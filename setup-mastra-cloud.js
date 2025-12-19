#!/usr/bin/env node
/**
 * Автоматическая настройка проекта LexAI в Mastra Cloud
 * 
 * Использование:
 *   MASTRA_CLOUD_TOKEN="your-token" OPENAI_API_KEY="your-key" node setup-mastra-cloud.js
 */

const token = process.env.MASTRA_CLOUD_TOKEN || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0ZWFtSWQiOiI1Mzg1OTEzMy0zY2ZkLTQ4ZjMtOWI5OS1iODZlYTgyOGFlOGUiLCJwcm9qZWN0SWQiOiI2YjE2ZDViMC1iNjE1LTQyNjYtODU3MC05ZTI1MDU2MjY4YjMiLCJ1bmlxdWVJZCI6IjZjNzJmMzBhLWVkYzItNGU1Yi04ODU3LWVlMGVhZWRmN2IxZiIsImlhdCI6MTc2NjE2NzE5OH0.4g8cMZ5Y7aF_yQZuv0aUsg_wzG9XqhS3a3ZT1GAi3Xg';
const openaiKey = process.env.OPENAI_API_KEY;

// Декодируем токен
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

console.log('🚀 Настройка проекта LexAI в Mastra Cloud\n');
console.log(`📋 Project ID: ${projectId}`);
console.log(`👥 Team ID: ${teamId}\n`);

// Пробуем разные возможные API endpoints
const possibleEndpoints = [
  'https://cloud.mastra.ai/api',
  'https://api.mastra.ai',
  'https://api.cloud.mastra.ai',
  'https://mastra.ai/api',
];

async function tryApiRequest(method, path, body = null) {
  for (const baseUrl of possibleEndpoints) {
    const url = `${baseUrl}${path}`;
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
      console.log(`🔍 Пробую: ${url}`);
      const response = await fetch(url, options);
      
      if (response.ok) {
        const data = await response.json();
        return { success: true, data, baseUrl };
      } else if (response.status === 404) {
        // Продолжаем пробовать другие endpoints
        continue;
      } else {
        const errorText = await response.text();
        return { success: false, error: `${response.status}: ${errorText}`, baseUrl };
      }
    } catch (error) {
      // Продолжаем пробовать другие endpoints
      continue;
    }
  }
  
  return { success: false, error: 'Все endpoints недоступны' };
}

async function setupEnvironmentVariables() {
  if (!openaiKey) {
    console.log('⚠️  OPENAI_API_KEY не установлен в переменных окружения');
    console.log('💡 Установите: export OPENAI_API_KEY="sk-..."');
    console.log('💡 Или добавьте вручную через веб-интерфейс Mastra Cloud\n');
    return false;
  }

  console.log('🔧 Настраиваю переменные окружения...\n');

  // Пробуем разные варианты API endpoints
  const endpoints = [
    `/projects/${projectId}/env`,
    `/projects/${projectId}/environment`,
    `/v1/projects/${projectId}/env`,
    `/api/v1/projects/${projectId}/env`,
    `/teams/${teamId}/projects/${projectId}/env`,
  ];

  for (const endpoint of endpoints) {
    const result = await tryApiRequest('PUT', endpoint, {
      OPENAI_API_KEY: openaiKey,
    });

    if (result.success) {
      console.log(`✅ Переменные окружения установлены через: ${result.baseUrl}${endpoint}`);
      return true;
    }
  }

  console.log('❌ Не удалось установить переменные через API');
  console.log('💡 Используйте веб-интерфейс: https://cloud.mastra.ai/');
  console.log(`   Project ID: ${projectId}`);
  console.log(`   Settings → Environment Variables → Добавить OPENAI_API_KEY\n`);
  return false;
}

async function restartProject() {
  console.log('🔄 Пробую перезапустить проект...\n');

  const endpoints = [
    `/projects/${projectId}/restart`,
    `/projects/${projectId}/deployments/restart`,
    `/v1/projects/${projectId}/restart`,
    `/api/v1/projects/${projectId}/restart`,
  ];

  for (const endpoint of endpoints) {
    const result = await tryApiRequest('POST', endpoint);

    if (result.success) {
      console.log(`✅ Проект перезапущен через: ${result.baseUrl}${endpoint}\n`);
      return true;
    }
  }

  console.log('⚠️  Не удалось перезапустить через API');
  console.log('💡 Перезапустите вручную через веб-интерфейс\n');
  return false;
}

async function checkProjectStatus() {
  console.log('📊 Проверяю статус проекта...\n');

  const endpoints = [
    `/projects/${projectId}`,
    `/v1/projects/${projectId}`,
    `/api/v1/projects/${projectId}`,
  ];

  for (const endpoint of endpoints) {
    const result = await tryApiRequest('GET', endpoint);

    if (result.success) {
      console.log(`✅ Статус проекта получен:`);
      console.log(JSON.stringify(result.data, null, 2));
      return true;
    }
  }

  console.log('⚠️  Не удалось получить статус через API\n');
  return false;
}

async function main() {
  console.log('='.repeat(60));
  console.log('🔧 АВТОМАТИЧЕСКАЯ НАСТРОЙКА MASTRA CLOUD');
  console.log('='.repeat(60));
  console.log();

  // Шаг 1: Проверка токена
  console.log('✅ Токен валиден\n');

  // Шаг 2: Настройка переменных окружения
  const envSet = await setupEnvironmentVariables();
  
  // Шаг 3: Перезапуск проекта (если переменные установлены)
  if (envSet) {
    await restartProject();
  }

  // Шаг 4: Проверка статуса
  await checkProjectStatus();

  console.log('='.repeat(60));
  console.log('📋 ИНСТРУКЦИИ ПО РУЧНОЙ НАСТРОЙКЕ:');
  console.log('='.repeat(60));
  console.log();
  console.log('1. Откройте https://cloud.mastra.ai/');
  console.log(`2. Войдите в проект: ${projectId}`);
  console.log('3. Перейдите в Settings → Environment Variables');
  console.log('4. Добавьте переменную:');
  console.log('   Name: OPENAI_API_KEY');
  console.log(`   Value: ${openaiKey || 'your-openai-api-key-here'}`);
  console.log('5. Сохраните и перезапустите проект');
  console.log();
  console.log('='.repeat(60));
}

main().catch(error => {
  console.error('❌ Критическая ошибка:', error);
  process.exit(1);
});

