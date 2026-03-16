#!/usr/bin/env python3
import subprocess
import json
from http.server import HTTPServer, BaseHTTPRequestHandler

class UpdateHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path == "/update":
            result = subprocess.run(
                ["sudo", "-u", "rstudio", "git", "-C", "/home/rstudio/MP26", "pull"],
                capture_output=True, text=True
            )
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(json.dumps({
                "success": result.returncode == 0,
                "output": result.stdout or result.stderr
            }).encode())
        else:
            self.send_response(404)
            self.end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")
        self.end_headers()

    def log_message(self, format, *args):
        pass

if __name__ == "__main__":
    server = HTTPServer(("localhost", 9000), UpdateHandler)
    server.serve_forever()