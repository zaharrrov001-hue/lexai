#!/bin/bash

# Упрощенный скрипт развертывания через SSH команды
# Выполняет команды последовательно

SERVER="root@194.135.38.236"
PASSWORD="a+-BLY*Zx4W9wU"
PROJECT_DIR="/var/www/mastra"

echo "🚀 Развертывание Mastra Server..."

# 1. Загрузка файлов
echo "📤 Загрузка файлов..."
rsync -avz --exclude 'node_modules' --exclude '.mastra' --exclude '.git' \
  src package.json tsconfig.json .gitignore env.example \
  $SERVER:$PROJECT_DIR/

echo ""
echo "✅ Файлы загружены!"
echo ""
echo "📋 Теперь выполните на сервере следующие команды:"
echo ""
echo "ssh $SERVER"
echo "# Пароль: $PASSWORD"
echo ""
echo "cd $PROJECT_DIR"
echo "npm install"
echo "npm run build"
echo ""
echo "cat > .env << 'EOF'"
echo "OPENAI_API_KEY=your-openai-api-key-here"
echo "DATABASE_URL=file:./lexai-memory.db"
echo "PORT=4111"
echo "CORS_ORIGIN=*"
echo "NODE_ENV=production"
echo "EOF"
echo ""
echo "# Создайте systemd service (см. DEPLOY_FULL_MASTRA.md)"
echo "# Запустите: systemctl start mastra-server"
echo ""

