# OpenMemory Usage Guide

Once you've configured the OpenMemory MCP server with your AI assistant, it works automatically in the background. No special prompts are required!

## How It Works

OpenMemory provides your AI assistant with **persistent memory** across conversations through these tools:

### 🔍 **search_memory** (Automatic)
- **Triggered**: Automatically on EVERY user query
- **Purpose**: Retrieves relevant memories to provide context
- **You don't need to ask**: The AI automatically searches your memories before responding

### 💾 **add_memories** (Automatic)
- **Triggered**: When you share information about yourself, preferences, or ask to remember something
- **Purpose**: Stores important information for future conversations
- **How it works**:
  1. Your conversation is sent to Mem0's LLM (configured in settings)
  2. The LLM extracts key facts, preferences, and important details
  3. Memories are deduplicated and checked for conflicts
  4. The extracted memory is stored in the vector database
- **Examples**:
  - "I prefer dark mode" → Stored as: "User prefers dark mode"
  - "My name is Rob" → Stored as: "User's name is Rob"
  - "Remember that I'm working on the OpenMemory project" → Stored as: "User is working on OpenMemory project"
  - "I use Python and TypeScript" → Stored as: "User uses Python and TypeScript"

### 📋 **list_memories** (On Request)
- **Triggered**: When you explicitly ask to see your memories
- **Purpose**: Shows all stored memories
- **Examples**:
  - "What do you remember about me?"
  - "Show me my memories"
  - "List all my stored information"

### 🗑️ **delete_memories** (On Request)
- **Triggered**: When you ask to delete specific memories
- **Purpose**: Removes memories by ID
- **Examples**:
  - "Delete memory abc-123"
  - "Remove the memory about my old email"

### 🧹 **delete_all_memories** (On Request)
- **Triggered**: When you ask to clear all memories
- **Purpose**: Wipes all stored memories
- **Examples**:
  - "Clear all my memories"
  - "Delete everything you remember about me"

---

## Usage Examples

### Natural Conversation (No Special Prompts Needed)

**You**: I prefer using TypeScript over JavaScript

**AI**: *(Automatically stores this preference)*
Got it! I'll remember that you prefer TypeScript over JavaScript.

---

**You**: What's the best way to handle async operations?

**AI**: *(Automatically searches memories and finds your TypeScript preference)*
Since you prefer TypeScript, I'd recommend using async/await with proper type annotations...

---

### Explicitly Asking to Remember

**You**: Remember that I'm working on a memory system called OpenMemory

**AI**: *(Stores the memory)*
I'll remember that you're working on OpenMemory, a memory system.

---

### Checking What's Remembered

**You**: What do you know about me?

**AI**: *(Lists your memories)*
Based on my memories, here's what I know about you:
- You prefer TypeScript over JavaScript
- You're working on a memory system called OpenMemory
- You prefer dark mode
...

---

## Tips for Best Results

### ✅ DO:
- **Be specific**: "I prefer React over Vue for frontend development"
- **Share context**: "I'm working on the OpenMemory project, which is a memory system for AI"
- **Update preferences**: "Actually, I've switched to using Svelte now"
- **Ask naturally**: Just talk normally - the AI will remember important details

### ❌ DON'T:
- **Don't use special syntax**: No need for `@remember` or special commands
- **Don't repeat yourself**: Once stored, the AI will remember across conversations
- **Don't worry about formatting**: Natural language works best

---

## Privacy & Control

### View Your Memories
```bash
# Via API
curl http://localhost:8765/api/v1/memories/filter \
  -H 'Content-Type: application/json' \
  -d '{"user_id": "rob", "page": 1, "size": 100}'
```

Or ask your AI: "Show me all my memories"

### Delete Specific Memories
Ask your AI: "Delete the memory about [topic]" or "Remove memory [ID]"

### Clear All Memories
Ask your AI: "Clear all my memories" or "Delete everything you know about me"

