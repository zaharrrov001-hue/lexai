import { createWorkflow, createStep } from "@mastra/core/workflows";
import { z } from "zod";
import { webSearchTool, documentAnalysisTool, legalQueryTool } from "../tools";

/**
 * Шаг 1: Поиск актуальной информации в интернете
 */
const searchStep = createStep({
  id: "search-legal-info",
  inputSchema: z.object({
    question: z.string().describe("Юридический вопрос для поиска информации"),
    documents: z.array(
      z.object({
        url: z.string().optional(),
        text: z.string().optional(),
      })
    ).optional(),
    jurisdiction: z.string().optional().default("RU"),
  }),
  outputSchema: z.object({
    question: z.string(),
    documents: z.array(
      z.object({
        url: z.string().optional(),
        text: z.string().optional(),
      })
    ).optional(),
    jurisdiction: z.string().optional(),
    searchResults: z.array(
      z.object({
        title: z.string(),
        url: z.string(),
        content: z.string(),
      })
    ),
  }),
  execute: async ({ inputData }) => {
    const { question, documents, jurisdiction } = inputData;
    
    // Используем webSearchTool для поиска информации
    const searchResult = await webSearchTool.execute({
      query: question,
      limit: 5,
    });

    return {
      question,
      documents,
      jurisdiction,
      searchResults: searchResult.results || [],
    };
  },
});

/**
 * Шаг 2: Анализ документов (если предоставлены)
 */
const analyzeDocumentsStep = createStep({
  id: "analyze-documents",
  inputSchema: z.object({
    question: z.string(),
    documents: z.array(
      z.object({
        url: z.string().optional(),
        text: z.string().optional(),
      })
    ).optional(),
    jurisdiction: z.string().optional(),
    searchResults: z.array(
      z.object({
        title: z.string(),
        url: z.string(),
        content: z.string(),
      })
    ),
  }),
  outputSchema: z.object({
    question: z.string(),
    jurisdiction: z.string().optional(),
    searchResults: z.array(
      z.object({
        title: z.string(),
        url: z.string(),
        content: z.string(),
      })
    ),
    documentAnalysis: z.array(
      z.object({
        summary: z.string(),
        keyPoints: z.array(z.string()),
      })
    ).optional(),
  }),
  execute: async ({ inputData }) => {
    const { documents, question, jurisdiction, searchResults } = inputData;

    let documentAnalysis = undefined;
    if (documents && documents.length > 0) {
      const analyses = await Promise.all(
        documents.map(async (doc) => {
          const result = await documentAnalysisTool.execute({
            documentUrl: doc.url,
            documentText: doc.text,
            analysisType: "summary",
          });
          return {
            summary: result.summary,
            keyPoints: result.keyPoints,
          };
        })
      );
      documentAnalysis = analyses;
    }

    return {
      question,
      jurisdiction,
      searchResults,
      documentAnalysis,
    };
  },
});

/**
 * Шаг 3: Обработка юридического запроса с учетом найденной информации
 */
const processLegalQueryStep = createStep({
  id: "process-legal-query",
  inputSchema: z.object({
    question: z.string(),
    jurisdiction: z.string().optional(),
    searchResults: z.array(
      z.object({
        title: z.string(),
        url: z.string(),
        content: z.string(),
      })
    ),
    documentAnalysis: z.array(
      z.object({
        summary: z.string(),
        keyPoints: z.array(z.string()),
      })
    ).optional(),
  }),
  outputSchema: z.object({
    question: z.string(),
    searchResults: z.array(
      z.object({
        title: z.string(),
        url: z.string(),
        content: z.string(),
      })
    ),
    legalAnswer: z.object({
      answer: z.string(),
      relevantLaws: z.array(z.string()).optional(),
      recommendations: z.array(z.string()).optional(),
      riskLevel: z.enum(["low", "medium", "high"]).optional(),
    }),
  }),
  execute: async ({ inputData }) => {
    const { question, searchResults = [], documentAnalysis = [], jurisdiction = "RU" } = inputData;

    // Формируем контекст из результатов поиска и анализа документов
    const contextParts: string[] = [];
    
    if (searchResults && searchResults.length > 0) {
      contextParts.push(...searchResults.map((r) => `${r.title}: ${r.content}`));
    }
    
    if (documentAnalysis && documentAnalysis.length > 0) {
      contextParts.push(...documentAnalysis.map((d) => d.summary));
    }

    const context = contextParts.length > 0 ? contextParts.join("\n\n") : undefined;

    // Используем legalQueryTool для обработки запроса
    const result = await legalQueryTool.execute({
      question,
      context,
      jurisdiction,
    });

    return {
      question,
      searchResults,
      legalAnswer: {
        answer: result.answer,
        relevantLaws: result.relevantLaws,
        recommendations: result.recommendations,
        riskLevel: result.riskLevel,
      },
    };
  },
});

