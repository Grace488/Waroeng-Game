#!/usr/bin/env python3
"""
Lightweight HTTP server to serve the exported Godot 4 Web build.
Includes proper MIME types for WASM and cross-origin isolation headers.
"""

import http.server
import socketserver
import os
import sys

PORT = 8000
DIRECTORY = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "build", "web"))

class GameHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        # Cross-Origin headers for optimal WebAssembly and shared buffers
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()

    def guess_type(self, path):
        if path.endswith(".wasm"):
            return "application/wasm"
        if path.endswith(".pck"):
            return "application/octet-stream"
        if path.endswith(".js"):
            return "application/javascript"
        return super().guess_type(path)

def run():
    if not os.path.isdir(DIRECTORY):
        print(f"Error: Directory '{DIRECTORY}' not found. Please export the project first.")
        sys.exit(1)

    port = PORT
    for attempt in range(10):
        try:
            with socketserver.TCPServer(("", port), GameHTTPRequestHandler) as httpd:
                print("=" * 60)
                print(f"  Waroeng Web Server Running!")
                print(f"  Local URL : http://localhost:{port}/")
                print(f"  Serving   : {DIRECTORY}")
                print("=" * 60)
                print("Press Ctrl+C to stop the server.\n")
                sys.stdout.flush()
                httpd.serve_forever()
        except OSError as e:
            if "Address already in use" in str(e) or e.errno == 10048:
                port += 1
            else:
                raise

if __name__ == "__main__":
    run()
