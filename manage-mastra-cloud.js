#!/usr/bin/env node
/**
 * Скрипт для управления проектом Mastra Cloud через API
 * 
 * Использование:
 *   node manage-mastra-cloud.js <command> [options]
 * 
 * Команды:
 *   - set-env <KEY> <VALUE>  - Установить переменную окружения
 *   - get-env                  - Получить все переменные окружения
 *   - restart                  - Перезапустить проект
 *   - status                   - Проверить статус проекта
 *   - logs                     - Получить логи
 */

const token = process.env.MASTRA_CLOUD_TOKEN || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0ZWFtSWQiOiI1Mzg1OTEzMy0zY2ZkLTQ4ZjMtOWI5OS1iODZlYTgyOGFlOGUiLCJwcm9qZWN0SWQiOiI2YjE2ZDViMC1iNjE1LTQyNjYtODU3MC05ZTI1MDU2MjY4YjMiLCJ1bmlxdWVJZCI6IjZjNzJmMzBhLWVkYzItNGU1Yi04ODU3LWVlMGVhZWRmN2IxZiIsImlhdCI6MTc2NjE2NzE5OH0.4g8cMZ5Y7aF_yQZuv0aUsg_wzG9XqhS3a3ZT1GAi3Xg';

// Декодируем токен для получения projectId
function decodeToken(token) {
  try {
    const parts = token.split('.');
    const payload = JSON.parse(Buffer.from(parts[1], 'base64').toString());
    return {
      teamId: payload.teamId,
      projectId: payload.projectId,
      uniqueId: payload.uniqueId
    };
  } catch (e) {
    console.error('❌ Ошибка декодирования токена:', e.message);
    process.exit(1);
  }
}

const { teamId, projectId } = decodeToken(token);
const baseUrl = 'https://cloud.mastra.ai/api'; // Предполагаемый URL API

async function apiRequest(method, endpoint, body = null) {
  const url = `${baseUrl}${endpoint}`;
  const options = {
    method,
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
  };

  if (body) {
    options.body = JSON.stringify(body);
  }

  try {
    const response = await fetch(url, options);
    const data = await response.json();
    
    if (!response.ok) {
      throw new Error(`API Error: ${response.status} - ${JSON.stringify(data)}`);
    }
    
    return data;
  } catch (error) {
    console.error(`❌ Ошибка запроса к ${endpoint}:`, error.message);
    throw error;
  }
}

async function setEnvironmentVariable(key, value) {
  console.log(`🔧 Устанавливаю переменную окружения: ${key}`);
  
  try {
    const result = await apiRequest('PUT', `/projects/${projectId}/env`, {
      [key]: value
    });
    
    console.log(`✅ Переменная ${key} установлена успешно`);
    console.log(`📋 Ответ API:`, JSON.stringify(result, null, 2));
    return result;
  } catch (error) {
    console.error(`❌ Не удалось установить переменную:`, error.message);
    console.log(`\n💡 Возможные причины:`);
    console.log(`   - API endpoint может отличаться`);
    console.log(`   - Токен может не иметь прав на изменение env vars`);
    console.log(`   - Используйте веб-интерфейс Mastra Cloud для настройки переменных`);
    throw error;
  }
}

async function getEnvironmentVariables() {
  console.log(`📋 Получаю переменные окружения для проекта ${projectId}...`);
  
  try {
    const result = await apiRequest('GET', `/projects/${projectId}/env`);
    console.log(`✅ Переменные окружения:`);
    console.log(JSON.stringify(result, null, 2));
    return result;
  } catch (error) {
    console.error(`❌ Не удалось получить переменные:`, error.message);
    throw error;
  }
}

async function restartProject() {
  console.log(`🔄 Перезапускаю проект ${projectId}...`);
  
  try {
    const result = await apiRequest('POST', `/projects/${projectId}/restart`);
    console.log(`✅ Проект перезапущен`);
    console.log(`📋 Ответ API:`, JSON.stringify(result, null, 2));
    return result;
  } catch (error) {
    console.error(`❌ Не удалось перезапустить проект:`, error.message);
    throw error;
  }
}

async function getProjectStatus() {
  console.log(`📊 Проверяю статус проекта ${projectId}...`);
  
  try {
    const result = await apiRequest('GET', `/projects/${projectId}`);
    console.log(`✅ Статус проекта:`);
    console.log(JSON.stringify(result, null, 2));
    return result;
  } catch (error) {
    console.error(`❌ Не удалось получить статус:`, error.message);
    throw error;
  }
}

async function getLogs() {
  console.log(`📜 Получаю логи проекта ${projectId}...`);
  
  try {
    const result = await apiRequest('GET', `/projects/${projectId}/logs`);
    console.log(`✅ Логи проекта:`);
    console.log(result);
    return result;
  } catch (error) {
    console.error(`❌ Не удалось получить логи:`, error.message);
    throw error;
  }
}

// Главная функция
async function main() {
  const command = process.argv[2];
  const args = process.argv.slice(3);

  console.log(`🔐 Используется токен для проекта: ${projectId}`);
  console.log(`👥 Team ID: ${teamId}\n`);

  try {
    switch (command) {
      case 'set-env':
        if (args.length < 2) {
          console.error('❌ Использование: node manage-mastra-cloud.js set-env <KEY> <VALUE>');
          process.exit(1);
        }
        await setEnvironmentVariable(args[0], args[1]);
        break;

      case 'get-env':
        await getEnvironmentVariables();
        break;

      case 'restart':
        await restartProject();
        break;

      case 'status':
        await getProjectStatus();
        break;

      case 'logs':
        await getLogs();
        break;

      default:
        console.log(`📖 Доступные команды:`);
        console.log(`   set-env <KEY> <VALUE>  - Установить переменную окружения`);
        console.log(`   get-env                - Получить все переменные окружения`);
        console.log(`   restart                - Перезапустить проект`);
        console.log(`   status                 - Проверить статус проекта`);
        console.log(`   logs                   - Получить логи`);
        console.log(`\n💡 Пример:`);
        console.log(`   node manage-mastra-cloud.js set-env OPENAI_API_KEY sk-...`);
        process.exit(0);
    }
  } catch (error) {
    console.error(`\n❌ Ошибка выполнения команды:`, error.message);
    console.log(`\n💡 Примечание: API endpoints Mastra Cloud могут отличаться.`);
    console.log(`   Проверьте документацию: https://docs.mastra.ai/cloud/api`);
    process.exit(1);
  }
}

main();

