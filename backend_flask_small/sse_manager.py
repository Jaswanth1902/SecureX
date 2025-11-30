import queue
import json
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class SSEManager:
    def __init__(self):
        # Dictionary to store listeners: owner_id -> list of queues
        self.listeners = {}

    def listen(self, owner_id):
        """Register a new listener for an owner"""
        q = queue.Queue()
        if owner_id not in self.listeners:
            self.listeners[owner_id] = []
        self.listeners[owner_id].append(q)
        logger.info(f"New listener registered for owner {owner_id}. Total listeners: {len(self.listeners[owner_id])}")
        return q

    def publish(self, owner_id, event_type, data):
        """Publish an event to all listeners of an owner"""
        if owner_id in self.listeners:
            # Format as Server-Sent Event
            msg = f"event: {event_type}\ndata: {json.dumps(data)}\n\n"
            
            dead_queues = []
            count = 0
            for q in self.listeners[owner_id]:
                try:
                    q.put(msg)
                    count += 1
                except Exception as e:
                    logger.error(f"Error publishing to queue: {e}")
                    dead_queues.append(q)
            
            # Cleanup dead queues
            for q in dead_queues:
                if q in self.listeners[owner_id]:
                    self.listeners[owner_id].remove(q)
            
            logger.info(f"Published '{event_type}' to {count} listeners for owner {owner_id}")
        else:
            logger.info(f"No listeners found for owner {owner_id}")

    def remove_listener(self, owner_id, q):
        """Remove a specific listener queue"""
        if owner_id in self.listeners and q in self.listeners[owner_id]:
            self.listeners[owner_id].remove(q)
            logger.info(f"Listener removed for owner {owner_id}")

# Global instance
sse_manager = SSEManager()
