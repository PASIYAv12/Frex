from flask import Flask, request, jsonify
import os, requests

app = Flask(__name__)

# VPS API endpoint (set in Heroku ENV vars)
VPS_API = os.getenv("VPS_API", "http://your-vps-ip:8000/signal")
TOKEN = os.getenv("SECRET_TOKEN", "12345")

@app.route("/trade", methods=["POST"])
def trade():
    data = request.json
    if data.get("token") != TOKEN:
        return jsonify({"ok": False, "error": "Unauthorized"}), 403

    try:
        res = requests.post(VPS_API, json=data).json()
        return jsonify({"ok": True, "vps_response": res})
    except Exception as e:
        return jsonify({"ok": False, "error": str(e)})

@app.route("/")
def home():
    return {"status": "Heroku Controller Running"}

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
