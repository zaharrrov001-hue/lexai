#!/bin/bash

# Быстрое развертывание Mastra на сервере
# Использование: ./quick-deploy.sh

set -e

SERVER="root@194.135.38.236"
PROJECT_DIR="/var/www/mastra"

echo "🚀 Быстрое развертывание Mastra..."
echo ""

# Загрузка файлов
echo "📤 Загрузка файлов на сервер..."
rsync -avz --exclude 'node_modules' --exclude '.mastra' --exclude '.git' \
  src package.json tsconfig.json .gitignore env.example \
  $SERVER:$PROJECT_DIR/ || {
  echo "❌ Ошибка загрузки. Используйте scp вручную."
  exit 1
}

echo ""
echo "✅ Файлы загружены!"
echo ""
echo "📋 Следующие шаги на сервере:"
echo ""
echo "1. Подключитесь к серверу:"
echo "   ssh $SERVER"
echo ""
echo "2. Выполните на сервере:"
echo "   cd $PROJECT_DIR"
echo "   npm install"
echo "   nano .env  # Добавьте OPENAI_API_KEY"
echo "   npm run build"
echo ""
echo "3. Создайте systemd service (см. DEPLOY_SERVER.md)"
echo "4. Запустите: systemctl start mastra-agent"
echo ""
echo "📖 Подробные инструкции: DEPLOY_SERVER.md"

