import { createTool } from "@mastra/core/tools";
import { z } from "zod";

/**
 * Инструмент для поиска информации в интернете
 * Использует Firecrawl или другие источники для веб-поиска
 */
export const webSearchTool = createTool({
  id: "web-search",
  description: "Ищет информацию в интернете по заданному запросу. Используйте для получения актуальной информации, новостей, документации и других данных из веб-источников.",
  inputSchema: z.object({
    query: z.string().describe("Поисковый запрос на русском или английском языке"),
    limit: z.number().optional().default(5).describe("Количество результатов для возврата (по умолчанию 5)"),
  }),
  outputSchema: z.object({
    results: z.array(
      z.object({
        title: z.string(),
        url: z.string(),
        content: z.string(),
        relevance: z.number().optional(),
      })
    ),
    query: z.string(),
  }),
  execute: async ({ query, limit = 5 }) => {
    try {
      // Здесь можно интегрировать Firecrawl API или другой поисковый сервис
      // Для примера возвращаем структурированный ответ
      const mockResults = [
        {
          title: `Результаты поиска для: ${query}`,
          url: `https://example.com/search?q=${encodeURIComponent(query)}`,
          content: `Информация по запросу "${query}" будет получена через Firecrawl API или другой поисковый сервис.`,
          relevance: 0.9,
        },
      ];

      return {
        results: mockResults.slice(0, limit),
        query,
      };
    } catch (error) {
      return {
        results: [],
        query,
      };
    }
  },
});



