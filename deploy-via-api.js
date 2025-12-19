#!/usr/bin/env node
/**
 * Развертывание проекта LexAI в Mastra Cloud через API
 */

import fetch from 'node-fetch';

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

console.log('🚀 Развертывание проекта LexAI через Mastra Cloud API\n');
console.log(`📋 Project ID: ${projectId}`);
console.log(`👥 Team ID: ${teamId}\n`);

// Возможные базовые URL для API
const baseUrls = [
  'https://cloud.mastra.ai',
  'https://api.mastra.ai',
  'https://api.cloud.mastra.ai',
  'https://mastra.ai',
];

async function apiRequest(baseUrl, method, path, body = null) {
  const url = `${baseUrl}${path}`;
  const options = {
    method,
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  };

  if (body) {
    options.body = JSON.stringify(body);
  }

  try {
    const response = await fetch(url, options);
    const text = await response.text();
    
    let data;
    try {
      data = JSON.parse(text);
    } catch {
      data = text;
    }

    return {
      ok: response.ok,
      status: response.status,
      statusText: response.statusText,
      data,
      url,
    };
  } catch (error) {
    return {
      ok: false,
      error: error.message,
      url,
    };
  }
}

async function tryAllEndpoints(method, paths, body = null) {
  const results = [];
  
  for (const baseUrl of baseUrls) {
    for (const path of paths) {
      console.log(`🔍 Пробую: ${baseUrl}${path}`);
      const result = await apiRequest(baseUrl, method, path, body);
      results.push(result);
      
      if (result.ok) {
        console.log(`✅ Успешно: ${result.url}`);
        return result;
      } else if (result.status === 401) {
        console.log(`❌ Ошибка авторизации: ${result.status} - ${result.statusText}`);
      } else if (result.status === 404) {
        console.log(`⚠️  Endpoint не найден: ${result.status}`);
      } else {
        console.log(`⚠️  Ошибка: ${result.status} - ${JSON.stringify(result.data).substring(0, 100)}`);
      }
    }
  }
  
  return null;
}

async function setEnvironmentVariable() {
  if (!openaiKey) {
    console.log('⚠️  OPENAI_API_KEY не установлен');
    console.log('💡 Установите: export OPENAI_API_KEY="sk-..."');
    return false;
  }

  console.log('\n🔧 Устанавливаю переменные окружения...\n');

  const paths = [
    `/api/v1/projects/${projectId}/env`,
    `/api/v1/projects/${projectId}/environment`,
    `/api/projects/${projectId}/env`,
    `/api/projects/${projectId}/environment`,
    `/v1/projects/${projectId}/env`,
    `/projects/${projectId}/env`,
    `/projects/${projectId}/environment`,
    `/api/teams/${teamId}/projects/${projectId}/env`,
    `/api/teams/${teamId}/projects/${projectId}/environment`,
  ];

  const body = {
    OPENAI_API_KEY: openaiKey,
  };

  const result = await tryAllEndpoints('PUT', paths, body);
  
  if (result && result.ok) {
    console.log(`\n✅ Переменные окружения установлены!`);
    console.log(`📋 Ответ: ${JSON.stringify(result.data, null, 2)}`);
    return true;
  }

  // Пробуем POST вместо PUT
  console.log('\n🔄 Пробую POST метод...\n');
  const postResult = await tryAllEndpoints('POST', paths, body);
  
  if (postResult && postResult.ok) {
    console.log(`\n✅ Переменные окружения установлены через POST!`);
    return true;
  }

  console.log('\n❌ Не удалось установить переменные через API');
  console.log('💡 Используйте веб-интерфейс: https://cloud.mastra.ai/');
  return false;
}

async function triggerDeployment() {
  console.log('\n🚀 Запускаю развертывание...\n');

  const paths = [
    `/api/v1/projects/${projectId}/deploy`,
    `/api/v1/projects/${projectId}/deployments`,
    `/api/projects/${projectId}/deploy`,
    `/api/projects/${projectId}/deployments`,
    `/v1/projects/${projectId}/deploy`,
    `/projects/${projectId}/deploy`,
    `/projects/${projectId}/deployments`,
    `/api/teams/${teamId}/projects/${projectId}/deploy`,
  ];

  const result = await tryAllEndpoints('POST', paths, {
    branch: 'main',
    force: true,
  });

  if (result && result.ok) {
    console.log(`\n✅ Развертывание запущено!`);
    console.log(`📋 Ответ: ${JSON.stringify(result.data, null, 2)}`);
    return true;
  }

  console.log('\n⚠️  Не удалось запустить развертывание через API');
  return false;
}

async function restartProject() {
  console.log('\n🔄 Перезапускаю проект...\n');

  const paths = [
    `/api/v1/projects/${projectId}/restart`,
    `/api/v1/projects/${projectId}/deployments/restart`,
    `/api/projects/${projectId}/restart`,
    `/api/projects/${projectId}/deployments/restart`,
    `/v1/projects/${projectId}/restart`,
    `/projects/${projectId}/restart`,
    `/projects/${projectId}/deployments/restart`,
  ];

  const result = await tryAllEndpoints('POST', paths);

  if (result && result.ok) {
    console.log(`\n✅ Проект перезапущен!`);
    return true;
  }

  console.log('\n⚠️  Не удалось перезапустить через API');
  return false;
}

async function getProjectStatus() {
  console.log('\n📊 Проверяю статус проекта...\n');

  const paths = [
    `/api/v1/projects/${projectId}`,
    `/api/projects/${projectId}`,
    `/v1/projects/${projectId}`,
    `/projects/${projectId}`,
    `/api/teams/${teamId}/projects/${projectId}`,
  ];

  const result = await tryAllEndpoints('GET', paths);

  if (result && result.ok) {
    console.log(`\n✅ Статус проекта:`);
    console.log(JSON.stringify(result.data, null, 2));
    return result.data;
  }

  return null;
}

async function main() {
  console.log('='.repeat(60));
  console.log('🚀 РАЗВЕРТЫВАНИЕ ЧЕРЕЗ MASTRA CLOUD API');
  console.log('='.repeat(60));
  console.log();

  // Шаг 1: Проверка статуса
  const status = await getProjectStatus();

  // Шаг 2: Установка переменных окружения
  const envSet = await setEnvironmentVariable();

  // Шаг 3: Запуск развертывания
  if (envSet) {
    await triggerDeployment();
    // Небольшая задержка перед перезапуском
    await new Promise(resolve => setTimeout(resolve, 2000));
    await restartProject();
  } else {
    console.log('\n⚠️  Пропускаю развертывание - переменные не установлены');
  }

  // Шаг 4: Финальная проверка статуса
  console.log('\n📊 Финальный статус:');
  await getProjectStatus();

  console.log('\n' + '='.repeat(60));
  console.log('✅ Процесс завершен!');
  console.log('='.repeat(60));
  console.log();
  console.log('💡 Если API не сработал, используйте веб-интерфейс:');
  console.log('   https://cloud.mastra.ai/');
  console.log(`   Project ID: ${projectId}`);
  console.log();
}

main().catch(error => {
  console.error('\n❌ Критическая ошибка:', error);
  process.exit(1);
});

