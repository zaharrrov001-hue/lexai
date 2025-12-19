# 🚀 Полное развертывание Mastra Server на ripro-mastra.ru

## Важно: Развертываем Mastra Server, а не только агента!

Mastra работает как полноценный HTTP сервер, который предоставляет API для агентов. Нужно развернуть весь сервер.

---

## Сервер
- **IP**: 194.135.38.236
- **Домен**: ripro-mastra.ru
- **SSH**: root@194.135.38.236
- **Пароль**: a+-BLY*Zx4W9wU
- **Порт Mastra**: 4111 (по умолчанию)

---

## Шаг 1: Подготовка на локальном компьютере

```bash
cd mastra

# Проверьте, что проект собирается
npm run build

# Должно создать .mastra/output/ с сервером
ls -la .mastra/output/
```

---

## Шаг 2: Подключение к серверу

```bash
ssh root@194.135.38.236
# Пароль: a+-BLY*Zx4W9wU
```

---

## Шаг 3: На сервере - Установка Node.js

```bash
# Проверьте версию
node --version

# Если не установлен или версия < 20:
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs
node --version  # Должно быть v20.x или выше
npm --version
```

---

## Шаг 4: На сервере - Создание директории

```bash
mkdir -p /var/www/mastra
cd /var/www/mastra
```

---

## Шаг 5: Загрузка файлов проекта

**На вашем локальном компьютере** (в новом терминале):

```bash
cd mastra

# Загрузите все необходимые файлы
rsync -avz --exclude 'node_modules' --exclude '.mastra' --exclude '.git' \
  src package.json tsconfig.json .gitignore env.example \
  root@194.135.38.236:/var/www/mastra/
# Пароль: a+-BLY*Zx4W9wU
```

---

## Шаг 6: На сервере - Установка зависимостей

```bash
cd /var/www/mastra
npm install
```

---

## Шаг 7: На сервере - Настройка .env

```bash
cd /var/www/mastra
nano .env
```

Добавьте:

```env
# OpenAI API Key (ОБЯЗАТЕЛЬНО!)
OPENAI_API_KEY=sk-your-actual-openai-api-key-here

# Database (опционально, по умолчанию file:./lexai-memory.db)
DATABASE_URL=file:./lexai-memory.db

# Port (опционально, по умолчанию 4111)
PORT=4111

# CORS (опционально, по умолчанию *)
CORS_ORIGIN=*

# Environment
NODE_ENV=production
```

**ВАЖНО**: Замените `sk-your-actual-openai-api-key-here` на ваш реальный API ключ!

Сохраните: `Ctrl+O`, `Enter`, `Ctrl+X`

---

## Шаг 8: На сервере - Сборка Mastra Server

```bash
cd /var/www/mastra
npm run build
```

**Должно вывести:**
```
Build successful, you can now deploy the .mastra/output directory to your target platform.
```

**Проверьте, что создался сервер:**
```bash
ls -la .mastra/output/
# Должны быть файлы: index.mjs, instrumentation.mjs и другие
```

---

## Шаг 9: На сервере - Тестовый запуск сервера

```bash
cd /var/www/mastra

# Запустите сервер вручную для проверки
node --import=./.mastra/output/instrumentation.mjs .mastra/output/index.mjs
```

**Должно вывести что-то вроде:**
```
Server running on port 4111
```

**В другом терминале проверьте:**
```bash
curl http://localhost:4111
# Или
curl http://localhost:4111/api/agents/lexaiAgent/generate -X POST -H "Content-Type: application/json" -d '{"messages":[{"role":"user","content":"Привет"}]}'
```

Если работает - остановите сервер (`Ctrl+C`) и продолжайте.

---

## Шаг 10: На сервере - Создание systemd service

```bash
cat > /etc/systemd/system/mastra-server.service << 'EOF'
[Unit]
Description=Mastra Server - LexAI Agent
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/var/www/mastra
Environment=NODE_ENV=production
EnvironmentFile=/var/www/mastra/.env
ExecStart=/usr/bin/node --import=/var/www/mastra/.mastra/output/instrumentation.mjs /var/www/mastra/.mastra/output/index.mjs
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
```

---

## Шаг 11: На сервере - Запуск Mastra Server

```bash
systemctl daemon-reload
systemctl enable mastra-server
systemctl start mastra-server
systemctl status mastra-server
```

**Должно показать:**
```
Active: active (running)
```

---

## Шаг 12: На сервере - Проверка работы сервера

```bash
# Проверьте логи
journalctl -u mastra-server -f

# В другом терминале проверьте доступность
curl http://localhost:4111
curl http://localhost:4111/api/agents
```

