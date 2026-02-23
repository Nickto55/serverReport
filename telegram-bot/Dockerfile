FROM node:20-alpine

WORKDIR /app

COPY package*.json ./

RUN npm cache clean --force && npm install --production --legacy-peer-deps

COPY . .

CMD ["npm", "start"]
