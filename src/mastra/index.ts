import { Mastra } from "@mastra/core/mastra";
import { LibSQLStore } from "@mastra/libsql";
import { lexaiAgent } from "./agents/lexai-agent";
import { legalConsultationWorkflow } from "./workflows/legal-consultation-workflow";

/**
 * Mastra Instance - главная точка входа для LexAI агента
 * 
 * Регистрирует всех агентов, workflows и делает их доступными через API
 * Настроен storage для memory (история разговоров, working memory, semantic recall)
 */
export const mastra = new Mastra({
  agents: {
    lexaiAgent,
  },
  workflows: {
    legalConsultationWorkflow,
  },
  // Storage для memory - хранит историю разговоров, working memory и semantic recall
  storage: new LibSQLStore({
    url: process.env.DATABASE_URL || "file:./lexai-memory.db",
  }),
  // Настройки сервера
  server: {
    port: parseInt(process.env.PORT || "4111", 10),
    timeout: 3 * 60 * 1000, // 3 минуты
    cors: {
      origin: process.env.CORS_ORIGIN ? process.env.CORS_ORIGIN.split(",") : "*",
      allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
      allowHeaders: ["Content-Type", "Authorization"],
      credentials: false,
    },
  },
  // Можно добавить дополнительные настройки:
  // - logger: для логирования
  // - telemetry: для мониторинга
});



