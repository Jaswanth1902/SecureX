from flask import Blueprint, Response, g, request, jsonify
from auth_utils import token_required
from sse_manager import sse_manager
import time

events_bp = Blueprint('events', __name__)

@events_bp.route('/stream', methods=['GET'])
@token_required
def stream():
    """
    SSE Endpoint for real-time notifications.
    Client connects here to receive updates.
    """
    owner_id = g.user['sub']
    
    def event_stream():
        q = sse_manager.listen(owner_id)
        try:
            # Send initial connection message
            yield "event: connected\ndata: {\"message\": \"Connected to notification stream\"}\n\n"
            
            while True:
                # Get message from queue (blocking with timeout)
                # Timeout allows loop to check if client is still alive or context changed
                try:
                    msg = q.get(timeout=20) 
                    yield msg
                except Exception:
                    # Timeout - just send a comment/keepalive or loop
                    yield ": keepalive\n\n"
        except GeneratorExit:
            # Client disconnected
            sse_manager.remove_listener(owner_id, q)
        except Exception as e:
            print(f"Stream error: {e}")
            sse_manager.remove_listener(owner_id, q)

    return Response(event_stream(), mimetype='text/event-stream')
