import os

TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN", "")
TELEGRAM_CHAT_ID = os.getenv("TELEGRAM_CHAT_ID", "")
REMOTE_BOT_API = os.getenv("REMOTE_BOT_API", "")  # e.g. http://<your-vps>:8000
ADMIN_IDS = {x.strip() for x in os.getenv("ADMIN_IDS", "").split(",") if x.strip()}
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")
