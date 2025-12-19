# 🚀 Развертывание Mastra на сервере

## Сервер
- **IP**: 194.135.38.236
- **Домен**: ripro-mastra.ru
- **SSH**: root@194.135.38.236
- **Пароль**: a+-BLY*Zx4W9wU

---

## Быстрое развертывание

### Вариант 1: Автоматический скрипт

```bash
cd mastra
./deploy-to-server.sh
```

**Примечание**: При первом подключении введите пароль: `a+-BLY*Zx4W9wU`

---

### Вариант 2: Ручное развертывание

#### 1. Подключитесь к серверу

```bash
ssh root@194.135.38.236
# Пароль: a+-BLY*Zx4W9wU
```

#### 2. Установите Node.js (если не установлен)

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs
node --version  # Должно быть v20.x или выше
```

#### 3. Создайте директорию проекта

```bash
mkdir -p /var/www/mastra
cd /var/www/mastra
```

#### 4. Загрузите файлы проекта

**На вашем локальном компьютере:**

```bash
cd mastra
scp -r src package.json tsconfig.json .gitignore env.example root@194.135.38.236:/var/www/mastra/
```

**Или используйте rsync:**

```bash
rsync -avz --exclude 'node_modules' --exclude '.mastra' --exclude '.git' \
  src package.json tsconfig.json .gitignore env.example \
  root@194.135.38.236:/var/www/mastra/
```

#### 5. На сервере: Установите зависимости

```bash
cd /var/www/mastra
npm install
```

#### 6. Настройте переменные окружения

```bash
cd /var/www/mastra
nano .env
```

Добавьте:
```env
OPENAI_API_KEY=your-actual-openai-api-key-here
DATABASE_URL=file:./lexai-memory.db
NODE_ENV=production
```

**ВАЖНО**: Замените `your-actual-openai-api-key-here` на ваш реальный API ключ!

#### 7. Соберите проект

```bash
cd /var/www/mastra
npm run build
```

#### 8. Создайте systemd service

```bash
cat > /etc/systemd/system/mastra-agent.service << 'EOF'
[Unit]
Description=Mastra LexAI Agent
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/var/www/mastra
Environment=NODE_ENV=production
ExecStart=/usr/bin/node --import=/var/www/mastra/.mastra/output/instrumentation.mjs /var/www/mastra/.mastra/output/index.mjs
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
```

#### 9. Запустите сервис

```bash
systemctl daemon-reload
systemctl enable mastra-agent
systemctl start mastra-agent
systemctl status mastra-agent
```

#### 10. Настройте Nginx (если установлен)

```bash
cat > /etc/nginx/sites-available/ripro-mastra.ru << 'EOF'
server {
    listen 80;
    server_name ripro-mastra.ru;

    location / {
        proxy_pass http://localhost:4111;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

ln -sf /etc/nginx/sites-available/ripro-mastra.ru /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx
```

#### 11. Настройте SSL (опционально, через Let's Encrypt)

```bash
apt-get install -y certbot python3-certbot-nginx
certbot --nginx -d ripro-mastra.ru
```

---

## Проверка работы

### Проверить статус сервиса

```bash
systemctl status mastra-agent
```

### Просмотр логов

```bash
journalctl -u mastra-agent -f
```

### Проверить доступность

```bash
curl http://localhost:4111
# Или
curl http://ripro-mastra.ru
```

---

## Управление сервисом

```bash
# Запустить
systemctl start mastra-agent

# Остановить
systemctl stop mastra-agent

# Перезапустить
systemctl restart mastra-agent

# Статус
systemctl status mastra-agent

# Логи
journalctl -u mastra-agent -f
```

---

## Обновление проекта

### 1. Загрузите новые файлы

```bash
# На локальном компьютере
cd mastra
rsync -avz --exclude 'node_modules' --exclude '.mastra' \
  src package.json tsconfig.json \
  root@194.135.38.236:/var/www/mastra/
```

### 2. На сервере: Обновите и пересоберите

```bash
cd /var/www/mastra
npm install
npm run build
systemctl restart mastra-agent
```

---

## Troubleshooting

### Проблема: Сервис не запускается

```bash
# Проверьте логи
journalctl -u mastra-agent -n 50

# Проверьте права доступа
ls -la /var/www/mastra

# Проверьте Node.js
node --version
```

### Проблема: Порт 4111 занят

```bash
# Проверьте, что использует порт
netstat -tulpn | grep 4111

# Или измените порт в .env
echo "PORT=4112" >> /var/www/mastra/.env
```

### Проблема: Ошибки сборки

```bash
# Очистите и переустановите
cd /var/www/mastra
rm -rf node_modules .mastra
npm install
npm run build
```

---

## Безопасность

### Рекомендации:

1. **Измените пароль root** после развертывания
2. **Настройте SSH ключи** вместо пароля
3. **Ограничьте доступ к порту 4111** через firewall
4. **Используйте HTTPS** (Let's Encrypt)
5. **Регулярно обновляйте** систему и зависимости

---

## Готово! 🎉

После развертывания ваш Mastra Agent будет доступен по адресу:
- **HTTP**: http://ripro-mastra.ru или http://194.135.38.236:4111
- **HTTPS**: https://ripro-mastra.ru (после настройки SSL)

**API Endpoint**: `http://ripro-mastra.ru/api/agents/lexaiAgent/generate`

