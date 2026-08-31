"""
Project: SAP AI Core Python Examples
Topic:   17_multi_modal
Goal:    Send a SAP screenshot to GPT-4V for UI analysis.
         If no image file is found, uses a detailed text description instead.
"""

import requests, base64, pathlib
from config import HEADERS, URL, SCREENSHOT_DESCRIPTION

def analyze_screenshot(use_real_image=False, image_path="sap_screenshot.png"):
    if use_real_image and pathlib.Path(image_path).exists():
        img_data = base64.b64encode(pathlib.Path(image_path).read_bytes()).decode()
        content = [
            {"type": "text", "text": "Analyze this SAP Fiori screenshot. Identify UX issues, action items, and system health indicators."},
            {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{img_data}"}},
        ]
    else:
        print("No screenshot file found – using text description.\n")
        content = (
            f"Analyze this SAP Fiori screenshot description as if you could see it.\n\n"
            f"{SCREENSHOT_DESCRIPTION}\n\n"
            "Identify: 1) Urgent action items, 2) UX issues, 3) System health concerns."
        )

    r = requests.post(URL, headers=HEADERS, json={
        "model": "gpt-4o",
        "messages": [
            {"role": "system", "content": "You are an SAP UX consultant and Basis expert."},
            {"role": "user", "content": content},
        ],
        "max_tokens": 350,
    }, timeout=30)
    r.raise_for_status()
    return r.json()["choices"][0]["message"]["content"].strip()

if __name__ == "__main__":
    analysis = analyze_screenshot()
    print("SAP Screenshot Analysis\n" + "=" * 40)
    print(analysis)
