-- Bulk-publish all SAP AI Core topics (set status = 'published')
UPDATE public.topics
SET status = 'published'
WHERE module_id IN (
  SELECT m.id
  FROM public.modules m
  WHERE m.course_id = 'sap-ai'
);

-- Verify
SELECT count(*) AS published_count
FROM public.topics t
JOIN public.modules m ON m.id = t.module_id
WHERE m.course_id = 'sap-ai'
  AND t.status = 'published';
