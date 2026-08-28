export const COURSES = [
  {
    id: "sap-btp",
    title: "SAP BTP & CAP Development",
    subtitle: "Build cloud-native apps on SAP Business Technology Platform",
    description: "Go from zero to a fully deployed SAP BTP application. You'll master SAPUI5 for the frontend, CAP for the backend, and deploy on BTP with CI/CD pipelines — all in one structured course.",
    status: "available",
    badge: null,
    icon: "🛠️",
    accentColor: "#0070F3",
    accentLight: "#e8f3ff",
    tags: ["CAP", "SAPUI5", "BTP", "Node.js"],
    level: "Beginner → Advanced",
    estimatedHours: 40,
    modules: 6,
    topics: 20,
    highlights: [
      "Build SAPUI5 apps with XML views & OData binding",
      "Design CDS models and expose REST/OData services",
      "Integrate frontend + backend end-to-end on BTP",
      "Deploy with CI/CD pipelines to Cloud Foundry",
    ],
    apiBase: "/api",
  },
  {
    id: "sap-ai",
    title: "SAP AI Core & Generative AI",
    subtitle: "Build AI-powered apps with SAP Generative AI Hub",
    description: "Learn to build Generative AI solutions using SAP AI Core and Gen AI Hub. Master prompt engineering, embeddings, RAG pipelines, function calling, and production-ready AI patterns — all without needing real API keys.",
    status: "available",
    badge: null,
    icon: "🤖",
    accentColor: "#7C3AED",
    accentLight: "#f0ebff",
    tags: ["AI Core", "Gen AI Hub", "LLM", "JavaScript"],
    level: "Intermediate",
    estimatedHours: 40,
    modules: 7,
    topics: 28,
    highlights: [
      "Connect to SAP Generative AI Hub with OpenAI-compatible API",
      "Build RAG pipelines with embeddings and semantic search",
      "Implement function calling and autonomous AI agents",
      "Apply production patterns: retry, caching, guardrails",
    ],
    apiBase: "/api",
  },
];

export function getCourse(id) {
  return COURSES.find((c) => c.id === id) || null;
}
