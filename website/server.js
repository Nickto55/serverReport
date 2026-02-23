require('dotenv').config();
const express = require('express');
const path = require('path');
const helmet = require('helmet');
const cors = require('cors');
const pool = require('./db');

// Импорт роутов
const authRoutes = require('./routes/auth');
const adminRoutes = require('./routes/admin');
const reportsRoutes = require('./routes/reports');

const app = express();
const PORT = process.env.PORT || 3000;

// Безопасность - Helmet (настроено для работы с inline скриптами и внешними ресурсами)
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'", "'unsafe-eval'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https:"],
      imgSrc: ["'self'", "data:", "https:", "blob:"],
      connectSrc: ["'self'", "https:", "wss:"],
      fontSrc: ["'self'", "data:", "https:"],
      objectSrc: ["'none'"],
      mediaSrc: ["'self'"],
      frameSrc: ["'self'"],
    }
  }
}));

// CORS
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  credentials: true
}));

// Парсинг JSON
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Логирование запросов
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    // Проверка подключения к БД
    await pool.query('SELECT 1');
    res.json({
      status: 'ok',
      timestamp: new Date().toISOString(),
      database: 'connected'
    });
  } catch (error) {
    res.status(503).json({
      status: 'error',
      timestamp: new Date().toISOString(),
      database: 'disconnected',
      error: error.message
    });
  }
});

// Основные роуты API
app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/reports', reportsRoutes);

// API информация
app.get('/api', (req, res) => {
  res.json({
    message: 'Express.js REST API для управления пользователями и отчетами',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      auth: {
        register: 'POST /api/auth/register',
        login: 'POST /api/auth/login'
      },
      admin: {
        getUsers: 'GET /api/admin/users',
        getUser: 'GET /api/admin/users/:id',
        updateRole: 'PUT /api/admin/users/:id/role',
        deleteUser: 'DELETE /api/admin/users/:id'
      },
      reports: {
        getAll: 'GET /api/reports',
        getById: 'GET /api/reports/:id',
        create: 'POST /api/reports',
        update: 'PUT /api/reports/:id',
        delete: 'DELETE /api/reports/:id'
      }
    }
  });
});

// Debug endpoint - показывает структуру public директории
app.get('/api/debug/public-files', (req, res) => {
  const fs = require('fs');
  const publicPath = path.join(__dirname, 'public');
  
  function getFiles(dir, prefix = '') {
    const files = [];
    try {
      const items = fs.readdirSync(dir);
      items.forEach(item => {
        const fullPath = path.join(dir, item);
        const stat = fs.statSync(fullPath);
        if (stat.isDirectory()) {
          files.push({ type: 'dir', path: prefix + item + '/' });
          files.push(...getFiles(fullPath, prefix + item + '/'));
        } else {
          files.push({ type: 'file', path: prefix + item, size: stat.size });
        }
      });
    } catch (err) {
      files.push({ type: 'error', path: prefix, error: err.message });
    }
    return files;
  }
  
  res.json({
    publicPath: publicPath,
    files: getFiles(publicPath)
  });
});

// Раздача статических файлов - ДОЛЖНА БЫТЬ ДО SPA FALLBACK!
app.use(express.static(path.join(__dirname, 'public'), {
  setHeaders: (res, filePath) => {
    if (filePath.endsWith('.js')) {
      res.setHeader('Content-Type', 'application/javascript; charset=utf-8');
    } else if (filePath.endsWith('.css')) {
      res.setHeader('Content-Type', 'text/css; charset=utf-8');
    }
  }
}));

// SPA fallback - для всех остальных маршрутов иди в главный HTML файл
// ВАЖНО: это должно быть ПОСЛЕ всех /api маршрутов и статических файлов!
const mainHtmlFile = process.env.MAIN_HTML || 'index.html';

app.get('/', (req, res) => {
  const filePath = path.join(__dirname, 'public', mainHtmlFile);
  res.sendFile(filePath, (err) => {
    if (err) {
      res.status(404).json({ 
        error: 'Главная страница не найдена', 
        message: `Файл ${mainHtmlFile} отсутствует в директории public/` 
      });
    }
  });
});

app.get('*', (req, res) => {
  const filePath = path.join(__dirname, 'public', mainHtmlFile);
  res.sendFile(filePath, (err) => {
    if (err) {
      res.status(404).json({ 
        error: 'Страница не найдена', 
        message: `Файл ${mainHtmlFile} отсутствует в директории public/` 
      });
    }
  });
});

// 404 обработчик для POST/PUT/DELETE (эти методы не поймают SPA fallback)
app.use((req, res) => {
  res.status(404).json({ error: 'Маршрут не найден' });
});

// Обработчик ошибок
app.use((err, req, res, next) => {
  console.error('Ошибка сервера:', err.stack);
  res.status(500).json({
    error: 'Внутренняя ошибка сервера',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// Запуск сервера
const server = app.listen(PORT, () => {
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('🚀 Сервер запущен');
  console.log(`📍 Порт: ${PORT}`);
  console.log(`🌐 URL: http://localhost:${PORT}`);
  console.log(`🔒 Окружение: ${process.env.NODE_ENV || 'development'}`);
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
});

// Корректное завершение
process.on('SIGTERM', () => {
  console.log('SIGTERM получен, закрываем сервер...');
  server.close(() => {
    console.log('Сервер закрыт');
    pool.end();
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('\nSIGINT получен, закрываем сервер...');
  server.close(() => {
    console.log('Сервер закрыт');
    pool.end();
    process.exit(0);
  });
});

module.exports = app;
