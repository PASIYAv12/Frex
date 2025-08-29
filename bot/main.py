import os
import time
import json
import logging
import threading
from datetime import datetime
import requests
import pytz
import redis

from telegram import Bot
from telegram.constants import ParseMode

from .config import TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID, REMOTE_BOT_API, ADMIN_IDS, REDIS_URL
from .strategy import get_signal

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("exness-heroku-worker")

bot = Bot(token=TELEGRAM_BOT_TOKEN)
rdb = redis.from_url(REDIS_URL)

TZ = pytz.timezone("Asia/Colombo")

def send(msg: str):
    if TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID:
        bot.send_message(chat_id=TELEGRAM_CHAT_ID, text=msg, parse_mode=ParseMode.MARKDOWN)
    else:
        log.warning("Telegram not configured; message: %s", msg)

def push_to_vps(payload: dict):
    if not REMOTE_BOT_API:
        return {"ok": False, "error": "REMOTE_BOT_API not set"}
    try:
        resp = requests.post(f"{REMOTE_BOT_API}/signal", json=payload, timeout=10)
        return {"ok": resp.ok, "status": resp.status_code, "body": resp.text}
    except Exception as e:
        return {"ok": False, "error": str(e)}

def heartbeat_loop():
    while True:
        now = datetime.now(TZ).strftime("%Y-%m-%d %H:%M:%S")
        rdb.set("exness-bot:last_heartbeat", now)
        time.sleep(60)

def signal_loop():
    while True:
        sig = get_signal()  # Replace with real pull from VPS/MT5 if you want read-only here
        pretty = f"📊 *{sig['symbol']}* | Signal: *{sig['signal']}* | Confidence: *{sig['confidence']}*\n⏱ {datetime.now(TZ).strftime('%Y-%m-%d %H:%M:%S')}"
        send(pretty)

        # Optionally forward to VPS bot to execute
        res = push_to_vps(sig)
        if not res.get("ok"):
            log.warning("VPS push failed: %s", res)
        else:
            log.info("VPS push ok: %s", res)

        time.sleep(240)  # every 4 minutes

def main():
    if not TELEGRAM_BOT_TOKEN or not TELEGRAM_CHAT_ID:
        log.warning("Set TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID env vars!")

    send("✅ Heroku worker started. Controller online.")
    threading.Thread(target=heartbeat_loop, daemon=True).start()
    threading.Thread(target=signal_loop, daemon=True).start()

    # Keep alive
    while True:
        time.sleep(3600)

if __name__ == "__main__":
    main()
