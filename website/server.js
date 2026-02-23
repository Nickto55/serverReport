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

// Безопасность - Helmet (настроено для работы с inline скриптами)
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:", "https:"],
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

// Раздача статических файлов - ДОЛЖНА БЫТЬ ДО SPA FALLBACK!
app.use(express.static(path.join(__dirname, 'public')));

// SPA fallback - для всех остальных маршрутов иди в index.html
// ВАЖНО: это должно быть ПОСЛЕ всех /api маршрутов и статических файлов!
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
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
