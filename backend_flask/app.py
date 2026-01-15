from flask import Flask, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
import os
import logging
from logging.handlers import RotatingFileHandler

import shutil

# Auto-create .env from example if missing
basedir = os.path.abspath(os.path.dirname(__file__))
env_path = os.path.join(basedir, '.env')
example_path = os.path.join(basedir, '.env.example')

if not os.path.exists(env_path):
    if os.path.exists(example_path):
        print(f"Creating .env from {example_path}...")
        shutil.copy(example_path, env_path)
    else:
        print("Warning: .env and .env.example not found. Creating empty .env")
        with open(env_path, 'w') as f:
            f.write("# Auto-generated .env\n")

# Load environment variables
load_dotenv(env_path)

# Import Blueprints
from routes.auth import auth_bp
from routes.owners import owners_bp
from routes.files import files_bp
from routes.events import events_bp
from routes.status import status_bp
from routes.feedback import feedback_bp

app = Flask(__name__)

@app.route("/")
def home():
    return "SecureX backend running"

# Fix Render / Flask proxy & upload connection issues
from werkzeug.middleware.proxy_fix import ProxyFix

app.wsgi_app = ProxyFix(
    app.wsgi_app,
    x_for=1,
    x_proto=1,
    x_host=1,
    x_port=1
)

app.config['MAX_CONTENT_LENGTH'] = 50 * 1024 * 1024  # 50MB

# CORS Configuration (Security Fix #3)
# Default to '*' for dev compatibility, but allow override via env var
cors_origins = os.getenv('CORS_ORIGINS', '*').split(',')
CORS(app, resources={r"/api/*": {"origins": cors_origins}})

# Logging Setup
if not os.path.exists('logs'):
    os.makedirs('logs')

log_formatter = logging.Formatter('%(asctime)s %(levelname)s [%(pathname)s:%(lineno)d] %(message)s')
log_file = 'logs/server_errors.log'

file_handler = RotatingFileHandler(log_file, maxBytes=10*1024*1024, backupCount=5)
file_handler.setFormatter(log_formatter)
file_handler.setLevel(logging.ERROR)

app.logger.addHandler(file_handler)
app.logger.setLevel(logging.ERROR)

# Error Handling
@app.errorhandler(400)
def bad_request(error):
    app.logger.error(f"Bad Request (400): {error}")
    return jsonify({
        "error": True,
        "statusCode": 400,
        "message": str(error.description if hasattr(error, 'description') else "Bad Request")
    }), 400

@app.errorhandler(401)
def unauthorized_error(error):
    app.logger.error(f"Unauthorized (401): {error}")
    return jsonify({
        "error": True,
        "statusCode": 401,
        "message": "Authentication required or invalid"
    }), 401

@app.errorhandler(404)
def not_found(error):
    app.logger.error(f"Not Found (404): {error}")
    return jsonify({
        "error": True,
        "statusCode": 404,
        "message": "Endpoint not found"
    }), 404

@app.errorhandler(500)
def internal_error(error):
    app.logger.error(f"Server Error: {error}", exc_info=True)
    return jsonify({
        "error": True,
        "statusCode": 500,
        "message": "Internal Server Error"
    }), 500

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        "status": "OK",
        "environment": os.getenv('NODE_ENV', 'development')
    })

# Register Blueprints
app.register_blueprint(auth_bp, url_prefix='/api/auth')
app.register_blueprint(owners_bp, url_prefix='/api/owners')
app.register_blueprint(files_bp, url_prefix='/api')
app.register_blueprint(events_bp, url_prefix='/api/events')
app.register_blueprint(status_bp, url_prefix='/api/status')
app.register_blueprint(feedback_bp, url_prefix='/api')

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='Run SecureX Backend')
    parser.add_argument('--host', type=str, default=os.getenv('HOST', '0.0.0.0'), help='Host to bind to')
    parser.add_argument('--port', type=int, default=int(os.getenv('PORT', 5000)), help='Port to bind to')
    args = parser.parse_args()

    print(f"Server starting on http://{args.host}:{args.port}")
    app.run(host=args.host, port=args.port, debug=False)


# Flask CLI: add `flask server` command so the server can be started with that exact command
import click
from flask import current_app
from flask.cli import run_command as _flask_run_command
import subprocess
import sys


@app.cli.command("server")
@click.option('--host', default=lambda: os.getenv('HOST', '0.0.0.0'), help='Host to bind to')
@click.option('--port', default=lambda: int(os.getenv('PORT', 5000)), help='Port to bind to')
@click.option('--debug/--no-debug', default=True, help='Run with debug output')
@click.pass_context
def server(ctx, host, port, debug):
    """Run the Flask development server (alias: `flask server`)."""
    # Use the existing `flask run` command logic so behavior matches the built-in CLI command and
    # we avoid conflicting or ignored calls to `app.run()` while using the `flask` CLI.
    # Fallback: call the system's Python executable to run the Flask CLI `run` action
    # in a subprocess so we don't run into CLI context conflicts.
    python_exe = sys.executable
    cmd = [python_exe, '-m', 'flask', 'run', '--host', host, '--port', str(port)]
    if debug:
        cmd.append('--debug')
    subprocess.check_call(cmd)
