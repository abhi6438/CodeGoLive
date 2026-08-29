DO $$ DECLARE m7 uuid; m8 uuid; BEGIN

-- ─────────────────────────────────────────────────────────────────────────────
-- MODULE 107 – Advanced Agentic AI
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO public.modules (number, title, subtitle, order_index, course_id)
VALUES (107, 'Advanced Agentic AI', 'MCP, LangChain, LangGraph, A2A, HANA Vector', 7, 'sap-ai')
ON CONFLICT (number) DO UPDATE SET title = EXCLUDED.title, subtitle = EXCLUDED.subtitle, course_id = EXCLUDED.course_id
RETURNING id INTO m7;
IF m7 IS NULL THEN SELECT id INTO m7 FROM public.modules WHERE number = 107; END IF;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m7, 'ai-28', 'ai-28-mcp-server', '28 · MCP Server', 'Protocol & Tools',
  'Build a Python MCP server that exposes SAP system data (materials, POs, users) as AI-readable tools using the Model Context Protocol.',
  'A running MCP server with 3 SAP data tools', 0, 'published')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m7, 'ai-29', 'ai-29-mcp-client', '29 · MCP Client', 'Connecting AI to MCP',
  'Connect Claude/GPT to your MCP server. The AI discovers tools automatically and calls them to answer SAP questions.',
  'An AI client that auto-discovers and calls MCP tools', 1, 'published')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m7, 'ai-30', 'ai-30-langchain', '30 · LangChain + GenAI Hub', 'LangChain Framework',
  'Use LangChain''s ChatOpenAI pointed at the GenAI Hub endpoint. Build chains, memory, and LCEL pipelines for SAP workflows.',
  'A LangChain-powered SAP assistant with memory and chains', 2, 'published')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m7, 'ai-31', 'ai-31-langgraph', '31 · LangGraph Agents', 'Stateful Agent Graphs',
  'Build stateful multi-step agents with LangGraph. Nodes represent actions, edges represent decisions. Build a procurement approval graph.',
  'A LangGraph agent that routes SAP approval workflows', 3, 'published')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m7, 'ai-32', 'ai-32-a2a-protocol', '32 · A2A Protocol', 'Agent-to-Agent',
  'Implement Google''s Agent-to-Agent protocol so two SAP AI agents (procurement and finance) can hand off tasks to each other.',
  'Two communicating agents that hand off SAP tasks', 4, 'published')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m7, 'ai-33', 'ai-33-hana-vector', '33 · SAP HANA Vector Engine', 'In-Database RAG',
  'Use SAP HANA Cloud''s built-in VECTOR column type and COSINE_SIMILARITY function to build RAG directly inside the database.',
  'A HANA-native vector search over SAP documents', 5, 'published')
ON CONFLICT (slug) DO NOTHING;

-- ─────────────────────────────────────────────────────────────────────────────
-- MODULE 108 – SAP Ecosystem & Production
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO public.modules (number, title, subtitle, order_index, course_id)
VALUES (108, 'SAP Ecosystem & Production', 'DOX, Joule, Eval, Fine-Tuning, Whisper, CAP AI SDK, Cost', 8, 'sap-ai')
ON CONFLICT (number) DO UPDATE SET title = EXCLUDED.title, subtitle = EXCLUDED.subtitle, course_id = EXCLUDED.course_id
RETURNING id INTO m8;
IF m8 IS NULL THEN SELECT id INTO m8 FROM public.modules WHERE number = 108; END IF;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m8, 'ai-34', 'ai-34-dox-service', '34 · Document Information Extraction', 'SAP DOX Service',
  'Call the SAP Document Information Extraction (DOX) BTP service to extract fields from invoices, POs, and receipts automatically.',
  'An invoice extractor using SAP DOX API', 0, 'published')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m8, 'ai-35', 'ai-35-joule-extensions', '35 · Extending SAP Joule', 'Custom Joule Skills',
  'Build a custom Joule skill that surfaces AI-generated summaries and recommendations inside the SAP S/4HANA Joule panel.',
  'A deployed Joule skill with custom AI capability', 1, 'published')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m8, 'ai-36', 'ai-36-llm-eval', '36 · LLM Evaluation & Testing', 'Eval Frameworks',
  'Test AI output quality systematically: RAGAS for RAG accuracy, LLM-as-judge pattern, regression test suites for SAP prompts.',
  'An eval suite that scores RAG pipeline accuracy', 2, 'published')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m8, 'ai-37', 'ai-37-fine-tuning', '37 · Fine-Tuning on AI Core', 'Custom Model Training',
  'Submit a fine-tuning job to SAP AI Core. Prepare JSONL training data from SAP support tickets and track training metrics.',
  'A fine-tuned model trained on SAP domain data', 3, 'published')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m8, 'ai-38', 'ai-38-whisper', '38 · Speech & Audio (Whisper)', 'Voice-to-SAP',
  'Transcribe SAP meeting recordings with Whisper API, extract action items, and push them as SAP tasks automatically.',
  'A meeting recorder that creates SAP tasks from speech', 4, 'published')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m8, 'ai-39', 'ai-39-cap-ai-sdk', '39 · CAP AI SDK (TypeScript)', 'Official SAP AI SDK',
  'Use @sap-ai-sdk/foundation-models in a TypeScript CAP app. Typed client, built-in auth, streaming, and error handling.',
  'A typed CAP service using the official SAP AI SDK', 5, 'published')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m8, 'ai-40', 'ai-40-cost-optimization', '40 · Cost Optimization', 'Prompt Caching & Model Selection',
  'Cut AI costs with prompt caching headers, GPT-4o-mini routing for simple tasks, token budgeting, and batching strategies.',
  'A cost analyzer that reduces token spend by 60%+', 6, 'published')
ON CONFLICT (slug) DO NOTHING;

END $$;
