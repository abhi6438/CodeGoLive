# 22_batch_processing

Async classify 20 invoice descriptions concurrently (asyncio + aiohttp, semaphore=5).

## Setup

```bash
pip install -r requirements.txt
cp .env.example .env
# Fill in .env
```

## Run

```bash
python main.py
```
