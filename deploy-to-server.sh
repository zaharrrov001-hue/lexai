#!/bin/bash

# Скрипт для развертывания Mastra на сервере
# Использование: ./deploy-to-server.sh

set -e

SERVER="root@194.135.38.236"
DOMAIN="ripro-mastra.ru"
PROJECT_DIR="/var/www/mastra"
SERVICE_NAME="mastra-agent"

echo "🚀 Начинаю развертывание Mastra на сервере..."

# 1. Проверка подключения
echo "📡 Проверка подключения к серверу..."
ssh -o StrictHostKeyChecking=no $SERVER "echo '✅ Подключение успешно'"

# 2. Установка Node.js (если не установлен)
echo "📦 Проверка Node.js..."
ssh $SERVER "command -v node >/dev/null 2>&1 || {
    echo 'Установка Node.js...'
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
}"

# 3. Создание директории проекта
echo "📁 Создание директории проекта..."
ssh $SERVER "mkdir -p $PROJECT_DIR && chmod 755 $PROJECT_DIR"

# 4. Загрузка файлов проекта
echo "📤 Загрузка файлов проекта..."
scp -r src package.json tsconfig.json .gitignore env.example $SERVER:$PROJECT_DIR/

# 5. Установка зависимостей
echo "📦 Установка зависимостей..."
ssh $SERVER "cd $PROJECT_DIR && npm install"

# 6. Создание .env файла (если не существует)
echo "⚙️  Настройка переменных окружения..."
ssh $SERVER "cd $PROJECT_DIR && [ ! -f .env ] && {
    echo 'OPENAI_API_KEY=your-openai-api-key-here' > .env
    echo 'DATABASE_URL=file:./lexai-memory.db' >> .env
    echo '⚠️  ВАЖНО: Обновите OPENAI_API_KEY в .env файле!'
}"

# 7. Сборка проекта
echo "🔨 Сборка проекта..."
ssh $SERVER "cd $PROJECT_DIR && npm run build"

# 8. Создание systemd service
echo "🔧 Создание systemd service..."
ssh $SERVER "cat > /etc/systemd/system/$SERVICE_NAME.service << 'EOF'
[Unit]
Description=Mastra LexAI Agent
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$PROJECT_DIR
Environment=NODE_ENV=production
ExecStart=/usr/bin/node --import=$PROJECT_DIR/.mastra/output/instrumentation.mjs $PROJECT_DIR/.mastra/output/index.mjs
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
"

# 9. Перезагрузка systemd и запуск сервиса
echo "🔄 Запуск сервиса..."
ssh $SERVER "systemctl daemon-reload && systemctl enable $SERVICE_NAME && systemctl restart $SERVICE_NAME"

# 10. Проверка статуса
echo "✅ Проверка статуса сервиса..."
ssh $SERVER "systemctl status $SERVICE_NAME --no-pager -l"

# 11. Настройка Nginx (если установлен)
echo "🌐 Настройка Nginx..."
ssh $SERVER "command -v nginx >/dev/null 2>&1 && {
    cat > /etc/nginx/sites-available/$DOMAIN << 'NGINX_EOF'
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://localhost:4111;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
NGINX_EOF
    ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
    nginx -t && systemctl reload nginx
    echo '✅ Nginx настроен'
} || echo '⚠️  Nginx не установлен, пропускаю настройку'"

echo ""
echo "🎉 Развертывание завершено!"
echo ""
echo "📋 Следующие шаги:"
echo "1. Обновите OPENAI_API_KEY в $PROJECT_DIR/.env на сервере"
echo "2. Перезапустите сервис: ssh $SERVER 'systemctl restart $SERVICE_NAME'"
echo "3. Проверьте логи: ssh $SERVER 'journalctl -u $SERVICE_NAME -f'"
echo "4. Откройте http://$DOMAIN или http://194.135.38.236:4111"
echo ""

