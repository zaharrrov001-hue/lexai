#!/bin/bash

# Полная настройка Mastra Server на сервере
# Загрузите этот файл на сервер и выполните: bash server-setup-full.sh

set -e

PROJECT_DIR="/var/www/mastra"
SERVICE_NAME="mastra-server"
DOMAIN="ripro-mastra.ru"

echo "🚀 Полная настройка Mastra Server..."
echo ""

# 1. Проверка Node.js
echo "📦 Проверка Node.js..."
if ! command -v node &> /dev/null; then
    echo "Установка Node.js 20.x..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
fi

echo "✅ Node.js: $(node --version)"
echo "✅ npm: $(npm --version)"

# 2. Переход в директорию проекта
cd $PROJECT_DIR || {
    echo "❌ Директория $PROJECT_DIR не найдена!"
    echo "Создайте её и загрузите файлы проекта."
    exit 1
}

# 3. Установка зависимостей
echo "📦 Установка зависимостей..."
npm install

# 4. Проверка .env файла
if [ ! -f .env ]; then
    echo "⚙️  Создание .env файла..."
    cat > .env << 'EOF'
OPENAI_API_KEY=your-openai-api-key-here
DATABASE_URL=file:./lexai-memory.db
PORT=4111
CORS_ORIGIN=*
NODE_ENV=production
EOF
    echo "⚠️  ВАЖНО: Обновите OPENAI_API_KEY в .env файле!"
    echo "   nano $PROJECT_DIR/.env"
fi

# 5. Сборка Mastra Server
echo "🔨 Сборка Mastra Server..."
npm run build

# Проверка, что сервер создан
if [ ! -f .mastra/output/index.mjs ]; then
    echo "❌ Ошибка: сервер не собран!"
    exit 1
fi

echo "✅ Mastra Server собран успешно!"

# 6. Тестовый запуск (проверка)
echo "🧪 Тестовая проверка сервера..."
timeout 5 node --import=./.mastra/output/instrumentation.mjs .mastra/output/index.mjs &
SERVER_PID=$!
sleep 3

if curl -s http://localhost:4111 > /dev/null; then
    echo "✅ Сервер работает!"
    kill $SERVER_PID 2>/dev/null || true
else
    echo "⚠️  Сервер не отвечает, но продолжаем..."
    kill $SERVER_PID 2>/dev/null || true
fi

# 7. Создание systemd service
echo "🔧 Создание systemd service..."
cat > /etc/systemd/system/$SERVICE_NAME.service << EOF
[Unit]
Description=Mastra Server - LexAI Agent
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$PROJECT_DIR
Environment=NODE_ENV=production
EnvironmentFile=$PROJECT_DIR/.env
ExecStart=/usr/bin/node --import=$PROJECT_DIR/.mastra/output/instrumentation.mjs $PROJECT_DIR/.mastra/output/index.mjs
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# 8. Запуск сервиса
echo "🔄 Запуск сервиса..."
systemctl daemon-reload
systemctl enable $SERVICE_NAME
systemctl restart $SERVICE_NAME

# 9. Проверка статуса
echo "✅ Проверка статуса..."
sleep 3
if systemctl is-active --quiet $SERVICE_NAME; then
    echo "✅ Сервис запущен успешно!"
else
    echo "⚠️  Сервис не запущен. Проверьте логи:"
    echo "   journalctl -u $SERVICE_NAME -n 50"
fi

# 10. Настройка Nginx (если установлен)
echo "🌐 Настройка Nginx..."
if command -v nginx &> /dev/null; then
    cat > /etc/nginx/sites-available/$DOMAIN << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    access_log /var/log/nginx/$DOMAIN-access.log;
    error_log /var/log/nginx/$DOMAIN-error.log;

    location / {
        proxy_pass http://localhost:4111;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

    ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
    
    if nginx -t; then
        systemctl reload nginx
        echo "✅ Nginx настроен и перезагружен!"
    else
        echo "⚠️  Ошибка в конфигурации Nginx"
    fi
else
    echo "⚠️  Nginx не установлен. Установите для работы с доменом:"
    echo "   apt-get install -y nginx"
fi

# 11. Настройка Firewall
echo "🔥 Настройка Firewall..."
if command -v ufw &> /dev/null; then
    ufw allow 80/tcp
    ufw allow 443/tcp
    echo "✅ Firewall настроен!"
fi

echo ""
echo "🎉 Настройка завершена!"
echo ""
echo "📋 Полезные команды:"
echo "   systemctl status $SERVICE_NAME    # Статус сервиса"
echo "   journalctl -u $SERVICE_NAME -f    # Логи в реальном времени"
echo "   systemctl restart $SERVICE_NAME   # Перезапуск"
echo ""
echo "🌐 Проверьте доступность:"
echo "   curl http://localhost:4111"
echo "   curl http://$DOMAIN"
echo ""
echo "⚠️  ВАЖНО: Обновите OPENAI_API_KEY в $PROJECT_DIR/.env!"
echo "   nano $PROJECT_DIR/.env"
echo ""

