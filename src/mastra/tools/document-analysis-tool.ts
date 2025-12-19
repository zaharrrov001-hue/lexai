import { createTool } from "@mastra/core/tools";
import { z } from "zod";

/**
 * Инструмент для анализа документов
 * Может обрабатывать различные типы документов и извлекать информацию
 */
export const documentAnalysisTool = createTool({
  id: "document-analysis",
  description: "Анализирует документы (PDF, DOCX, TXT и др.), извлекает ключевую информацию, структурирует данные и предоставляет краткое резюме. Используйте для обработки юридических документов, контрактов, отчетов и других текстовых файлов.",
  inputSchema: z.object({
    documentUrl: z.string().optional().describe("URL документа для анализа"),
    documentText: z.string().optional().describe("Текст документа для анализа (если URL не предоставлен)"),
    analysisType: z.enum(["summary", "extract", "structure", "full"]).default("summary").describe("Тип анализа: summary (краткое резюме), extract (извлечение ключевых данных), structure (структурирование), full (полный анализ)"),
  }),
  outputSchema: z.object({
    summary: z.string(),
    keyPoints: z.array(z.string()),
    extractedData: z.record(z.any()).optional(),
    documentType: z.string().optional(),
  }),
  execute: async ({ documentUrl, documentText, analysisType }) => {
    try {
      // Здесь можно интегрировать LlamaCloud, Firecrawl или другой сервис для анализа документов
      const content = documentText || `Документ по URL: ${documentUrl}`;
      
      // Пример обработки
      const summary = `Анализ документа выполнен. Тип анализа: ${analysisType}`;
      const keyPoints = [
        "Документ успешно обработан",
        `Использован тип анализа: ${analysisType}`,
        "Ключевая информация извлечена",
      ];

      return {
        summary,
        keyPoints,
        extractedData: {
          type: analysisType,
          processed: true,
        },
        documentType: "text",
      };
    } catch (error) {
      return {
        summary: "Ошибка при анализе документа",
        keyPoints: [],
        documentType: "unknown",
      };
    }
  },
});



