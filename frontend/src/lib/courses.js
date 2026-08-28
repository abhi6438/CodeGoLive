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
    subtitle: "Deploy and orchestrate AI models on SAP AI Core",
    description: "Learn to build and deploy Generative AI solutions using SAP AI Core and Gen AI Hub. Covers LLM orchestration, prompt engineering, and building AI-powered SAP applications with Python.",
    status: "coming_soon",
    badge: "Coming Soon",
    icon: "🤖",
    accentColor: "#7C3AED",
    accentLight: "#f0ebff",
    tags: ["AI Core", "Gen AI Hub", "LLM", "Python"],
    level: "Intermediate",
    estimatedHours: 25,
    modules: 5,
    topics: 18,
    highlights: [
      "Set up SAP AI Core and connect to Gen AI Hub",
      "Build LLM-powered apps with prompt templates",
      "Orchestrate multi-model AI pipelines",
      "Deploy AI services in production on BTP",
    ],
    apiBase: null,
  },
];

export function getCourse(id) {
  return COURSES.find((c) => c.id === id) || null;
}
