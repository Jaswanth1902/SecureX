import sqlite3
from flask import Blueprint, request, jsonify, g
from auth_utils import token_required

feedback_bp = Blueprint('feedback', __name__)

@feedback_bp.route('/feedback', methods=['POST'])
@token_required
def submit_feedback():
    print(f"DEBUG: Feedback submission attempt by {g.user}")
    try:
        data = request.get_json(force=True)
        message = data.get("message")
        rating = data.get("rating")

        if not message:
            return jsonify({"error": True, "message": "Message required"}), 400

        user_id = g.user.get("sub")
        if not user_id:
             print("DEBUG: Missing 'sub' in g.user")
             return jsonify({"error": True, "message": "Invalid token: missing sub"}), 401

        # Use absolute path from db module
        from db import DB_PATH
        print(f"DEBUG: Connecting to DB at {DB_PATH}")
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()

        cursor.execute(
            """
            INSERT INTO feedback (user_id, message, rating)
            VALUES (?, ?, ?)
            """,
            (user_id, message, rating)
        )

        conn.commit()
        conn.close()
        print(f"DEBUG: Feedback saved for user {user_id}")

        return jsonify({"success": True}), 200

    except Exception as e:
        import traceback
        tb = traceback.format_exc()
        print("FEEDBACK API ERROR:", e)
        print(tb)
        return jsonify({
            "error": True,
            "message": f"Internal server error: {str(e)}"
        }), 500
