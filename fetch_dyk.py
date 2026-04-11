import urllib.request
import json
import ssl
import time
import os

ssl._create_default_https_context = ssl._create_unverified_context
URL = "https://query.wikidata.org/sparql"

# لیستێکی فراوانتر بۆ دڵنیابوون لە گەیشتن بە ١٨٢٥
queries = [
    ("Software & Tech", "wd:Q21390"),
    ("Chemical Elements", "wd:Q11344"),
    ("Food & Drinks", "wd:Q2095"),
    ("Movies", "wd:Q11424"),
    ("Musical Instruments", "wd:Q34371"),
    ("Diseases", "wd:Q12136"),
    ("Plants", "wd:Q756")
]

def fetch_category_data(q_id):
    query = f"""
    SELECT DISTINCT ?itemLabel ?description WHERE {{
      ?item wdt:P31/wdt:P279* {q_id} .
      ?item schema:description ?description .
      FILTER(LANG(?description) = "en")
      SERVICE wikibase:label {{ bd:serviceParam wikibase:language "en". }}
    }}
    LIMIT 1000
    """
    url = URL + "?format=json&query=" + urllib.request.quote(query)
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            return json.loads(response.read().decode())
    except:
        return None

# 1. بارکردنی داتاکانی پێشوو ئەگەر هەبن
final_results = []
seen_labels = set()

if os.path.exists("facts_data.json"):
    with open("facts_data.json", "r", encoding="utf-8") as f:
        final_results = json.load(f)
        for item in final_results:
            # وەرگرتنی ناوی فاکتەکە بۆ ئەوەی دووبارە نەبێتەوە
            name_part = item["content"].replace("Did you know? ", "").split(" is ")[0]
            seen_labels.add(name_part.lower())
    print(f"📂 Loaded {len(final_results)} existing facts. Looking for more...")

# 2. هێنانی داتای نوێ
for name, q_id in queries:
    if len(final_results) >= 1825:
        break
    
    data = fetch_category_data(q_id)
    if not data: continue
    
    added_in_session = 0
    for item in data["results"]["bindings"]:
        label = item["itemLabel"]["value"]
        desc = item["description"]["value"]
        
        if label.lower() in seen_labels or len(desc) < 15 or label.startswith("Q"):
            continue
            
        seen_labels.add(label.lower())
        
        final_results.append({
            "id": len(final_results) + 1,
            "content": f"Did you know? {label} is {desc}.",
            "category": "General Knowledge",
            "icon": "lightbulb"
        })
        added_in_session += 1
        if len(final_results) >= 1825: break
    
    print(f"➕ Added {added_in_session} new facts from {name}.")
    time.sleep(1)

# 3. پاشەکەوتکردنی هەمووی بەیەکەوە
with open("facts_data.json", "w", encoding="utf-8") as f:
    json.dump(final_results, f, ensure_ascii=False, indent=2)

print(f"\n✅ Total facts now: {len(final_results)}")