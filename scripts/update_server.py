import argparse
import base64
import json
import os
import sys
import threading
import time
from http.server import HTTPServer, BaseHTTPRequestHandler
from cryptography.hazmat.primitives.asymmetric import ed25519
from cryptography.hazmat.primitives import serialization

KEY_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "tmp")
PRIVATE_KEY_PATH = os.path.join(KEY_DIR, "update_signing_key.pem")
PUBLIC_KEY_PATH = os.path.join(KEY_DIR, "update_public_key.b64")

def ensure_key_dir():
    os.makedirs(KEY_DIR, exist_ok=True)

def generate_keypair():
    ensure_key_dir()
    private_key = ed25519.Ed25519PrivateKey.generate()
    public_key = private_key.public_key()

    priv_bytes = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption()
    )
    with open(PRIVATE_KEY_PATH, "wb") as f:
        f.write(priv_bytes)

    pub_raw = public_key.public_bytes_raw()
    pub_b64 = base64.b64encode(pub_raw).decode("utf-8")
    with open(PUBLIC_KEY_PATH, "w") as f:
        f.write(pub_b64)

    return PRIVATE_KEY_PATH, pub_b64

def load_private_key():
    if not os.path.exists(PRIVATE_KEY_PATH):
        generate_keypair()
    with open(PRIVATE_KEY_PATH, "rb") as f:
        return serialization.load_pem_private_key(f.read(), password=None)

def sign_payload(payload_dict):
    private_key = load_private_key()
    canonical_bytes = json.dumps(payload_dict, sort_keys=True, separators=(",", ":")).encode("utf-8")
    signature = private_key.sign(canonical_bytes)
    return {
        "payload": payload_dict,
        "signature": base64.b64encode(signature).decode("utf-8")
    }

class UpdateRequestHandler(BaseHTTPRequestHandler):
    mode = "optional"

    def do_GET(self):
        if self.path in ("/version.json", "/"):
            self.serve_version()
        elif self.path == "/up-to-date":
            self.serve_up_to_date()
        elif self.path == "/force-update":
            self.serve_force_update()
        elif self.path == "/health":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(b'{"status":"ok"}')
        else:
            self.send_response(404)
            self.end_headers()

    def serve_version(self):
        if UpdateRequestHandler.mode == "forced":
            self.serve_force_update()
        elif UpdateRequestHandler.mode == "uptodate":
            self.serve_up_to_date()
        else:
            payload = {
                "latest_version": "1.1.0",
                "min_supported_version": "1.0.0",
                "release_notes": "Added advanced stroke practice and pinyin tone exercises.",
                "app_store_url": "https://apps.apple.com/app/id6738321000",
                "force_update": False,
                "timestamp": int(time.time())
            }
            self.send_signed_json(payload)

    def serve_force_update(self):
        payload = {
            "latest_version": "2.0.0",
            "min_supported_version": "2.0.0",
            "release_notes": "Mandatory security and architecture update. Please update on App Store.",
            "app_store_url": "https://apps.apple.com/app/id6738321000",
            "force_update": True,
            "timestamp": int(time.time())
        }
        self.send_signed_json(payload)

    def serve_up_to_date(self):
        payload = {
            "latest_version": "1.0.0",
            "min_supported_version": "1.0.0",
            "release_notes": "",
            "app_store_url": "https://apps.apple.com/app/id6738321000",
            "force_update": False,
            "timestamp": int(time.time())
        }
        self.send_signed_json(payload)

    def send_signed_json(self, payload):
        signed_data = sign_payload(payload)
        body = json.dumps(signed_data, indent=2).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format, *args):
        pass

def start_server(port=8000, mode="optional"):
    UpdateRequestHandler.mode = mode
    server = HTTPServer(("127.0.0.1", port), UpdateRequestHandler)
    print(f"Update server listening on http://127.0.0.1:{port} (mode: {mode})")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()

def main():
    parser = argparse.ArgumentParser(description="Local Version Check Server and Key Manager")
    subparsers = parser.add_subparsers(dest="command")

    gen_parser = subparsers.add_parser("generate-keys", help="Generate Ed25519 signing keypair")

    sign_parser = subparsers.add_parser("sign", help="Sign a JSON payload")
    sign_parser.add_argument("--version", default="1.1.0", help="Latest version string")
    sign_parser.add_argument("--min-version", default="1.0.0", help="Minimum supported version")
    sign_parser.add_argument("--force", action="store_true", help="Force update flag")
    sign_parser.add_argument("--notes", default="Bug fixes and performance improvements", help="Release notes")
    sign_parser.add_argument("--url", default="https://apps.apple.com/app/id6738321000", help="App Store URL")

    serve_parser = subparsers.add_parser("serve", help="Launch local HTTP update server")
    serve_parser.add_argument("--port", type=int, default=8000, help="Port to listen on")
    serve_parser.add_argument("--mode", choices=["optional", "forced", "uptodate"], default="optional")

    args = parser.parse_args()

    if args.command == "generate-keys":
        priv_path, pub_b64 = generate_keypair()
        print(f"Private Key: {priv_path}")
        print(f"Public Key (Base64): {pub_b64}")
    elif args.command == "sign":
        payload = {
            "latest_version": args.version,
            "min_supported_version": args.min_version,
            "release_notes": args.notes,
            "app_store_url": args.url,
            "force_update": args.force,
            "timestamp": int(time.time())
        }
        signed = sign_payload(payload)
        print(json.dumps(signed, indent=2))
    elif args.command == "serve":
        start_server(port=args.port, mode=args.mode)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
