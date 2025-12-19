#!/usr/bin/expect -f

set SERVER "194.135.38.236"
set USER "root"
set PASSWORD "a+-BLY*Zx4W9wU"
set PROJECT_DIR "/var/www/mastra"
set timeout 30

puts "🔍 Проверка статуса развертывания..."
puts ""

# Проверка Node.js
spawn ssh -o StrictHostKeyChecking=no ${USER}@${SERVER} "node --version && npm --version"
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

# Проверка файлов
spawn ssh -o StrictHostKeyChecking=no ${USER}@${SERVER} "cd $PROJECT_DIR && ls -la | head -10"
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

# Проверка сборки
spawn ssh -o StrictHostKeyChecking=no ${USER}@${SERVER} "cd $PROJECT_DIR && test -f .mastra/output/index.mjs && echo '✅ Сервер собран' || echo '❌ Сервер не собран'"
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

# Проверка сервиса
spawn ssh -o StrictHostKeyChecking=no ${USER}@${SERVER} "systemctl status mastra-server --no-pager -l 2>&1 | head -10"
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
spawn ssh -o StrictHostKeyChecking=no ${USER}@${SERVER} "curl -s http://localhost:4111/api/agents 2>&1 | head -5"
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
puts "✅ Проверка завершена!"

