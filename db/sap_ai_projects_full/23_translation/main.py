"""
Project: SAP AI Core Python Examples
Topic:   23_translation
Goal:    Translate 5 SAP UI strings to 5 languages. Also detect language of 3 incoming messages.
"""

import requests, json
from config import HEADERS, URL, UI_STRINGS, LANGUAGES, INCOMING_MESSAGES

def translate_batch(strings, target_lang):
    prompt = (
        f"Translate the following SAP UI strings to {target_lang}. "
        "Return a JSON array of translated strings in the same order.\n\n"
        + json.dumps(strings)
    )
    r = requests.post(URL, headers=HEADERS, json={
        "model": "gpt-4o",
        "messages": [{"role": "user", "content": prompt}],
        "response_format": {"type": "json_object"},
        "max_tokens": 200,
    }, timeout=30)
    r.raise_for_status()
    raw = r.json()["choices"][0]["message"]["content"]
    data = json.loads(raw)
    return list(data.values())[0] if isinstance(data, dict) else data

def detect_language(text):
    r = requests.post(URL, headers=HEADERS, json={
        "model": "gpt-4o",
        "messages": [
            {"role": "system", "content": "Detect the language. Reply with only the language name in English."},
            {"role": "user", "content": text},
        ],
        "max_tokens": 10,
    }, timeout=30)
    r.raise_for_status()
    return r.json()["choices"][0]["message"]["content"].strip()

if __name__ == "__main__":
    print("SAP UI String Translations")
    print(f"{'String':<35}", end="")
    for lang in LANGUAGES:
        print(f"  {lang[:8]:<12}", end="")
    print()
    print("-" * 100)

    translations = {lang: translate_batch(UI_STRINGS, lang) for lang in LANGUAGES}
    for i, string in enumerate(UI_STRINGS):
        print(f"{string:<35}", end="")
        for lang in LANGUAGES:
            t = translations[lang]
            val = t[i] if isinstance(t, list) and i < len(t) else "?"
            print(f"  {val[:12]:<12}", end="")
        print()

    print("\n\nLanguage Detection")
    print("-" * 60)
    for msg in INCOMING_MESSAGES:
        lang = detect_language(msg)
        print(f"{lang:<12}  {msg[:55]}")
