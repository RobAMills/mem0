# OpenMemory Architecture

## Overview

OpenMemory is a personal memory layer for LLMs that provides private, portable, and open-source memory management. The system uses a dual-storage architecture combining vector embeddings (Qdrant) for semantic search with relational metadata (SQLite) for structured queries and access control.

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Client Layer                              │
│  ┌──────────────────┐              ┌──────────────────┐         │
│  │   Next.js UI     │              │   MCP Clients    │         │
│  │   (Port 3000)    │              │ (Claude, etc.)   │         │
│  └──────────────────┘              └──────────────────┘         │
└─────────────────────────────────────────────────────────────────┘
                    │                           │
                    │ HTTP REST                 │ SSE/MCP Protocol
                    ▼                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                    API Layer - FastAPI (Port 8765)              │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  API Routers                    MCP Server               │  │
│  │  • /api/v1/memories            • SSE Transport           │  │
│  │  • /api/v1/apps                • add_memories()          │  │
│  │  • /api/v1/config              • search_memories()       │  │
│  │  • /api/v1/stats               • list_memories()         │  │
│  │  • /api/v1/backup                                        │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Business Logic Layer                          │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Memory Client (Mem0 SDK)                    │  │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────────┐    │  │
│  │  │    LLM     │  │  Embedder  │  │  Categorizer   │    │  │
│  │  │ (Ollama/   │  │(HuggingFace│  │   (Optional)   │    │  │
│  │  │  OpenAI/   │  │  /OpenAI/  │  │                │    │  │
│  │  │   Z.AI)    │  │  Ollama)   │  │                │    │  │
│  │  └────────────┘  └────────────┘  └────────────────┘    │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Data Layer                                │
│  ┌──────────────────────┐        ┌──────────────────────┐      │
│  │   SQLite Database    │        │   Vector Store       │      │
│  │   (openmemory.db)    │        │   (Qdrant:6333)      │      │
│  │                      │        │                      │      │
│  │  • users             │        │  • Embeddings (384d) │      │
│  │  • apps              │        │  • Payload:          │      │
│  │  • memories          │        │    - data            │      │
│  │  • categories        │        │    - user_id         │      │
│  │  • memory_acl        │        │    - hash            │      │
│  │  • access_logs       │        │    - timestamps      │      │
│  │  • status_history    │        │    - metadata        │      │
│  │  • config            │        │                      │      │
│  └──────────────────────┘        └──────────────────────┘      │
└─────────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. Client Layer

#### Next.js UI (Port 3000)
- React-based web interface
- Redux state management
- Real-time memory browsing and management
- Configuration interface for LLM/embedder settings
- Category-based filtering and search

#### MCP Clients
- Model Context Protocol integration
- Claude Desktop, Cursor, Windsurf support
- SSE (Server-Sent Events) transport
- Context-aware memory operations

### 2. API Layer (FastAPI - Port 8765)

#### REST API Routers
- **Memories Router** (`/api/v1/memories`): CRUD operations, search, filtering
- **Apps Router** (`/api/v1/apps`): Application management, access control
- **Config Router** (`/api/v1/config`): LLM/embedder/vector store configuration
- **Stats Router** (`/api/v1/stats`): Usage analytics and metrics
- **Backup Router** (`/api/v1/backup`): Export/import functionality

#### MCP Server
- Implements Model Context Protocol
- Tools: `add_memories`, `search_memories`, `list_memories`
- Context variables: `user_id`, `client_name`
- Graceful degradation when dependencies unavailable

### 3. Business Logic Layer

#### Memory Client (Mem0 SDK)
Orchestrates memory operations through three key components:

**LLM (Language Model)**
- Extracts facts from raw text
- Deduplicates similar memories
- Updates existing memories with new information
- Supported providers: OpenAI, Ollama, Z.AI (via LiteLLM)

**Embedder**
- Converts text to vector embeddings
- Default: HuggingFace `sentence-transformers/all-MiniLM-L6-v2` (384 dimensions)
- Alternatives: OpenAI embeddings (1536 dims), Z.AI embeddings (1024-2048 dims), Ollama embeddings (768-1024 dims)
- Used for semantic similarity search

**Categorizer (Optional)**
- Automatically categorizes memories
- Providers: OpenAI, Z.AI, Ollama
- Disabled by default (`ENABLE_CATEGORIZATION=false`)
- Categories: personal, work, health, finance, travel, education, preferences, relationships

### 4. Data Layer

#### SQLite Database (`openmemory.db`)
Stores structured metadata and relationships:

**Core Tables:**
- `users`: User accounts and profiles
- `apps`: Applications with access to memories
- `memories`: Memory metadata (content, state, timestamps)
- `categories`: Memory categorization
- `memory_categories`: Many-to-many relationship

**Access Control:**
- `access_controls`: Fine-grained permissions (ACL)
- `memory_access_logs`: Audit trail of memory access
- `memory_status_history`: State change tracking

**Configuration:**
- `configs`: System configuration (LLM, embedder, vector store)

#### Vector Store (Qdrant - Port 6333)
Stores vector embeddings for semantic search:
- **Collection**: `openmemory`
- **Dimensions**: 384 (HuggingFace), 1536 (OpenAI), 1024-2048 (Z.AI), 768-1024 (Ollama)
- **Payload**: `{data, user_id, hash, created_at, source_app, mcp_client}`
- **Indexing**: HNSW for fast approximate nearest neighbor search

## Data Flow

### Memory Creation Flow

