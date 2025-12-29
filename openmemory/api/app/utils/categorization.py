import json
import logging
import os
from typing import List

from app.config import ENABLE_CATEGORIZATION
from app.utils.prompts import MEMORY_CATEGORIZATION_PROMPT
from dotenv import load_dotenv
from pydantic import BaseModel
from tenacity import retry, stop_after_attempt, wait_exponential

load_dotenv()

class MemoryCategories(BaseModel):
    categories: List[str]


@retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=4, max=15))
def get_categories_for_memory(memory: str) -> List[str]:
    # Check if categorization is enabled
    if not ENABLE_CATEGORIZATION:
        return []

    categorization_provider = os.getenv("CATEGORIZATION_PROVIDER", "openai").lower()

    if categorization_provider == "ollama":
        return _get_categories_ollama(memory)
    elif categorization_provider == "zai":
        return _get_categories_zai(memory)
    else:
        return _get_categories_openai(memory)


def _get_categories_openai(memory: str) -> List[str]:
    """Get categories using OpenAI's structured output."""
    from openai import OpenAI

    openai_client = OpenAI()

    try:
        messages = [
            {"role": "system", "content": MEMORY_CATEGORIZATION_PROMPT},
            {"role": "user", "content": memory}
        ]

        # Let OpenAI handle the pydantic parsing directly
        completion = openai_client.beta.chat.completions.parse(
            model="gpt-4o-mini",
            messages=messages,
            response_format=MemoryCategories,
            temperature=0
        )

        parsed: MemoryCategories = completion.choices[0].message.parsed
        return [cat.strip().lower() for cat in parsed.categories]

    except Exception as e:
        logging.error(f"[ERROR] Failed to get categories from OpenAI: {e}")
        try:
            logging.debug(f"[DEBUG] Raw response: {completion.choices[0].message.content}")
        except Exception as debug_e:
            logging.debug(f"[DEBUG] Could not extract raw response: {debug_e}")
        raise


def _get_categories_zai(memory: str) -> List[str]:
    """Get categories using Z.AI (Zhipu AI) with structured JSON output."""
    from openai import OpenAI

    # Z.AI uses OpenAI-compatible API
    zai_client = OpenAI(
        api_key=os.getenv("ZAI_API_KEY"),
        base_url="https://api.z.ai/api/coding/paas/v4"
    )

    try:
        # Enhanced system message with JSON schema
        system_message = f"""{MEMORY_CATEGORIZATION_PROMPT}

You MUST respond with valid JSON in this exact format:
{{"categories": ["category1", "category2"]}}"""

        messages = [
            {"role": "system", "content": system_message},
            {"role": "user", "content": memory}
        ]

        completion = zai_client.chat.completions.create(
            model=os.getenv("CATEGORIZATION_MODEL", "glm-4.7"),
            messages=messages,
            response_format={"type": "json_object"},
            temperature=0
        )

        content = completion.choices[0].message.content
        logging.debug(f"[DEBUG] Z.AI raw response: {content}")

        # Parse JSON response
        parsed_json = json.loads(content)
        categories = parsed_json.get("categories", [])

        # Ensure it's a list and clean up
        if isinstance(categories, list):
            return [cat.strip().lower() for cat in categories if isinstance(cat, str)]
        else:
            logging.warning(f"[WARNING] Unexpected categories format: {categories}")
            return []

    except json.JSONDecodeError as e:
        logging.error(f"[ERROR] Failed to parse JSON from Z.AI: {e}")
        logging.debug(f"[DEBUG] Raw content: {content}")
        return []
    except Exception as e:
        logging.error(f"[ERROR] Failed to get categories from Z.AI: {e}")
        raise


def _get_categories_ollama(memory: str) -> List[str]:
    """Get categories using Ollama with JSON mode."""
    import ollama

    try:
        # Enhanced prompt for JSON output
        enhanced_prompt = f"""{MEMORY_CATEGORIZATION_PROMPT}

You MUST respond with valid JSON in this exact format:
{{"categories": ["category1", "category2"]}}

Memory to categorize: {memory}"""

        response = ollama.chat(
            model=os.getenv("CATEGORIZATION_MODEL", "phi3:mini"),
            messages=[
                {"role": "system", "content": "You are a categorization assistant. Always respond with valid JSON."},
                {"role": "user", "content": enhanced_prompt}
            ],
            format="json",
            options={
                "temperature": 0.1,
            }
        )

        content = response['message']['content']
        logging.debug(f"[DEBUG] Ollama raw response: {content}")

        # Parse JSON response
        parsed_json = json.loads(content)
        categories = parsed_json.get("categories", [])

        # Ensure it's a list and clean up
        if isinstance(categories, list):
            return [cat.strip().lower() for cat in categories if isinstance(cat, str)]
        else:
            logging.warning(f"[WARNING] Unexpected categories format: {categories}")
            return []

    except json.JSONDecodeError as e:
        logging.error(f"[ERROR] Failed to parse JSON from Ollama: {e}")
        logging.debug(f"[DEBUG] Raw content: {content}")
        return []
    except Exception as e:
        logging.error(f"[ERROR] Failed to get categories from Ollama: {e}")
        return []
