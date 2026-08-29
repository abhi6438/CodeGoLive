from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from .config import get_settings
from .routers import modules, topics, questions, answers, replies, moderation, admin, notifications, certificates, courses

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
app.include_router(modules.router)
app.include_router(topics.router)
app.include_router(questions.router)
app.include_router(answers.router)
app.include_router(replies.router)
app.include_router(moderation.router)
app.include_router(admin.router)
app.include_router(notifications.router)
app.include_router(certificates.router)


@app.get("/api/health")
async def health():
    return {"status": "ok"}
