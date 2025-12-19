import { createTool } from "@mastra/core/tools";
import { z } from "zod";

/**
 * Инструмент для работы с юридическими запросами
 * Помогает анализировать правовые вопросы и предоставлять юридическую информацию
 */
export const legalQueryTool = createTool({
  id: "legal-query",
  description: "Обрабатывает юридические запросы, анализирует правовые вопросы, предоставляет информацию о законах, нормах и прецедентах. Используйте для получения юридических консультаций, анализа договоров и правовых документов.",
  inputSchema: z.object({
    question: z.string().describe("Юридический вопрос или запрос на русском языке"),
    context: z.string().optional().describe("Дополнительный контекст или документы, связанные с вопросом"),
    jurisdiction: z.string().optional().default("RU").describe("Юрисдикция (RU, US, EU и т.д.)"),
  }),
  outputSchema: z.object({
    answer: z.string(),
    relevantLaws: z.array(z.string()).optional(),
    recommendations: z.array(z.string()).optional(),
    riskLevel: z.enum(["low", "medium", "high"]).optional(),
  }),
  execute: async ({ question, context, jurisdiction = "RU" }) => {
    try {
      // Здесь можно интегрировать базу знаний о законах, прецедентах и т.д.
      const answer = `Анализ юридического вопроса выполнен для юрисдикции ${jurisdiction}. Вопрос: ${question}`;
      
      const relevantLaws = [
        "Гражданский кодекс РФ",
        "Трудовой кодекс РФ",
      ];

      const recommendations = [
        "Рекомендуется проконсультироваться с квалифицированным юристом",
        "Проверьте актуальность нормативных актов",
      ];

      return {
        answer,
        relevantLaws,
        recommendations,
        riskLevel: "medium" as const,
      };
    } catch (error) {
      return {
        answer: "Ошибка при обработке юридического запроса",
        recommendations: ["Обратитесь к специалисту"],
      };
    }
  },
});



