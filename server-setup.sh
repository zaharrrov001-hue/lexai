#!/bin/bash

# Скрипт для выполнения на сервере
# Загрузите этот файл на сервер и выполните: bash server-setup.sh

set -e

PROJECT_DIR="/var/www/mastra"
SERVICE_NAME="mastra-agent"

echo "🚀 Настройка Mastra на сервере..."

# 1. Проверка Node.js
echo "📦 Проверка Node.js..."
if ! command -v node &> /dev/null; then
    echo "Установка Node.js..."
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
NODE_ENV=production
EOF
    echo "⚠️  ВАЖНО: Обновите OPENAI_API_KEY в .env файле!"
    echo "   nano $PROJECT_DIR/.env"
fi

# 5. Сборка проекта
echo "🔨 Сборка проекта..."
npm run build

# 6. Создание systemd service
echo "🔧 Создание systemd service..."
cat > /etc/systemd/system/$SERVICE_NAME.service << EOF
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
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# 7. Запуск сервиса
echo "🔄 Запуск сервиса..."
systemctl daemon-reload
systemctl enable $SERVICE_NAME
systemctl restart $SERVICE_NAME

# 8. Проверка статуса
echo "✅ Проверка статуса..."
sleep 2
systemctl status $SERVICE_NAME --no-pager -l | head -20

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
echo ""