/**
 * Шаг 4: Формирование финального ответа
 */
const formatResponseStep = createStep({
  id: "format-response",
  inputSchema: z.object({
    question: z.string(),
    searchResults: z.array(
      z.object({
        title: z.string(),
        url: z.string(),
        content: z.string(),
      })
    ),
    legalAnswer: z.object({
      answer: z.string(),
      relevantLaws: z.array(z.string()).optional(),
      recommendations: z.array(z.string()).optional(),
      riskLevel: z.enum(["low", "medium", "high"]).optional(),
    }),
  }),
  outputSchema: z.object({
    response: z.object({
      question: z.string(),
      answer: z.string(),
      sources: z.array(
        z.object({
          title: z.string(),
          url: z.string(),
        })
      ),
      relevantLaws: z.array(z.string()).optional(),
      recommendations: z.array(z.string()).optional(),
      riskLevel: z.enum(["low", "medium", "high"]).optional(),
      disclaimer: z.string(),
    }),
  }),
  execute: async ({ inputData }) => {
    const { question, searchResults, legalAnswer } = inputData;

    return {
      response: {
        question,
        answer: legalAnswer.answer,
        sources: searchResults.map((r) => ({
          title: r.title,
          url: r.url,
        })),
        relevantLaws: legalAnswer.relevantLaws,
        recommendations: legalAnswer.recommendations,
        riskLevel: legalAnswer.riskLevel,
        disclaimer:
          "⚠️ ВАЖНО: Данная информация не является профессиональной юридической консультацией. Для важных решений рекомендуется обратиться к квалифицированному юристу.",
      },
    };
  },
});

/**
 * Workflow для юридических консультаций
 * 
 * Последовательность:
 * 1. Поиск актуальной информации в интернете
 * 2. Анализ документов (если предоставлены)
 * 3. Обработка юридического запроса
 * 4. Формирование структурированного ответа
 */
export const legalConsultationWorkflow = createWorkflow({
  id: "legal-consultation",
  inputSchema: z.object({
    question: z.string().describe("Юридический вопрос на русском языке"),
    documents: z
      .array(
        z.object({
          url: z.string().optional().describe("URL документа для анализа"),
          text: z.string().optional().describe("Текст документа для анализа"),
        })
      )
      .optional()
      .describe("Документы для анализа (опционально)"),
    jurisdiction: z
      .string()
      .optional()
      .default("RU")
      .describe("Юрисдикция (RU, US, EU и т.д.)"),
  }),
  outputSchema: z.object({
    response: z.object({
      question: z.string(),
      answer: z.string(),
      sources: z.array(
        z.object({
          title: z.string(),
          url: z.string(),
        })
      ),
      relevantLaws: z.array(z.string()).optional(),
      recommendations: z.array(z.string()).optional(),
      riskLevel: z.enum(["low", "medium", "high"]).optional(),
      disclaimer: z.string(),
    }),
  }),
})
  .then(searchStep)
  .then(analyzeDocumentsStep)
  .then(processLegalQueryStep)
  .then(formatResponseStep)
  .commit();

