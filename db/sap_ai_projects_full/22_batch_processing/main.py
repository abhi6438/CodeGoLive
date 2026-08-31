"""
Project: SAP AI Core Python Examples
Topic:   22_batch_processing
Goal:    Async classify 20 invoice descriptions concurrently (asyncio + aiohttp, semaphore=5).
Requirements: pip install aiohttp
"""

import asyncio, aiohttp, json
from config import HEADERS, URL, INVOICES, SYSTEM

async def classify_one(session, sem, idx, description):
    async with sem:
        payload = {
            "model": "gpt-4o",
            "messages": [
                {"role": "system", "content": SYSTEM},
                {"role": "user", "content": description},
            ],
            "max_tokens": 15,
        }
        async with session.post(URL, headers=HEADERS, json=payload) as resp:
            resp.raise_for_status()
            data  = await resp.json()
            label = data["choices"][0]["message"]["content"].strip()
            return idx, label

async def main():
    sem = asyncio.Semaphore(5)
    async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=60)) as session:
        tasks   = [classify_one(session, sem, i, desc) for i, desc in enumerate(INVOICES)]
        results = await asyncio.gather(*tasks)
    results.sort()
    print(f"{'#':<4} {'Category':<18} Invoice Description")
    print("-" * 80)
    for idx, label in results:
        print(f"{idx+1:<4} {label:<18} {INVOICES[idx][:58]}")

if __name__ == "__main__":
    asyncio.run(main())
