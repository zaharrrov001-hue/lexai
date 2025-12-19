#!/usr/bin/expect -f

set SERVER "194.135.38.236"
set USER "root"
set PASSWORD "a+-BLY*Zx4W9wU"
set timeout 30

puts "🔧 Завершение развертывания..."

# Загрузка systemd service файла
puts "📝 Загрузка systemd service..."
spawn scp -o StrictHostKeyChecking=no mastra-server.service ${USER}@${SERVER}:/etc/systemd/system/mastra-server.service
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

# Загрузка nginx конфигурации
puts "🌐 Загрузка Nginx конфигурации..."
spawn scp -o StrictHostKeyChecking=no nginx-ripro-mastra.conf ${USER}@${SERVER}:/etc/nginx/sites-available/ripro-mastra.ru
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
spawn ssh -o StrictHostKeyChecking=no ${USER}@${SERVER} "systemctl daemon-reload && systemctl enable mastra-server && systemctl start mastra-server && sleep 3 && systemctl status mastra-server --no-pager -l | head -15"
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
spawn ssh -o StrictHostKeyChecking=no ${USER}@${SERVER} "command -v nginx >/dev/null 2>&1 && { ln -sf /etc/nginx/sites-available/ripro-mastra.ru /etc/nginx/sites-enabled/ && nginx -t && systemctl reload nginx && echo '✅ Nginx настроен'; } || echo '⚠️  Nginx не установлен'"
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
puts "✅ Проверка доступности..."
spawn ssh -o StrictHostKeyChecking=no ${USER}@${SERVER} "sleep 2 && curl -s http://localhost:4111/api/agents | head -5"
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
puts "⚠️  ВАЖНО: Обновите OPENAI_API_KEY в /var/www/mastra/.env"
puts "   ssh ${USER}@${SERVER}"
puts "   nano /var/www/mastra/.env"
puts "   systemctl restart mastra-server"
puts ""
puts "🌐 Проверьте:"
puts "   http://ripro-mastra.ru"
puts "   http://ripro-mastra.ru/api/agents"
puts ""

