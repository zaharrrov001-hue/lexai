# 🚀 Пошаговое развертывание Mastra на сервере

## Сервер
- **IP**: 194.135.38.236
- **Домен**: ripro-mastra.ru
- **SSH**: root@194.135.38.236
- **Пароль**: a+-BLY*Zx4W9wU

---

## Шаг 1: Подготовка файлов локально

```bash
cd mastra
tar -czf mastra-deploy.tar.gz src package.json tsconfig.json .gitignore env.example
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
# Проверьте версию Node.js
node --version

# Если не установлен или версия < 20:
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs
node --version  # Должно быть v20.x или выше
```

---

## Шаг 4: На сервере - Создание директории

```bash
mkdir -p /var/www/mastra
cd /var/www/mastra
```

---

## Шаг 5: Загрузка файлов

**На вашем локальном компьютере** (в новом терминале):

```bash
cd mastra
scp mastra-deploy.tar.gz root@194.135.38.236:/var/www/mastra/
# Пароль: a+-BLY*Zx4W9wU
```

**Или используйте rsync:**

```bash
rsync -avz --exclude 'node_modules' --exclude '.mastra' --exclude '.git' \
  src package.json tsconfig.json .gitignore env.example \
  root@194.135.38.236:/var/www/mastra/
# Пароль: a+-BLY*Zx4W9wU
```

**На сервере** (распакуйте если использовали tar):

```bash
cd /var/www/mastra
tar -xzf mastra-deploy.tar.gz
rm mastra-deploy.tar.gz
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

Добавьте (замените на ваш реальный API ключ):

```env
OPENAI_API_KEY=sk-your-actual-openai-api-key-here
DATABASE_URL=file:./lexai-memory.db
NODE_ENV=production
```

Сохраните: `Ctrl+O`, `Enter`, `Ctrl+X`

---

## Шаг 8: На сервере - Сборка проекта

```bash
cd /var/www/mastra
npm run build
```

Должно вывести: `Build successful`

---

## Шаг 9: На сервере - Создание systemd service

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

---

## Шаг 10: На сервере - Запуск сервиса

```bash
systemctl daemon-reload
systemctl enable mastra-agent
systemctl start mastra-agent
systemctl status mastra-agent
```

Должно показать: `Active: active (running)`

---

## Шаг 11: На сервере - Проверка работы

```bash
# Проверьте логи
journalctl -u mastra-agent -f

# В другом терминале проверьте доступность
curl http://localhost:4111
```

---

## Шаг 12: На сервере - Настройка Nginx (опционально)

```bash
# Проверьте, установлен ли Nginx
nginx -v

# Если установлен, создайте конфигурацию:
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

# Активируйте конфигурацию
ln -sf /etc/nginx/sites-available/ripro-mastra.ru /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx
```

---

## Шаг 13: На сервере - Настройка SSL (опционально)

```bash
apt-get update
apt-get install -y certbot python3-certbot-nginx
certbot --nginx -d ripro-mastra.ru
```

---

## ✅ Готово!

Ваш Mastra Agent доступен по адресу:
- **HTTP**: http://ripro-mastra.ru или http://194.135.38.236:4111
- **API**: http://ripro-mastra.ru/api/agents/lexaiAgent/generate

---

## 📋 Полезные команды

```bash
# Статус сервиса
systemctl status mastra-agent

# Логи в реальном времени
journalctl -u mastra-agent -f

# Перезапуск
systemctl restart mastra-agent

# Остановка
systemctl stop mastra-agent

# Проверка порта
netstat -tulpn | grep 4111
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
systemctl restart mastra-agent
```

---

## ❗ Troubleshooting

### Сервис не запускается

```bash
journalctl -u mastra-agent -n 50
```

### Порт занят

```bash
netstat -tulpn | grep 4111
# Если занят, остановите процесс или измените порт
```

### Ошибки сборки

```bash
cd /var/www/mastra
rm -rf node_modules .mastra
npm install
npm run build
```

---

**Готово к развертыванию! 🚀**

