# Real-Time Notifications (SSE) Implementation

## Overview
Implemented Server-Sent Events (SSE) to provide instant notifications to the desktop client when new files are uploaded, replacing the need for manual refreshing.

## Backend Changes (Flask)

### 1. New Components
- **`sse_manager.py`**: Created a singleton `SSEManager` class.
  - Manages in-memory message queues for connected clients.
  - Handles publishing events to specific owners.
- **`routes/events.py`**: Created a new Blueprint for SSE.
  - Endpoint: `GET /api/events/stream`
  - Streams data using `text/event-stream` MIME type.

### 2. Integration
- **`app.py`**: Registered the `events_bp` blueprint.
- **`routes/files.py`**: Updated `upload_file` function.
  - Now publishes a `new_file` event via `sse_manager` immediately after a successful database commit.

## Desktop Changes (Flutter)

### 1. New Service
- **`services/notification_service.dart`**: Created `NotificationService`.
  - Manages persistent HTTP connection to the SSE endpoint.
  - Parses incoming event streams.
  - Exposes a Dart Stream for UI components to listen to.
- **`main.dart`**: Registered `NotificationService` in the provider list.

### 2. UI Integration
- **`screens/dashboard_screen.dart`**:
  - Subscribes to `NotificationService` on initialization.
  - Listens for `new_file` events.
  - **Behavior**: Shows a SnackBar ("New file received") and automatically refreshes the file list.
  - **Cleanup**: Disposes the service connection on logout.

## Verification
- Created `test_sse_realtime.py` to verify the flow.
- **Result**: Confirmed that uploading a file via Python script triggers an immediate event reception in a separate listener thread.
