from flask import Flask, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

# Import Blueprints
from routes.auth import auth_bp
from routes.owners import owners_bp
from routes.files import files_bp
from routes.events import events_bp

app = Flask(__name__)

# CORS Configuration
CORS(app, resources={r"/api/*": {"origins": "*"}})

# Error Handling
@app.errorhandler(404)
def not_found(error):
    return jsonify({
        "error": True,
        "statusCode": 404,
        "message": "Endpoint not found"
    }), 404

@app.errorhandler(500)
def internal_error(error):
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

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    print(f"Server running on http://0.0.0.0:{port}")
    app.run(host='0.0.0.0', port=port, debug=True)


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
