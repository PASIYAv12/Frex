import time
import random

def get_signal():
    """
    Dummy strategy:
    Returns one of: BUY / SELL / HOLD with confidence.
    Replace with your real logic (pull from VPS/MT5 or calculations).
    """
    choice = random.choice(["BUY","SELL","HOLD"])
    conf = round(random.uniform(0.51, 0.89), 2)
    symbol = "EURUSD"
    return {"symbol": symbol, "signal": choice, "confidence": conf, "ts": int(time.time())}
