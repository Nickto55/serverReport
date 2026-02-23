FROM node:20-alpine

WORKDIR /app

# Копируем только package.json и package-lock.json
COPY website/package*.json ./

# Устанавливаем зависимости
RUN npm cache clean --force && npm install --production --legacy-peer-deps

# Копируем файлы приложения (без node_modules благодаря .dockerignore)
COPY website/server.js website/db.js ./
COPY website/routes ./routes
COPY website/middleware ./middleware

# Копируем директорию public (должна существовать, даже если пустая)
COPY website/public ./public

EXPOSE 3000

CMD ["npm", "start"]