### Use the Web UI
Navigate to `http://localhost:3000` to manage memories visually.

---

## Multi-Client Support

OpenMemory tracks which client (Augment, Claude, Goose, etc.) created each memory and manages access permissions:

- **Shared memories**: Accessible across all your AI assistants
- **Client-specific**: Some memories may be restricted to specific apps
- **User-specific**: Your memories are isolated from other users

---

## Troubleshooting

### "No memories found"
- Make sure you've shared some information first
- Check if OpenMemory is running: `docker ps | grep openmemory`
- Verify the MCP connection in your AI assistant's settings

### "Memory system unavailable"
- Ensure Docker containers are running: `docker-compose up -d`
- Check logs: `docker logs openmemory-mcp-1`
- Verify Qdrant is accessible: `curl http://localhost:6333/collections`

### Memories not persisting
- Check database: `sqlite3 openmemory/api/openmemory.db "SELECT COUNT(*) FROM memories;"`
- Verify user_id matches your configuration
- Check app permissions in the web UI

---

## How Memory Summaries Are Created

When you share information, OpenMemory uses **Mem0's intelligent extraction** to create clean, structured memories:

### The Process

1. **Information Extraction**
   - Your conversation messages are sent to the configured LLM (default: Z.AI glm-4.7)
   - The LLM analyzes the conversation and extracts key facts, preferences, and decisions
   - Raw text like "I'm planning a trip to Tokyo next month" becomes "User is planning a trip to Tokyo"

2. **Conflict Resolution**
   - Mem0 compares new memories against existing ones
   - Detects duplicates and contradictions
   - Updates or merges memories intelligently
   - Example: "I prefer Vue" updates the previous "User prefers React"

3. **Memory Storage**
   - Extracted facts are stored in the vector database (Qdrant)
   - Embeddings are created for semantic search
   - Metadata is saved in SQLite for filtering and access control

### Configuring the LLM

The LLM used for memory extraction is configured in Settings or `config.json`:

```json
{
  "mem0": {
    "llm": {
      "provider": "openai",
      "config": {
        "model": "glm-4.7",
        "temperature": 0.1,
        "max_tokens": 2000,
        "api_key": "env:ZAI_API_KEY",
        "openai_base_url": "https://api.z.ai/api/coding/paas/v4"
      }
    }
  }
}
```

**Supported LLM Providers:**
- **Z.AI** (default, GLM models)
- **OpenAI** (GPT-4, GPT-3.5)
- **Anthropic** (Claude)
- **Google** (Gemini)
- **Ollama** (local, free)

See [LLM_SETUP.md](./LLM_SETUP.md) for detailed configuration.

### Inference Mode

By default, memories are **inferred** (extracted by LLM). You can disable this:

**Via API:**
```bash
curl -X POST http://localhost:8765/api/v1/memories/ \
  -H 'Content-Type: application/json' \
  -d '{
    "user_id": "rob",
    "text": "Raw text to store as-is",
    "infer": false
  }'
```

**Via MCP:** The `add_memories` tool always uses inference (default behavior).

---

## Advanced Usage

### Custom User IDs
If you configured a custom user_id, all memories are stored under that ID. You can have multiple user profiles by using different user_ids in the MCP URL.

### App-Specific Memories
Memories can be restricted to specific apps (e.g., only accessible by Augment, not Claude). Manage this in the web UI under Apps → Access Control.

### Backup & Export
```bash
# Export all memories
curl http://localhost:8765/api/v1/backup/export/rob > memories_backup.json

# Import memories
curl -X POST http://localhost:8765/api/v1/backup/import \
  -H 'Content-Type: application/json' \
  -d @memories_backup.json
```

---

## Next Steps

- **Explore the Web UI**: `http://localhost:3000`
- **Check API docs**: `http://localhost:8765/docs`
- **Read Architecture**: See `ARCHITECTURE.md` for technical details
- **Configure LLMs**: See `LLM_SETUP.md` for custom embeddings/LLMs

