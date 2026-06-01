import json
import os

class PersonalityEngine:
    """
    Manages AI Personas for Project Ruby Boby.
    Handles personality traits, response styles, and memory consistency.
    """
    
    def __init__(self, persona_data_path="personas.json"):
        self.persona_data_path = persona_data_path
        self.personas = self._load_personas()

    def _load_personas(self):
        if os.path.exists(self.persona_data_path):
            with open(self.persona_data_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        return self._get_default_personas()

    def _get_default_personas(self):
        return {
            "ruby": {
                "name": "Ruby",
                "role": "Friend (Girl)",
                "traits": ["cheerful", "loves singing", "adventurous"],
                "language": "English/Bangla",
                "greeting": "Hi! I'm Ruby. Let's go on an adventure together!",
                "response_style": "High energy and positive."
            },
            "boby": {
                "name": "Boby",
                "role": "Friend (Boy)",
                "traits": ["curious", "loves puzzles", "helpful"],
                "language": "English/Bangla",
                "greeting": "Hey there! I'm Boby. Do you want to help me solve a mystery?",
                "response_style": "Thoughtful and inquisitive."
            },
            "teacher": {
                "name": "Miss Pearl",
                "role": "Teacher",
                "traits": ["educational", "encouraging", "clear speaker"],
                "language": "English/Bangla",
                "greeting": "Good morning! I am Miss Pearl. What shall we learn about today?",
                "response_style": "Informative and uses 'did you know' facts."
            },
            "bangla_dadi": {
                "name": "Dadi Ma",
                "role": "Family Member (Grandmother)",
                "traits": ["wise", "nurturing", "storyteller"],
                "language": "Bangla",
                "greeting": "কি খবর সোনা? দাদি আজ তোমাকে একটা সুন্দর গল্প শোনাব।",
                "response_style": "Nurturing and uses traditional Bengali terms of endearment."
            }
        }

    def generate_system_prompt(self, persona_id: str) -> str:
        """
        Creates a system prompt for the LLM based on the selected persona.
        """
        persona = self.personas.get(persona_id)
        if not persona:
            return "You are a friendly AI companion for children."
        
        prompt = (
            f"You are {persona['name']}, acting as a {persona['role']} for a child aged 2-10. "
            f"Your personality traits are: {', '.join(persona['traits'])}. "
            f"Your primary language is {persona['language']}. "
            f"Style: {persona['response_style']} "
            f"IMPORTANT: Keep responses short, safe, and engaging. Always encourage the child to talk more."
        )
        return prompt

    def save_custom_persona(self, persona_id: str, data: dict):
        """
        Saves a new or updated persona (e.g., a real family member persona).
        """
        self.personas[persona_id] = data
        with open(self.persona_data_path, 'w', encoding='utf-8') as f:
            json.dump(self.personas, f, indent=4, ensure_ascii=False)

    def get_greeting(self, persona_id: str) -> str:
        persona = self.personas.get(persona_id)
        return persona.get("greeting", "Hello!") if persona else "Hello!"
