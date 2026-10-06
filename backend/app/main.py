from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from .config import get_settings
from .routers import modules, topics, questions, answers, replies, moderation, admin, notifications, certificates, courses, progress, analytics, profile, assessment, arena

settings = get_settings()

app = FastAPI(title="CodeGoLive API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    origin = request.headers.get("origin", "")
    allowed = settings.ALLOWED_ORIGINS
    headers = {}
    if origin in allowed or "*" in allowed:
        headers["Access-Control-Allow-Origin"] = origin
        headers["Access-Control-Allow-Credentials"] = "true"
    return JSONResponse(
        status_code=500,
        content={"detail": str(exc)},
        headers=headers,
    )


app.include_router(courses.router)
app.include_router(progress.router)
app.include_router(modules.router)
app.include_router(topics.router)
app.include_router(questions.router)
app.include_router(answers.router)
app.include_router(replies.router)
app.include_router(moderation.router)
app.include_router(admin.router)
app.include_router(notifications.router)
app.include_router(certificates.router)
app.include_router(analytics.router)
app.include_router(profile.router)
app.include_router(assessment.router)
app.include_router(arena.router)


@app.get("/api/health")
async def health():
    return {"status": "ok"}


# ── SEO: server-rendered topic pages for Googlebot ─────────────────────────
import markdown as _md
from fastapi.responses import HTMLResponse

@app.get("/topics/{slug}", response_class=HTMLResponse, include_in_schema=False)
async def render_topic_html(slug: str):
    """Return a fully crawlable HTML page for each topic — used by Google."""
    from .supabase_client import get_supabase
    sb = get_supabase()

    topic_res = sb.table("topics").select(
        "slug, title, description, content_md, modules(title, course_id, courses(title, slug))"
    ).eq("slug", slug).eq("status", "published").maybe_single().execute()

    if not topic_res or not topic_res.data:
        return HTMLResponse(status_code=404, content="<h1>Topic not found</h1>")

    t = topic_res.data
    mod = (t.get("modules") or {})
    course = (mod.get("courses") or {})
    course_title = course.get("title", "CodeGoLive")
    course_slug = course.get("slug", "")
    module_title = mod.get("title", "")

    title = t.get("title", "")
    description = t.get("description", "") or ""
    content_md = t.get("content_md", "") or ""

    # Convert markdown to HTML (fenced_code + tables extensions)
    content_html = _md.markdown(content_md, extensions=["fenced_code", "tables", "nl2br"])

    page_title = f"{title} | {course_title} | CodeGoLive"
    canonical = f"https://www.codegolive.com/topics/{slug}"
    course_url = f"https://www.codegolive.com/course/{course_slug}" if course_slug else "https://www.codegolive.com"

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{page_title}</title>
  <meta name="description" content="{description}">
  <meta name="robots" content="index, follow">
  <link rel="canonical" href="{canonical}">
  <meta property="og:type" content="article">
  <meta property="og:title" content="{title} | CodeGoLive">
  <meta property="og:description" content="{description}">
  <meta property="og:url" content="{canonical}">
  <meta property="og:site_name" content="CodeGoLive">
  <script type="application/ld+json">
  {{
    "@context": "https://schema.org",
    "@type": "LearningResource",
    "name": "{title}",
    "description": "{description}",
    "url": "{canonical}",
    "isPartOf": {{ "@type": "Course", "name": "{course_title}", "url": "{course_url}" }},
    "provider": {{ "@type": "Organization", "name": "CodeGoLive", "url": "https://www.codegolive.com" }},
    "educationalLevel": "beginner",
    "inLanguage": "en"
  }}
  </script>
  <style>
    *,*::before,*::after{{box-sizing:border-box}}
    body{{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;
          line-height:1.7;color:#1a1a2e;background:#fff;margin:0;padding:0}}
    .wrap{{max-width:860px;margin:0 auto;padding:2rem 1.5rem 4rem}}
    .breadcrumb{{font-size:.85rem;color:#666;margin-bottom:1.5rem}}
    .breadcrumb a{{color:#0070f3;text-decoration:none}}
    .breadcrumb a:hover{{text-decoration:underline}}
    h1{{font-size:2rem;font-weight:700;color:#0f172a;margin:0 0 0.5rem}}
    .desc{{font-size:1.05rem;color:#555;margin-bottom:2rem;border-bottom:1px solid #e5e7eb;padding-bottom:1.5rem}}
    h2{{font-size:1.35rem;font-weight:600;color:#0f172a;margin:2rem 0 0.75rem}}
    h3{{font-size:1.1rem;font-weight:600;margin:1.5rem 0 0.5rem}}
    p{{margin:0 0 1rem}}
    pre{{background:#0f172a;color:#e2e8f0;padding:1.25rem 1.5rem;border-radius:8px;
         overflow-x:auto;font-size:.875rem;line-height:1.6;margin:1rem 0}}
    code{{font-family:"Fira Code",Consolas,monospace;font-size:.875em}}
    p code,li code{{background:#f1f5f9;color:#0f172a;padding:.1em .4em;border-radius:4px}}
    ul,ol{{padding-left:1.5rem;margin:0 0 1rem}}
    li{{margin-bottom:.35rem}}
    table{{width:100%;border-collapse:collapse;margin:1.5rem 0;font-size:.9rem}}
    th{{background:#f8fafc;font-weight:600;text-align:left;padding:.6rem .85rem;border:1px solid #e5e7eb}}
    td{{padding:.55rem .85rem;border:1px solid #e5e7eb}}
    blockquote{{border-left:4px solid #0070f3;margin:1.5rem 0;padding:.75rem 1.25rem;
                background:#f0f7ff;color:#374151;border-radius:0 6px 6px 0}}
    .cta{{display:inline-block;margin-top:2rem;padding:.75rem 1.75rem;
          background:#0070f3;color:#fff;border-radius:8px;text-decoration:none;
          font-weight:600;font-size:.95rem}}
    .cta:hover{{background:#005fd4}}
    .site-nav{{border-bottom:1px solid #e5e7eb;padding:1rem 1.5rem;
               display:flex;align-items:center;justify-content:space-between}}
    .site-nav a{{text-decoration:none;color:#0f172a;font-weight:600;font-size:1rem}}
    .site-nav .signin{{font-size:.875rem;color:#0070f3}}
    @media(prefers-color-scheme:dark){{
      body{{color:#e2e8f0;background:#0f172a}}
      h1,h2,h3{{color:#f1f5f9}}
      .desc{{color:#94a3b8}}
      p code,li code{{background:#1e293b;color:#e2e8f0}}
      .desc,.site-nav{{border-color:#1e293b}}
      th{{background:#1e293b;border-color:#334155}}
      td{{border-color:#334155}}
      blockquote{{background:#1e293b;color:#cbd5e1}}
      .breadcrumb{{color:#94a3b8}}
    }}
  </style>
</head>
<body>
  <nav class="site-nav">
    <a href="https://www.codegolive.com">CodeGoLive</a>
    <a class="signin" href="https://www.codegolive.com/login">Sign in for interactive mode →</a>
  </nav>
  <div class="wrap">
    <div class="breadcrumb">
      <a href="https://www.codegolive.com">Home</a> ›
      <a href="{course_url}">{course_title}</a> ›
      {module_title} › {title}
    </div>
    <h1>{title}</h1>
    <p class="desc">{description}</p>
    {content_html}
    <a class="cta" href="https://www.codegolive.com/login">
      Sign in for progress tracking &amp; Q&amp;A →
    </a>
  </div>
</body>
</html>"""
    return HTMLResponse(content=html)