```
1. Client → API: POST /api/v1/memories {text, user_id, app}
2. API validates user and app (SQLite)
3. API → Memory Client: add(text, user_id, metadata)
4. Memory Client → Embedder: Generate embedding vector
5. Memory Client → LLM: Extract facts and process text
6. Memory Client → Qdrant: Store vector + payload
7. Qdrant → Memory Client: Return memory ID
8. Memory Client → API: Return {results: [{event: 'ADD', id, memory}]}
9. API → SQLite: INSERT memory metadata with same ID
10. API → SQLite: INSERT status_history entry
11. API → Client: Return memory object
```

### Memory Search Flow

```
1. Client → API: POST /api/v1/memories/search {query, user_id}
2. API → Memory Client: search(query, user_id)
3. Memory Client → Embedder: Generate query embedding
4. Memory Client → Qdrant: Vector similarity search
5. Qdrant → Memory Client: Return top-k results with scores
6. Memory Client → API: Filter by ACL permissions
7. API → SQLite: Log access in memory_access_logs
8. API → Client: Return filtered results
```

## Key Design Decisions

### Dual Storage Architecture
**Why both SQLite and Qdrant?**
- **Qdrant**: Optimized for vector similarity search, enables semantic memory retrieval
- **SQLite**: Provides structured queries, relationships, access control, and audit trails
- **Synchronization**: Same UUID used in both stores to maintain consistency
- **UI Queries**: UI reads from SQLite only for performance and simplicity

### Memory State Management
Memories have four states:
- `active`: Available for search and retrieval
- `paused`: Temporarily excluded from search results
- `archived`: Long-term storage, excluded by default
- `deleted`: Soft-deleted, can be restored

### Access Control
- **App-based isolation**: Each app can only access memories it created
- **ACL system**: Fine-grained permissions via `access_controls` table
- **Audit logging**: All memory access tracked in `memory_access_logs`

### Configuration Management
- **Database-first**: Configuration stored in SQLite `configs` table
- **Hot reload**: Memory client reinitializes when config changes
- **Environment variables**: Support for `env:VAR_NAME` syntax in API keys
- **Docker-aware**: Automatic URL adjustment for Ollama in containers

## Deployment Architecture

### Docker Compose Setup
```yaml
services:
  mem0_store:        # Qdrant vector database
  openmemory-mcp:    # FastAPI backend + MCP server
  openmemory-ui:     # Next.js frontend
```

### Volume Mounts
- `mem0_storage`: Qdrant data persistence
- `./api:/usr/src/openmemory`: Hot reload for development
- SQLite database: `./api/openmemory.db`

### Network Configuration
- **UI → API**: `http://localhost:8765` (configurable via `NEXT_PUBLIC_API_URL`)
- **API → Qdrant**: `http://mem0_store:6333` (internal Docker network)
- **API → Ollama**: `http://host.docker.internal:11434` (host machine)

## Security Considerations

### API Keys
- Stored as `env:VAR_NAME` references in config
- Parsed at runtime from environment variables
- Never exposed in API responses

### Data Privacy
- All data stored locally (SQLite + Qdrant)
- No external data transmission except to configured LLM/embedder APIs
- User data isolated by `user_id`

### Access Control
- App-level permissions prevent cross-app data access
- ACL system for fine-grained memory sharing
- Audit logs for compliance and debugging

## Performance Characteristics

### Vector Search
- **Qdrant HNSW index**: Sub-millisecond search for 100k+ vectors
- **Embedding dimensions**: 384 (HuggingFace) vs 1536 (OpenAI)
- **Trade-off**: Lower dimensions = faster search, slightly lower accuracy

### Database Queries
- **SQLite**: Optimized for read-heavy workloads
- **Indexes**: On user_id, app_id, state, created_at
- **Pagination**: Server-side pagination for large result sets

### Caching
- **Memory client**: Singleton pattern, reused across requests
- **Config hash**: Prevents unnecessary reinitialization
- **Embeddings**: Cached in Qdrant, not recomputed

## Extensibility

### Adding New LLM Providers
1. Update `LLMConfig` schema in `app/routers/config.py`
2. Add provider-specific URL handling in `app/utils/memory.py`
3. Mem0 SDK handles provider abstraction via LiteLLM

### Adding New Vector Stores
1. Create compose file in `compose/{vectorstore}.yml`
2. Update `get_default_memory_config()` in `app/utils/memory.py`
3. Add environment variable detection
4. Configure via API or UI

### Custom Categorization
1. Implement provider in `app/utils/categorization.py`
2. Add to `get_categories_for_memory()` switch statement
3. Set `CATEGORIZATION_PROVIDER` environment variable

## Monitoring and Debugging

### Logs
- **API logs**: `docker logs openmemory-mcp-1`
- **UI logs**: `docker logs openmemory-ui-1`
- **Qdrant logs**: `docker logs mem0_store-1`

### Health Checks
- API: `GET http://localhost:8765/docs` (Swagger UI)
- Qdrant: `GET http://localhost:6333/dashboard`
- UI: `http://localhost:3000`

### Common Issues
1. **Dimension mismatch**: Qdrant collection created with wrong dimensions
   - Solution: Delete collection, restart with correct embedder config
2. **Memory in Qdrant but not UI**: SQLite insert failed
   - Check logs for database errors, verify transaction commits
3. **Ollama connection failed**: Docker networking issue
   - Verify `host.docker.internal` resolves, check Ollama running on host

## References

- [Mem0 Documentation](https://docs.mem0.ai/)
- [Qdrant Documentation](https://qdrant.tech/documentation/)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Next.js Documentation](https://nextjs.org/docs)


