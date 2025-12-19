#!/usr/bin/expect -f

set SERVER "194.135.38.236"
set USER "root"
set PASSWORD "a+-BLY*Zx4W9wU"
set PROJECT_DIR "/var/www/mastra"
set timeout 300

puts "🚀 Автоматическое развертывание Mastra Server..."
puts ""

# Функция для выполнения команд
proc run_command {command} {
    global SERVER USER PASSWORD
    spawn ssh -o StrictHostKeyChecking=no ${USER}@${SERVER} $command
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
}

# Функция для загрузки файлов
proc upload_files {} {
    global SERVER USER PASSWORD PROJECT_DIR
    puts "📤 Загрузка файлов проекта..."
    spawn rsync -avz --exclude 'node_modules' --exclude '.mastra' --exclude '.git' \
        src package.json tsconfig.json .gitignore env.example \
        ${USER}@${SERVER}:${PROJECT_DIR}/
    expect {
        "password:" {
            send "$PASSWORD\r"
            exp_continue
        }
        eof
    }
    puts "✅ Файлы загружены!"
}

# 1. Создание директории
puts "📁 Создание директории на сервере..."
run_command "mkdir -p $PROJECT_DIR"

# 2. Загрузка файлов
upload_files

# 3. Установка Node.js
puts "📦 Проверка и установка Node.js..."
spawn ssh -o StrictHostKeyChecking=no ${USER}@${SERVER} "command -v node >/dev/null 2>&1 || { curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && apt-get install -y nodejs; }"
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

# 4. Установка зависимостей
puts "📦 Установка зависимостей..."
spawn ssh -o StrictHostKeyChecking=no ${USER}@${SERVER} "cd $PROJECT_DIR && npm install"
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

# 5. Создание .env
puts "⚙️  Создание .env файла..."
spawn ssh -o StrictHostKeyChecking=no ${USER}@${SERVER} "cd $PROJECT_DIR && cat > .env << 'EOF'
OPENAI_API_KEY=your-openai-api-key-here
DATABASE_URL=file:./lexai-memory.db
PORT=4111
CORS_ORIGIN=*
NODE_ENV=production
EOF
"
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

# 6. Сборка проекта
puts "🔨 Сборка Mastra Server..."
spawn ssh -o StrictHostKeyChecking=no ${USER}@${SERVER} "cd $PROJECT_DIR && npm run build"
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

# 7. Создание systemd service
puts "🔧 Создание systemd service..."
spawn ssh -o StrictHostKeyChecking=no ${USER}@${SERVER} "cat > /etc/systemd/system/mastra-server.service << 'EOF'
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
"
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

# 8. Запуск сервиса
puts "🔄 Запуск Mastra Server..."
spawn ssh -o StrictHostKeyChecking=no ${USER}@${SERVER} "systemctl daemon-reload && systemctl enable mastra-server && systemctl restart mastra-server"
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

# 9. Проверка статуса
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

# 10. Настройка Nginx
puts "🌐 Настройка Nginx..."
spawn ssh -o StrictHostKeyChecking=no ${USER}@${SERVER} "command -v nginx >/dev/null 2>&1 && {
    cat > /etc/nginx/sites-available/ripro-mastra.ru << 'NGINX_EOF'
server {
    listen 80;
    server_name ripro-mastra.ru www.ripro-mastra.ru;
    access_log /var/log/nginx/ripro-mastra-access.log;
    error_log /var/log/nginx/ripro-mastra-error.log;
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
NGINX_EOF
    ln -sf /etc/nginx/sites-available/ripro-mastra.ru /etc/nginx/sites-enabled/
    nginx -t && systemctl reload nginx
    echo '✅ Nginx настроен'
} || echo '⚠️  Nginx не установлен'"
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
puts "⚠️  ВАЖНО: Обновите OPENAI_API_KEY в .env файле на сервере!"
puts "   ssh ${USER}@${SERVER}"
puts "   nano $PROJECT_DIR/.env"
puts "   systemctl restart mastra-server"
puts ""
puts "🌐 Проверьте доступность:"
puts "   curl http://ripro-mastra.ru"
puts "   curl http://ripro-mastra.ru/api/agents"
puts ""

