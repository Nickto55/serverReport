FROM node:20-alpine

WORKDIR /app

COPY website/package*.json ./

RUN npm install --production

COPY website/ .

# Копируем статические файлы сайта из submodule в public
COPY siteEMB/public ./public

EXPOSE 3000

CMD ["npm", "start"]
