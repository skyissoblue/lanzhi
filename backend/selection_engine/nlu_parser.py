"""Parse natural-language stock-selection instructions with OpenAI."""

from __future__ import annotations

import os
from typing import Any, Literal

from openai import OpenAI
from pydantic import BaseModel

from .prompts import build_system_prompt


class ParsedCondition(BaseModel):
    action: Literal["add", "remove_last", "reset", "error"]
    condition: dict[str, Any] | None = None
    message: str | None = None


def parse_condition(
    text: str,
    context_conditions: list | None = None,
) -> dict:
    if not isinstance(text, str) or not text.strip():
        return {"action": "error", "message": "text must not be empty"}

    try:
        client = OpenAI()
        response = client.responses.parse(
            model=os.getenv("OPENAI_MODEL", "gpt-4.1-mini"),
            input=[
                {
                    "role": "system",
                    "content": build_system_prompt(context_conditions),
                },
                {"role": "user", "content": text.strip()},
            ],
            text_format=ParsedCondition,
        )
        parsed = response.output_parsed
        if parsed is None:
            return {"action": "error", "message": "model returned no parsed output"}
        if isinstance(parsed, BaseModel):
            result = parsed.model_dump(exclude_none=True)
        elif isinstance(parsed, dict):
            result = parsed
        else:
            raise TypeError("unexpected OpenAI response type")
        return result
    except Exception as error:
        return {"action": "error", "message": str(error)}
