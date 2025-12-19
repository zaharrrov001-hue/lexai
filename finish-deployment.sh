#!/usr/bin/expect -f

set SERVER "194.135.38.236"
set USER "root"
set PASSWORD "a+-BLY*Zx4W9wU"
set PROJECT_DIR "/var/www/mastra"
set timeout 30

puts "🔧 Завершение развертывания Mastra Server..."
puts ""

# Создание systemd service
puts "📝 Создание systemd service..."
spawn ssh -o StrictHostKeyChecking=no ${USER}@${SERVER} "bash -c 'cat > /etc/systemd/system/mastra-server.service << \"SERVICEEOF\"
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
SERVICEEOF
'"
expect {
    "password:" {
        send "$PASSWORD\r"
    }
    "yes/no" {
        send "yes\r"
        expect "password:"
        send "$PASSWORD\r"
    }
}
expect eof

# Запуск сервиса
puts "🔄 Запуск Mastra Server..."
spawn ssh -o StrictHostKeyChecking=no ${USER}@${SERVER} "systemctl daemon-reload && systemctl enable mastra-server && systemctl start mastra-server"
expect {
    "password:" {
        send "$PASSWORD\r"
    }
    "yes/no" {
        send "yes\r"
        expect "password:"
        send "$PASSWORD\r"
    }
}
expect eof

# Проверка статуса
puts "✅ Проверка статуса..."
spawn ssh -o StrictHostKeyChecking=no ${USER}@${SERVER} "sleep 3 && systemctl status mastra-server --no-pager -l | head -15"
expect {
    "password:" {
        send "$PASSWORD\r"
    }
    "yes/no" {
        send "yes\r"
        expect "password:"
        send "$PASSWORD\r"
    }
}
expect eof

# Проверка доступности
puts "🌐 Проверка доступности API..."
spawn ssh -o StrictHostKeyChecking=no ${USER}@${SERVER} "sleep 2 && curl -s http://localhost:4111/api/agents | head -10"
expect {
    "password:" {
        send "$PASSWORD\r"
    }
    "yes/no" {
        send "yes\r"
        expect "password:"
        send "$PASSWORD\r"
    }
}
expect eof

# Настройка Nginx
puts "🌐 Настройка Nginx..."
spawn ssh -o StrictHostKeyChecking=no ${USER}@${SERVER} "command -v nginx >/dev/null 2>&1 && bash -c 'cat > /etc/nginx/sites-available/ripro-mastra.ru << \"NGINXEOF\"
server {
    listen 80;
    server_name ripro-mastra.ru www.ripro-mastra.ru;
    access_log /var/log/nginx/ripro-mastra-access.log;
    error_log /var/log/nginx/ripro-mastra-error.log;
    location / {
        proxy_pass http://localhost:4111;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \\\$http_upgrade;
        proxy_set_header Connection \"upgrade\";
        proxy_set_header Host \\\$host;
        proxy_set_header X-Real-IP \\\$remote_addr;
        proxy_set_header X-Forwarded-For \\\$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \\\$scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        proxy_cache_bypass \\\$http_upgrade;
    }
}
NGINXEOF
ln -sf /etc/nginx/sites-available/ripro-mastra.ru /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
echo \"✅ Nginx настроен\"
' || echo '⚠️  Nginx не установлен'"
expect {
    "password:" {
        send "$PASSWORD\r"
    }
    "yes/no" {
        send "yes\r"
        expect "password:"
        send "$PASSWORD\r"
    }
}
expect eof

puts ""
puts "🎉 Развертывание завершено!"
puts ""
puts "⚠️  ВАЖНО: Обновите OPENAI_API_KEY в .env файле!"
puts "   ssh ${USER}@${SERVER}"
puts "   nano $PROJECT_DIR/.env"
puts "   systemctl restart mastra-server"
puts ""
puts "🌐 Проверьте:"
puts "   http://ripro-mastra.ru"
puts "   http://ripro-mastra.ru/api/agents"
puts ""

