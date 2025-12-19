# 🚀 Полное развертывание Mastra Server

## ⚠️ Важно!

Развертываем **Mastra Server** (полноценный HTTP сервер), а не только агента!

Mastra Server предоставляет:
- ✅ HTTP API для агентов
- ✅ Endpoints для работы с memory
- ✅ WebSocket поддержка (если нужно)
- ✅ Автоматическая маршрутизация

---

## 📋 Быстрое развертывание (3 шага)

### Шаг 1: Загрузите файлы на сервер

На вашем локальном компьютере:

```bash
cd mastra
rsync -avz --exclude 'node_modules' --exclude '.mastra' --exclude '.git' \
  src package.json tsconfig.json .gitignore env.example \
  root@194.135.38.236:/var/www/mastra/
# Пароль: a+-BLY*Zx4W9wU
```

### Шаг 2: Подключитесь и выполните настройку

```bash
ssh root@194.135.38.236
# Пароль: a+-BLY*Zx4W9wU

cd /var/www/mastra

# Загрузите скрипт настройки
wget -O server-setup-full.sh https://raw.githubusercontent.com/.../server-setup-full.sh
# Или скопируйте содержимое файла server-setup-full.sh вручную

# Выполните настройку
bash server-setup-full.sh
```

### Шаг 3: Настройте API ключ

```bash
nano /var/www/mastra/.env
# Добавьте ваш OPENAI_API_KEY
# Сохраните: Ctrl+O, Enter, Ctrl+X

systemctl restart mastra-server
```

---

## 📖 Подробная инструкция

См. **`DEPLOY_FULL_MASTRA.md`** - полное пошаговое руководство.

---

## ✅ После развертывания

Mastra Server будет доступен по адресу:
- **http://ripro-mastra.ru** (через Nginx)
- **http://194.135.38.236:4111** (напрямую)

**API Endpoints:**
- `GET /api/agents` - список агентов
- `POST /api/agents/lexaiAgent/generate` - генерация ответа
- `POST /api/agents/lexaiAgent/stream` - streaming ответа

---

## 🔍 Проверка работы

```bash
# На сервере
systemctl status mastra-server
journalctl -u mastra-server -f
curl http://localhost:4111/api/agents
```

---

**Готово к развертыванию! 🚀**

