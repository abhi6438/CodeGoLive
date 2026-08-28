-- ============================================================
-- SAP AI Core & Generative AI — Course Seed
-- Run this in Supabase SQL Editor AFTER admin_migration.sql
-- ============================================================

-- Step 1: Ensure the sap-ai course is marked available
UPDATE public.courses SET status = 'available', estimated_hours = 40, updated_at = now()
WHERE id = 'sap-ai';

-- Step 2: Insert modules for the SAP AI course
-- Uses a DO block so we can reference IDs immediately
DO $$
DECLARE
  m0 uuid; m1 uuid; m2 uuid; m3 uuid; m4 uuid; m5 uuid; m6 uuid;
BEGIN

  -- Module 0: AI Foundations
  INSERT INTO public.modules (number, title, subtitle, order_index, course_id)
  VALUES (100, 'AI Foundations', 'Connect to SAP AI Core and understand the API', 0, 'sap-ai')
  ON CONFLICT (number) DO UPDATE SET title = EXCLUDED.title, subtitle = EXCLUDED.subtitle, course_id = EXCLUDED.course_id
  RETURNING id INTO m0;
  IF m0 IS NULL THEN SELECT id INTO m0 FROM public.modules WHERE number = 100; END IF;

  -- Module 1: Prompt Engineering
  INSERT INTO public.modules (number, title, subtitle, order_index, course_id)
  VALUES (101, 'Prompt Engineering', 'Control AI output with system prompts and techniques', 1, 'sap-ai')
  ON CONFLICT (number) DO UPDATE SET title = EXCLUDED.title, subtitle = EXCLUDED.subtitle, course_id = EXCLUDED.course_id
  RETURNING id INTO m1;
  IF m1 IS NULL THEN SELECT id INTO m1 FROM public.modules WHERE number = 101; END IF;

  -- Module 2: Embeddings & Search
  INSERT INTO public.modules (number, title, subtitle, order_index, course_id)
  VALUES (102, 'Embeddings & Semantic Search', 'Vector embeddings, cosine similarity, and RAG', 2, 'sap-ai')
  ON CONFLICT (number) DO UPDATE SET title = EXCLUDED.title, subtitle = EXCLUDED.subtitle, course_id = EXCLUDED.course_id
  RETURNING id INTO m2;
  IF m2 IS NULL THEN SELECT id INTO m2 FROM public.modules WHERE number = 102; END IF;

  -- Module 3: Advanced AI Patterns
  INSERT INTO public.modules (number, title, subtitle, order_index, course_id)
  VALUES (103, 'Advanced AI Patterns', 'Function calling, agents, data analysis, multi-modal', 3, 'sap-ai')
  ON CONFLICT (number) DO UPDATE SET title = EXCLUDED.title, subtitle = EXCLUDED.subtitle, course_id = EXCLUDED.course_id
  RETURNING id INTO m3;
  IF m3 IS NULL THEN SELECT id INTO m3 FROM public.modules WHERE number = 103; END IF;

  -- Module 4: Production Skills
  INSERT INTO public.modules (number, title, subtitle, order_index, course_id)
  VALUES (104, 'Production Skills', 'Safety, monitoring, templates, batch processing', 4, 'sap-ai')
  ON CONFLICT (number) DO UPDATE SET title = EXCLUDED.title, subtitle = EXCLUDED.subtitle, course_id = EXCLUDED.course_id
  RETURNING id INTO m4;
  IF m4 IS NULL THEN SELECT id INTO m4 FROM public.modules WHERE number = 104; END IF;

  -- Module 5: Integration with SAP
  INSERT INTO public.modules (number, title, subtitle, order_index, course_id)
  VALUES (105, 'SAP Integration', 'CAP+AI, UI5 chat, translation, production patterns', 5, 'sap-ai')
  ON CONFLICT (number) DO UPDATE SET title = EXCLUDED.title, subtitle = EXCLUDED.subtitle, course_id = EXCLUDED.course_id
  RETURNING id INTO m5;
  IF m5 IS NULL THEN SELECT id INTO m5 FROM public.modules WHERE number = 105; END IF;

  -- Module 6: Mini Projects
  INSERT INTO public.modules (number, title, subtitle, order_index, course_id)
  VALUES (106, 'Mini Projects', 'Three full-feature AI apps end-to-end', 6, 'sap-ai')
  ON CONFLICT (number) DO UPDATE SET title = EXCLUDED.title, subtitle = EXCLUDED.subtitle, course_id = EXCLUDED.course_id
  RETURNING id INTO m6;
  IF m6 IS NULL THEN SELECT id INTO m6 FROM public.modules WHERE number = 106; END IF;

  -- ── Module 0 Topics ──────────────────────────────────────────

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m0, 'ai-00', 'ai-00-core-intro', '00 · SAP AI Core Intro', 'First API Call',
    'Connect to the mock SAP AI Core server, call the health and models endpoints, and make your first chat completion call.',
    'A working page that lists models and gets a response from the AI', 0, 'published')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m0, 'ai-01', 'ai-01-genai-hub', '01 · SAP GenAI Hub', 'Model Explorer',
    'Explore available models, send prompts to different models, and compare their responses side by side.',
    'A model explorer that lets you select and compare LLM responses', 1, 'published')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m0, 'ai-02', 'ai-02-prompt-engineering', '02 · Prompt Engineering', 'Prompting Techniques',
    'Master zero-shot, chain-of-thought, role prompting, and constrained output. Use A/B comparison to see the difference.',
    'A prompt lab with A/B comparison across 4 prompting techniques', 2, 'published')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m0, 'ai-03', 'ai-03-chat-completions', '03 · Chat Completions API', 'Multi-Turn Chat',
    'Build a chatbot that maintains full conversation history. Understand how the messages array works in the OpenAI-compatible API.',
    'A multi-turn chatbot that remembers context across messages', 3, 'published')
  ON CONFLICT (slug) DO NOTHING;

  -- ── Module 1 Topics ──────────────────────────────────────────

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m1, 'ai-04', 'ai-04-system-prompts', '04 · System Prompts & Personas', 'Persona Control',
    'Use system prompts to switch AI personas: SAP Expert, Customer Support, Data Analyst, and Pirate. See how the same question gets different answers.',
    'A persona switcher that demonstrates system prompt control', 0, 'published')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m1, 'ai-05', 'ai-05-few-shot', '05 · Few-Shot Learning', 'In-Context Examples',
    'Teach the AI new behaviors with examples in the prompt. Compare zero-shot vs few-shot sentiment classification.',
    'A classifier that demonstrates few-shot vs zero-shot accuracy', 1, 'published')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m1, 'ai-06', 'ai-06-multi-turn', '06 · Multi-Turn Conversations', 'History Management',
    'Build a chat UI that maintains the full history array and lets you inspect the raw JSON sent to the API on every turn.',
    'A chat with a history inspector showing the full messages array', 2, 'published')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m1, 'ai-07', 'ai-07-streaming', '07 · Streaming Responses', 'Server-Sent Events',
    'Stream AI responses token by token using SSE. Compare streaming vs standard mode and see how chunks are parsed.',
    'A streaming chat that shows tokens appearing word by word', 3, 'published')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m1, 'ai-08', 'ai-08-structured-output', '08 · Structured JSON Output', 'JSON Mode',
    'Force AI to return machine-readable JSON. Parse and render product lists, sentiment scores, and entity extractions.',
    'A tool that extracts and renders structured data from AI responses', 4, 'published')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m1, 'ai-09', 'ai-09-function-calling', '09 · Function Calling / Tool Use', 'Tool Loop',
    'Implement the full tool-use loop: define tools, let AI pick one, execute it locally, send the result back, get the final answer.',
    'A weather + calculator + product search tool-use demo', 5, 'published')
  ON CONFLICT (slug) DO NOTHING;

  -- ── Module 2 Topics ──────────────────────────────────────────

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m2, 'ai-10', 'ai-10-embeddings', '10 · Text Embeddings', 'Vector Representation',
    'Generate 1536-dimensional text embeddings. Visualize vector info and compute cosine similarity between two sentences.',
    'An embedding visualizer with similarity comparison', 0, 'published')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m2, 'ai-11', 'ai-11-semantic-search', '11 · Semantic Search', 'Meaning-Based Search',
    'Build a dynamic knowledge base and search it by meaning rather than keywords. Rank results by cosine similarity.',
    'A semantic search engine over a live document set', 1, 'published')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m2, 'ai-12', 'ai-12-rag-indexing', '12 · RAG – Indexing', 'Document Chunking',
    'Split a long document into overlapping chunks, embed each one, and build a vector index ready for retrieval.',
    'A document indexer with configurable chunk size and overlap', 2, 'published')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m2, 'ai-13', 'ai-13-rag-pipeline', '13 · RAG – Full Pipeline', 'Retrieve & Generate',
    'Complete Retrieval-Augmented Generation: embed the question, retrieve the top-3 chunks, build a grounded prompt, get the AI answer.',
    'A full RAG Q&A system grounded in your own documents', 3, 'published')
  ON CONFLICT (slug) DO NOTHING;

  -- ── Module 3 Topics ──────────────────────────────────────────

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m3, 'ai-14', 'ai-14-cap-ai', '14 · CAP + AI Integration', 'Backend AI Service',
    'Build a Node.js service using the SAP CAP pattern. Add AI-powered endpoints: product pitch generator and smart recommendation.',
    'A backend service with AI-enhanced OData-style endpoints', 0, 'published')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m3, 'ai-15', 'ai-15-ui5-ai-chat', '15 · UI5 AI Chat', 'Fiori Chat UI',
    'Build a Fiori-styled AI chat interface with typing indicators, conversation history, and SAP BTP quick-action buttons.',
    'An enterprise-quality AI chat widget in SAP Fiori style', 1, 'published')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m3, 'ai-16', 'ai-16-data-analysis', '16 · AI Data Analysis', 'NL Business Insights',
    'Feed real sales data to AI and ask for trend analysis, anomaly detection, forecasting, and executive summaries.',
    'A data analysis tool powered by natural language prompts', 2, 'published')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m3, 'ai-17', 'ai-17-multi-modal', '17 · Multi-Modal AI', 'Vision Prompting',
    'Simulate vision model patterns with scene-aware prompts. Analyze SAP dashboards, charts, error screens, and forms.',
    'A multi-modal prompt explorer with 4 SAP UI scene types', 3, 'published')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m3, 'ai-18', 'ai-18-ai-agents', '18 · AI Agents', 'Autonomous Workflows',
    'Build an autonomous AI agent with 4 tools (analyze_data, send_report, search_kb, create_ticket). Watch it plan and execute multi-step tasks.',
    'A self-directed agent that plans and executes multi-step SAP tasks', 4, 'published')
  ON CONFLICT (slug) DO NOTHING;

  -- ── Module 4 Topics ──────────────────────────────────────────

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m4, 'ai-19', 'ai-19-prompt-templates', '19 · Prompt Templates', 'Reusable Patterns',
    'Build a prompt template library with {{variable}} placeholders. Auto-detect variables, render inputs, and preview the final prompt.',
    'A template engine that renders and runs parametrised prompts', 0, 'published')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m4, 'ai-20', 'ai-20-ai-safety', '20 · AI Safety & Guardrails', 'Input Validation',
    'Implement keyword blocking, length limits, and prompt injection detection. Test with real attack patterns and see them blocked.',
    'A guardrail system that validates inputs before reaching the AI', 1, 'published')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m4, 'ai-21', 'ai-21-token-monitoring', '21 · Token Monitoring', 'Cost Tracking',
    'Track prompt and completion token usage per request. Calculate cost by model and see running session totals.',
    'A cost dashboard showing real token usage and pricing per model', 2, 'published')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m4, 'ai-22', 'ai-22-batch-processing', '22 · Batch Processing', 'Sequential vs Parallel',
    'Process multiple items (sentiment, summary, category, priority) in sequential and parallel modes. Compare speed and output.',
    'A batch processor with sequential and Promise.all parallel modes', 3, 'published')
  ON CONFLICT (slug) DO NOTHING;

  -- ── Module 5 Topics ──────────────────────────────────────────

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m5, 'ai-23', 'ai-23-translation', '23 · AI Translation', 'Localisation',
    'Translate SAP UI content into 8 languages in parallel. Switch between formal, friendly, and technical tones.',
    'A parallel translator with tone control across 8 languages', 0, 'published')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m5, 'ai-24', 'ai-24-production-patterns', '24 · Production Patterns', 'Retry, Cache & Timeout',
    'Add retry with exponential backoff, response caching, and AbortController timeout. Simulate failures to test resilience.',
    'A production-safe AI client with retry, cache and timeout', 1, 'published')
  ON CONFLICT (slug) DO NOTHING;

  -- ── Module 6 Topics ──────────────────────────────────────────

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m6, 'ai-25', 'ai-25-mp-help-desk', '25 · Mini Project: AI Help Desk', 'Full Support System',
    'Build a complete AI support desk: chat with history, knowledge base lookup, automatic ticket creation, and session statistics.',
    'A production-quality AI support desk with ticketing system', 0, 'published')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m6, 'ai-26', 'ai-26-mp-code-reviewer', '26 · Mini Project: AI Code Reviewer', 'Automated Review',
    'Analyse SAP CAP code for SQL injection, missing auth, and best-practice violations. Four review modes plus AI auto-fix.',
    'A code review tool with security, performance, and CAP mode', 1, 'published')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m6, 'ai-27', 'ai-27-mp-ai-dashboard', '27 · Mini Project: AI BI Dashboard', 'NL Data Queries',
    'KPI tiles, monthly sales table, and a natural language query interface. Ask about trends, anomalies, forecasts, or board summaries.',
    'A business intelligence dashboard with AI-powered natural language queries', 2, 'published')
  ON CONFLICT (slug) DO NOTHING;

END $$;

-- Confirm results
SELECT 'modules' AS tbl, count(*) FROM public.modules WHERE course_id = 'sap-ai'
UNION ALL
SELECT 'topics', count(*) FROM public.topics t
JOIN public.modules m ON t.module_id = m.id
WHERE m.course_id = 'sap-ai';
