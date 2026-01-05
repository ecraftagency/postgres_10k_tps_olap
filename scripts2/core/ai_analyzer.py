#!/usr/bin/env python3
"""
AI Analyzer Module - Gemini API integration for benchmark analysis
"""
import json
import os
import urllib.request
import urllib.error
from typing import Optional

GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"

AI_PROMPT = """You are an expert database infrastructure engineer. Analyze this benchmark report and provide:

1. **Executive Summary** - 2-3 sentences about overall system performance

2. **Score Card** (MUST include this section with exact format):

| Aspect | Score | Assessment |
|--------|-------|------------|
| **Performance** | X/10 | (Compare actual metrics vs expected) |
| **Stability** | X/10 | (How close is P99 to P50? Variance analysis) |
| **Efficiency** | X/10 | (Resource utilization, bottlenecks) |

3. **Detailed Analysis** - Key observations from benchmark and diagnostics

4. **Recommendations** - Prioritized list of improvements (if any)

IMPORTANT:
- Focus on actionable insights
- Compare against industry benchmarks when relevant
- Note any anomalies or concerns

Format your response as clean, well-structured Markdown.

---

BENCHMARK REPORT TO ANALYZE:

"""


def call_gemini(prompt: str, api_key: str) -> str:
    """
    Call Gemini API and return response text.

    Args:
        prompt: Full prompt including report data
        api_key: Gemini API key

    Returns:
        AI response text
    """
    request_body = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "temperature": 0.3,
            "maxOutputTokens": 8192,
        }
    }

    url = f"{GEMINI_API_URL}?key={api_key}"
    req = urllib.request.Request(
        url,
        data=json.dumps(request_body).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST"
    )

    try:
        with urllib.request.urlopen(req, timeout=120) as response:
            data = json.loads(response.read().decode("utf-8"))
            candidates = data.get("candidates", [])
            if candidates:
                parts = candidates[0].get("content", {}).get("parts", [])
                if parts:
                    return parts[0].get("text", "")
            return "No response from AI"
    except urllib.error.HTTPError as e:
        return f"API Error {e.code}: {e.read().decode('utf-8')}"
    except Exception as e:
        return f"Error: {str(e)}"


def analyze_report(report: str) -> Optional[str]:
    """
    Analyze benchmark report with AI.

    Args:
        report: Markdown report content

    Returns:
        AI analysis or None if API key not set
    """
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("\n[!] GEMINI_API_KEY not set - skipping AI analysis")
        print("    Set it with: export GEMINI_API_KEY=your_key")
        return None

    print("\nSending to AI for analysis...")
    return call_gemini(AI_PROMPT + report, api_key)


def print_scorecard(ai_response: str):
    """Print AI score card from response"""
    print("\n--- AI Score Card ---")
    in_table = False
    for line in ai_response.split("\n"):
        if "| Aspect |" in line or "| **Performance**" in line or "| **Stability**" in line or "| **Efficiency" in line:
            print(line)
            in_table = True
        elif in_table and line.startswith("|"):
            print(line)
        elif in_table and not line.startswith("|"):
            in_table = False
