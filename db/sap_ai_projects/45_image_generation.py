"""
DALL-E 3 Image Generation via SAP GenAI Hub
pip install requests
"""
import os
import json
import urllib.request
from pathlib import Path
from datetime import datetime

# ── Env vars ──────────────────────────────────────────────────────────────────
BASE_URL  = os.environ["AICORE_BASE_URL"]
TOKEN     = os.environ["AICORE_TOKEN"]
IMG_DEPID = os.environ["AICORE_IMAGE_DEPLOYMENT_ID"]
RG        = os.environ["AICORE_RG"]

import requests

HEADERS = {
    "Authorization": f"Bearer {TOKEN}",
    "Content-Type":  "application/json",
    "AI-Resource-Group": RG,
}

OUTPUT_DIR = Path("generated_images")
OUTPUT_DIR.mkdir(exist_ok=True)

# ── Size options ──────────────────────────────────────────────────────────────
SIZE_SQUARE    = "1024x1024"
SIZE_LANDSCAPE = "1792x1024"
SIZE_PORTRAIT  = "1024x1792"

# ── Core generation function ──────────────────────────────────────────────────
def generate_image(
    prompt: str,
    size: str = SIZE_SQUARE,
    quality: str = "standard",   # "standard" | "hd"
    style: str = "vivid",        # "vivid" | "natural"
    filename: str | None = None,
) -> Path | None:
    """
    Call DALL-E 3 via GenAI Hub and save the image to disk.
    Returns the saved file path, or None on content-policy error.
    """
    url = f"{BASE_URL}/inference/deployments/{IMG_DEPID}/images/generations"
    payload = {
        "prompt":  prompt,
        "model":   "dall-e-3",
        "n":       1,
        "size":    size,
        "quality": quality,
        "style":   style,
    }

    try:
        resp = requests.post(url, headers=HEADERS, json=payload, timeout=60)

        # Handle content policy violation gracefully
        if resp.status_code == 400:
            body = resp.json()
            error = body.get("error", {})
            if error.get("code") == "content_filter":
                print(f"  [BLOCKED] Content policy violation: {error.get('message', '')}")
                return None
            raise requests.HTTPError(f"400 Bad Request: {body}", response=resp)

        resp.raise_for_status()
        data = resp.json()

        image_url     = data["data"][0]["url"]
        revised_prompt = data["data"][0].get("revised_prompt", prompt)
        print(f"  Revised prompt: {revised_prompt[:100]}...")

        # Download and save the image
        ts = datetime.now().strftime("%Y%m%d_%H%M%S")
        fname = filename or f"image_{ts}.png"
        out_path = OUTPUT_DIR / fname

        urllib.request.urlretrieve(image_url, out_path)
        print(f"  Saved: {out_path} ({out_path.stat().st_size // 1024} KB)")
        return out_path

    except requests.HTTPError as e:
        print(f"  [ERROR] HTTP error: {e}")
        return None
    except Exception as e:
        print(f"  [ERROR] Unexpected error: {e}")
        return None

# ── SAP-specific prompts ──────────────────────────────────────────────────────
SAP_PROMPTS = [
    {
        "name":   "architecture_diagram",
        "prompt": (
            "A clean, professional enterprise architecture diagram showing SAP S/4HANA "
            "connected to SAP BTP, SAP Integration Suite, and external cloud services. "
            "Use a modern flat design style with blue and white colors, boxes and arrows, "
            "on a white background."
        ),
        "size":    SIZE_LANDSCAPE,
        "quality": "hd",
        "style":   "natural",
    },
    {
        "name":   "approval_workflow",
        "prompt": (
            "A clear flowchart diagram of a purchase order approval workflow in SAP. "
            "Shows steps: Submit Request → Manager Approval → Finance Review → "
            "Auto-Approve or Reject. Flat design, professional, teal and gray colors."
        ),
        "size":    SIZE_SQUARE,
        "quality": "standard",
        "style":   "natural",
    },
    {
        "name":   "org_chart",
        "prompt": (
            "A clean corporate organizational chart for an SAP Center of Excellence team. "
            "Hierarchy: CTO at top, then SAP Architect, then Functional Leads (FI, MM, SD), "
            "then Consultants. Modern flat design, white background, blue boxes."
        ),
        "size":    SIZE_PORTRAIT,
        "quality": "standard",
        "style":   "natural",
    },
    {
        "name":   "dashboard_mockup",
        "prompt": (
            "A modern SAP Analytics Cloud dashboard mockup showing KPI tiles for Revenue, "
            "Orders, and Customer Satisfaction, plus a bar chart and line chart. "
            "Clean UI design, light theme, SAP Fiori-inspired blue color scheme."
        ),
        "size":    SIZE_LANDSCAPE,
        "quality": "hd",
        "style":   "vivid",
    },
]

# ── Variation pattern ─────────────────────────────────────────────────────────
def generate_variation(base_prompt: str, variation_note: str, name: str) -> Path | None:
    """Generate a variation by appending a modifier to the base prompt."""
    varied_prompt = f"{base_prompt} {variation_note}"
    print(f"\n[Variation] {name}")
    print(f"  Modifier: {variation_note}")
    return generate_image(varied_prompt, size=SIZE_SQUARE, filename=f"{name}_variation.png")

# ── Main ──────────────────────────────────────────────────────────────────────
def main():
    print(f"Output directory: {OUTPUT_DIR.resolve()}")
    print(f"Size options: {SIZE_SQUARE}, {SIZE_LANDSCAPE}, {SIZE_PORTRAIT}\n")

    results = {}

    # Generate each SAP-themed image
    for item in SAP_PROMPTS:
        print(f"\n{'='*60}")
        print(f"Generating: {item['name']} ({item['size']}, {item['quality']})")
        path = generate_image(
            prompt=item["prompt"],
            size=item["size"],
            quality=item["quality"],
            style=item["style"],
            filename=f"{item['name']}.png",
        )
        results[item["name"]] = str(path) if path else "BLOCKED"

    # Demonstrate variation: take the dashboard and make a dark-mode version
    base = SAP_PROMPTS[3]["prompt"]  # dashboard mockup
    generate_variation(
        base_prompt=base,
        variation_note="Dark mode version with deep navy background and glowing accent colors.",
        name="dashboard_dark",
    )

    # Summary
    print(f"\n{'='*60}")
    print("Generation Summary:")
    for name, path in results.items():
        print(f"  {name}: {path}")

if __name__ == "__main__":
    main()
