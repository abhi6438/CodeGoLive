DO $$ DECLARE m9 uuid; BEGIN

INSERT INTO public.modules (number, title, subtitle, order_index, course_id)
VALUES (109, 'Advanced Techniques', 'Advanced RAG, observability, JS, local dev, image generation', 9, 'sap-ai')
ON CONFLICT (number) DO UPDATE SET title = EXCLUDED.title, subtitle = EXCLUDED.subtitle, course_id = EXCLUDED.course_id
RETURNING id INTO m9;
IF m9 IS NULL THEN SELECT id INTO m9 FROM public.modules WHERE number = 109; END IF;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m9, 'ai-41', 'ai-41-advanced-rag', '41 · Advanced RAG', 'HyPE, BM25, Reranking',
  'Go beyond naive RAG with hypothetical document embeddings (HyPE), BM25 hybrid search, reciprocal rank fusion, and cross-encoder reranking to dramatically improve retrieval accuracy.',
  'An advanced RAG pipeline that outperforms naive retrieval on SAP questions', 0, 'published')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m9, 'ai-42', 'ai-42-ai-observability', '42 · AI Observability', 'Tracing with Langfuse',
  'Instrument your SAP AI pipelines with distributed tracing. Log every prompt, retrieval step, token count, and latency to Langfuse for debugging and optimization.',
  'A fully traced RAG pipeline with Langfuse dashboards', 1, 'published')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m9, 'ai-43', 'ai-43-js-genai-hub', '43 · JavaScript + GenAI Hub', 'Node.js Native Fetch',
  'Call the SAP GenAI Hub from Node.js using native fetch. Build a SAPAIClient class with chat() and stream() methods — no npm packages needed.',
  'A Node.js AI client with streaming support using only built-in APIs', 2, 'published')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m9, 'ai-44', 'ai-44-ollama-local', '44 · Local Dev with Ollama', 'Offline LLM Development',
  'Run Llama 3 locally with Ollama for development without API keys. Swap to SAP GenAI Hub in production using the same interface — zero code changes.',
  'A dual-mode AI client that switches between local and cloud automatically', 3, 'published')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m9, 'ai-45', 'ai-45-image-generation', '45 · Image Generation', 'DALL-E 3 via GenAI Hub',
  'Generate SAP architecture diagrams, workflow visuals, and UI mockups from text prompts using DALL-E 3 through the SAP GenAI Hub images endpoint.',
  'An image generator that creates SAP-themed diagrams from natural language', 4, 'published')
ON CONFLICT (slug) DO NOTHING;

END $$;

UPDATE public.courses SET estimated_hours = 70, updated_at = now() WHERE id = 'sap-ai';
