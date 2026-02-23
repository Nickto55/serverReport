FROM node:20-alpine

WORKDIR /app

COPY website/package*.json ./

RUN npm cache clean --force && npm install --production --legacy-peer-deps

# Копируем все файлы website кроме public папки
COPY website/ .
RUN rm -rf ./public/*

# Копируем статические файлы сайта из siteEMB
COPY siteEMB/public ./public

EXPOSE 3000

CMD ["npm", "start"]
