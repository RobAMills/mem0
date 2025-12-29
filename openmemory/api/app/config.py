import os

USER_ID = os.getenv("USER", "default_user")
DEFAULT_APP_ID = "openmemory"
ENABLE_CATEGORIZATION = os.getenv("ENABLE_CATEGORIZATION", "false").lower() == "true"