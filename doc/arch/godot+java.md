# Architecture: Java Backend + Godot Frontend

## Core Architecture

A **WebSocket-based client-server architecture** with:
- **Godot Engine** as the frontend client (UI, graphics, input handling)
- **Java Spring Boot** as the backend server (game logic, state management)
- **FlatBuffers** for efficient binary serialization between components

## Data Flow

1. **Client (Godot)** sends player inputs/actions via WebSocket
2. **Server (Java)** processes game logic, updates state
3. **Server** sends state updates to client using FlatBuffers
4. **Client** renders updated game state without deserialization overhead

## Key Components

### Backend (Java)
- WebSocket server endpoint handling client connections
- Game state management and business logic
- FlatBuffers for zero-copy serialization

### Frontend (Godot)
- WebSocket client maintaining connection to server
- Binary data interpretation using FlatBuffers
- Rendering and user interface

## Technical Implementation

- **Local Development**: Both components run on localhost for rapid iteration
- **Communication**: Binary WebSockets for minimal overhead
- **Data Format**: FlatBuffers schema for type-safe, efficient data exchange
- **Optimization**: Zero-parsing access to message data on both ends

## Benefits

- Clean separation between presentation and game logic
- Leverages Java for complex backend processing
- Minimizes network overhead with binary protocols
- Provides foundation for potential multiplayer expansion
