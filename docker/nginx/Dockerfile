FROM nginx:alpine

# Копируем конфиг
COPY nginx.conf /etc/nginx/nginx.conf

# Создаем директорию для сертификатов
RUN mkdir -p /etc/nginx/certs

# Устанавливаем openssl
RUN apk add --no-cache openssl

# Генерируем самоподписанный сертификат (365 дней)
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/certs/server.key \
    -out /etc/nginx/certs/server.crt \
    -subj "/CN=localhost"

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
