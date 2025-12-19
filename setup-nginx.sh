#!/usr/bin/expect -f

set SERVER "194.135.38.236"
set USER "root"
set PASSWORD "a+-BLY*Zx4W9wU"
set timeout 60

puts "🌐 Установка и настройка Nginx..."
puts ""

# Установка Nginx
puts "📦 Установка Nginx..."
spawn ssh -o StrictHostKeyChecking=no ${USER}@${SERVER} "apt-get update -qq && apt-get install -y -qq nginx"
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

# Создание директории для sites-available
puts "📁 Создание директорий Nginx..."
spawn ssh -o StrictHostKeyChecking=no ${USER}@${SERVER} "mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled"
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

# Загрузка конфигурации
puts "📝 Загрузка конфигурации Nginx..."
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

# Активация конфигурации
puts "🔄 Активация конфигурации..."
spawn ssh -o StrictHostKeyChecking=no ${USER}@${SERVER} "ln -sf /etc/nginx/sites-available/ripro-mastra.ru /etc/nginx/sites-enabled/ && nginx -t && systemctl reload nginx"
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

# Проверка статуса Nginx
puts "✅ Проверка статуса Nginx..."
spawn ssh -o StrictHostKeyChecking=no ${USER}@${SERVER} "systemctl status nginx --no-pager -l | head -10"
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
puts "✅ Nginx настроен!"
puts ""
puts "🌐 Проверьте доступность:"
puts "   curl http://ripro-mastra.ru"
puts "   curl http://ripro-mastra.ru/api/agents"
puts ""

