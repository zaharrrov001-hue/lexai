#!/bin/bash

# Быстрое развертывание Mastra Server на ripro-mastra.ru
# Использование: ./QUICK_DEPLOY_SERVER.sh

set -e

SERVER="root@194.135.38.236"
PROJECT_DIR="/var/www/mastra"
SERVICE_NAME="mastra-server"

echo "🚀 Развертывание Mastra Server на ripro-mastra.ru..."
echo ""

# 1. Загрузка файлов
echo "📤 Загрузка файлов проекта..."
rsync -avz --exclude 'node_modules' --exclude '.mastra' --exclude '.git' \
  src package.json tsconfig.json .gitignore env.example \
  $SERVER:$PROJECT_DIR/ || {
  echo "❌ Ошибка загрузки. Выполните вручную:"
  echo "   rsync -avz --exclude 'node_modules' --exclude '.mastra' --exclude '.git' \\"
  echo "     src package.json tsconfig.json .gitignore env.example \\"
  echo "     $SERVER:$PROJECT_DIR/"
  exit 1
}

echo ""
echo "✅ Файлы загружены!"
echo ""
echo "📋 Теперь выполните на сервере:"
echo ""
echo "1. Подключитесь:"
echo "   ssh $SERVER"
echo "   # Пароль: a+-BLY*Zx4W9wU"
echo ""
echo "2. Выполните настройку:"
echo "   cd $PROJECT_DIR"
echo "   bash <(curl -s https://raw.githubusercontent.com/.../server-setup-full.sh)"
echo ""
echo "   Или следуйте инструкциям в DEPLOY_FULL_MASTRA.md"
echo ""

