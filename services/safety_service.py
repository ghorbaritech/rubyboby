import os

class SafetyService:
    """
    Ruby Boby Safety Service
    Responsible for filtering input/output to ensure age-appropriate content.
    """
    
    # Simple dictionary for immediate blocking
    FORBIDDEN_TOPICS = [
        "violence", "grooming", "self-harm", "horror", 
        "sexual content", "hate speech", "adult topics"
    ]
    
    @staticmethod
    def is_safe(text: str) -> bool:
        """
        Performs a basic check against forbidden keywords.
        In a production environment, this would call LlamaGuard or OpenAI Moderation API.
        """
        normalized_text = text.lower()
        for topic in SafetyService.FORBIDDEN_TOPICS:
            if topic in normalized_text:
                return False
        return True

    @staticmethod
    def filter_output(response: str) -> str:
        """
        Ensures the AI output remains friendly and safe for children.
        """
        if not SafetyService.is_safe(response):
            return "Oops! I shouldn't talk about that. Let's talk about something fun like space or animals!"
        return response

    @staticmethod
    def log_safety_violation(child_id: str, input_text: str):
        """
        Logs violations for parental review.
        """
        # Placeholder for database logging
        print(f"SAFETY ALERT: Child {child_id} entered potentially unsafe text: {input_text}")