**Ожидаемый ответ:**
```json
{
  "agents": ["lexaiAgent"],
  "version": "..."
}
```

---

## Шаг 13: На сервере - Настройка Nginx

```bash
# Проверьте, установлен ли Nginx
nginx -v

# Если не установлен:
apt-get update
apt-get install -y nginx

# Создайте конфигурацию для ripro-mastra.ru
cat > /etc/nginx/sites-available/ripro-mastra.ru << 'EOF'
server {
    listen 80;
    server_name ripro-mastra.ru www.ripro-mastra.ru;

    # Логи
    access_log /var/log/nginx/ripro-mastra-access.log;
    error_log /var/log/nginx/ripro-mastra-error.log;

    # Проксирование на Mastra Server
    location / {
        proxy_pass http://localhost:4111;
        proxy_http_version 1.1;
        
        # WebSocket support (если нужно)
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        
        # Headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

# Активируйте конфигурацию
ln -sf /etc/nginx/sites-available/ripro-mastra.ru /etc/nginx/sites-enabled/

# Проверьте конфигурацию
nginx -t

# Перезагрузите Nginx
systemctl reload nginx
```

---

## Шаг 14: На сервере - Настройка SSL (опционально, но рекомендуется)

```bash
apt-get update
apt-get install -y certbot python3-certbot-nginx

# Получите SSL сертификат
certbot --nginx -d ripro-mastra.ru -d www.ripro-mastra.ru

# Автоматическое обновление
certbot renew --dry-run
```

---

## Шаг 15: На сервере - Настройка Firewall

```bash
# Разрешите HTTP и HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Проверьте статус
ufw status
```

---

## ✅ Проверка работы

### 1. Проверьте статус сервиса

```bash
systemctl status mastra-server
```

### 2. Проверьте логи

```bash
journalctl -u mastra-server -f
```

### 3. Проверьте доступность через домен

```bash
curl http://ripro-mastra.ru
curl http://ripro-mastra.ru/api/agents
```

### 4. Проверьте API агента

```bash
curl -X POST http://ripro-mastra.ru/api/agents/lexaiAgent/generate \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {
        "role": "user",
        "content": "Привет! Как дела?"
      }
    ]
  }'
```

---

## 📋 Полезные команды

```bash
# Статус сервиса
systemctl status mastra-server

# Логи в реальном времени
journalctl -u mastra-server -f

# Перезапуск
systemctl restart mastra-server

# Остановка
systemctl stop mastra-server

# Проверка порта
netstat -tulpn | grep 4111

# Проверка Nginx
nginx -t
systemctl status nginx
```

---

## 🔄 Обновление проекта

```bash
# На локальном компьютере
cd mastra
rsync -avz --exclude 'node_modules' --exclude '.mastra' \
  src package.json tsconfig.json \
  root@194.135.38.236:/var/www/mastra/

# На сервере
cd /var/www/mastra
npm install
npm run build
systemctl restart mastra-server
```

---

## ❗ Troubleshooting

### Сервер не запускается

```bash
# Проверьте логи
journalctl -u mastra-server -n 50

# Проверьте .env файл
cat /var/www/mastra/.env

# Проверьте права доступа
ls -la /var/www/mastra
```

### Порт 4111 занят

```bash
# Проверьте, что использует порт
netstat -tulpn | grep 4111

# Или измените порт в .env
echo "PORT=4112" >> /var/www/mastra/.env
# И обновите Nginx конфигурацию
systemctl restart mastra-server
```

### Ошибки сборки

```bash
cd /var/www/mastra
rm -rf node_modules .mastra
npm install
npm run build
```

### Nginx не проксирует

```bash
# Проверьте конфигурацию
nginx -t

# Проверьте логи
tail -f /var/log/nginx/ripro-mastra-error.log

# Проверьте, что Mastra Server работает
curl http://localhost:4111
```

---

## 🌐 Доступные endpoints

После развертывания доступны:

- **Главная**: http://ripro-mastra.ru
- **API Agents**: http://ripro-mastra.ru/api/agents
- **API Generate**: http://ripro-mastra.ru/api/agents/lexaiAgent/generate
- **API Stream**: http://ripro-mastra.ru/api/agents/lexaiAgent/stream
- **Memory API**: http://ripro-mastra.ru/api/memory/...

---

## ✅ Готово!

Ваш Mastra Server развернут и доступен по адресу:
- **HTTP**: http://ripro-mastra.ru
- **HTTPS**: https://ripro-mastra.ru (после настройки SSL)

**API Endpoint**: `http://ripro-mastra.ru/api/agents/lexaiAgent/generate`

---

**Mastra Server полностью развернут! 🎉**

