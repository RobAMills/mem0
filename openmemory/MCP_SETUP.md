# MCP Server Setup Guide

This guide explains how to configure the OpenMemory MCP server with various AI assistants.

## Overview

OpenMemory provides a Model Context Protocol (MCP) server that allows AI assistants to:
- **Add memories**: Store information for later retrieval
- **Search memories**: Semantic search through stored memories (called automatically on every query)
- **List memories**: Browse all stored memories

The MCP server uses **SSE (Server-Sent Events)** transport and is available at:
```
http://localhost:8765/mcp/{client_name}/sse/{user_id}
```

## Prerequisites

1. OpenMemory must be running:
   ```bash
   cd openmemory
   docker-compose up -d
   ```

2. Verify the API is accessible:
   ```bash
   curl http://localhost:8765/api/v1/config/
   ```

---

## Augment Code (VS Code Extension)

### Configuration

1. **Create or edit** `~/.augment/settings.json`:

```json
{
  "mcpServers": {
    "openmemory": {
      "type": "sse",
      "url": "http://localhost:8765/mcp/augment/sse/rob"
    }
  }
}
```

2. **Restart VS Code** or reload the Augment extension

3. **Verify** the connection in Augment's output panel

### URL Format
```
http://localhost:8765/mcp/{client_name}/sse/{user_id}
```
- `client_name`: `augment` (identifies the client)
- `user_id`: `rob` (your user ID from the database)

### Available Tools

Once configured, Augment can use:
- `add_memories(text)` - Store new information
- `search_memory(query)` - Search memories (auto-called on queries)
- `list_memories()` - List all memories

---

## Auggie CLI

For the command-line interface:

```bash
auggie mcp add openmemory \
  --transport sse \
  --url http://localhost:8765/mcp/auggie/sse/rob
```

Or compressed syntax:
```bash
auggie mcp add openmemory --transport sse http://localhost:8765/mcp/auggie/sse/rob
```

### Verify Configuration
```bash
auggie mcp list
```

---

## Claude Desktop

### Configuration

1. **Edit** Claude Desktop config file:
   - **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
   - **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

2. **Add OpenMemory server**:

```json
{
  "mcpServers": {
    "openmemory": {
      "type": "sse",
      "url": "http://localhost:8765/mcp/claude/sse/rob"
    }
  }
}
```

3. **Restart Claude Desktop**

4. **Verify** by asking Claude: "What MCP tools do you have access to?"

---

## Cursor IDE

### Configuration

1. **Edit** Cursor settings:
   - Open Cursor Settings (Cmd/Ctrl + ,)
   - Search for "MCP"
   - Or edit `~/.cursor/mcp_config.json`

2. **Add configuration**:

```json
{
  "mcpServers": {
    "openmemory": {
      "type": "sse",
      "url": "http://localhost:8765/mcp/cursor/sse/rob"
    }
  }
}
```

3. **Restart Cursor**

---

## Windsurf

### Configuration

1. **Edit** Windsurf config:
   - **macOS**: `~/Library/Application Support/Windsurf/mcp_config.json`
   - **Windows**: `%APPDATA%\Windsurf\mcp_config.json`

2. **Add configuration**:

```json
{
  "mcpServers": {
    "openmemory": {
      "type": "sse",
      "url": "http://localhost:8765/mcp/windsurf/sse/rob"
    }
  }
}
```

3. **Restart Windsurf**

---

## Goose

Goose is an open-source AI agent that supports MCP extensions.

### Configuration

**Option 1: Using goose configure (Recommended)**

1. Run the configuration command:
   ```bash
   goose configure
   ```

2. Select **Add Extension** from the menu

3. Choose **Remote Extension (SSE)**

4. Follow the prompts:
   - **Name**: `OpenMemory`
   - **URL**: `http://localhost:8765/mcp/goose/sse/rob`
   - **Timeout**: `300` (seconds)

**Option 2: Direct config file edit**

Edit `~/.config/goose/config.yaml`:

```yaml
extensions:
  openmemory:
    name: OpenMemory
    url: http://localhost:8765/mcp/goose/sse/rob
    enabled: true
    type: sse
    timeout: 300
```

**Option 3: Start session with extension**

```bash
goose session --with-remote-extension "http://localhost:8765/mcp/goose/sse/rob"
```

### Verify Configuration

```bash
goose configure
```

Select **Toggle Extensions** to see if OpenMemory is listed and enabled.

---

## Custom User ID

To use a different user ID, update the URL:

```json
{
  "mcpServers": {
    "openmemory": {
      "type": "sse",
      "url": "http://localhost:8765/mcp/{client_name}/sse/{your_user_id}"
    }
  }
}
```

Check your user ID:
```bash
sqlite3 openmemory/api/openmemory.db "SELECT user_id FROM users;"
```

---

## Troubleshooting

### Connection Failed

**Check if OpenMemory is running:**
```bash
docker ps | grep openmemory
```

**Check API accessibility:**
```bash
curl http://localhost:8765/api/v1/config/
```

**Check logs:**
```bash
docker logs openmemory-mcp-1
```

### Tools Not Appearing

1. **Verify MCP endpoint** is accessible:
   ```bash
   curl http://localhost:8765/mcp/augment/sse/rob
   ```

2. **Check client logs** for connection errors

3. **Restart the client** application

### Wrong User ID

**List all users:**
```bash
sqlite3 openmemory/api/openmemory.db "SELECT user_id, name FROM users;"
```

**Update URL** with correct user_id

---

## Testing the Connection

### Via API
```bash
# Add a memory
curl -X POST http://localhost:8765/api/v1/memories/ \
  -H 'Content-Type: application/json' \
  -d '{
    "user_id": "rob",
    "text": "Test memory from MCP setup",
    "app": "augment",
    "infer": false
  }'

# Search memories
curl -X POST http://localhost:8765/api/v1/memories/filter \
  -H 'Content-Type: application/json' \
  -d '{
    "user_id": "rob",
    "page": 1,
    "size": 10,
    "search_query": "test"
  }'
```

### Via Client

Ask your AI assistant:
- "Remember that I prefer dark mode"
- "What do you remember about me?"
- "Search my memories for 'dark mode'"

---

## Security Considerations

### Local Development
The current setup uses `http://localhost:8765` which is only accessible from your machine.

### Production Deployment
For production use:

1. **Enable HTTPS** with a reverse proxy (nginx, Caddy)
2. **Add authentication** to the MCP endpoints
3. **Use environment variables** for sensitive configuration
4. **Restrict CORS** origins in the API

---

## Advanced Configuration

### Multiple Users

Configure different URLs for different clients:

```json
{
  "mcpServers": {
    "openmemory-personal": {
      "type": "sse",
      "url": "http://localhost:8765/mcp/augment/sse/rob"
    },
    "openmemory-work": {
      "type": "sse",
      "url": "http://localhost:8765/mcp/augment/sse/rob-work"
    }
  }
}
```

### Custom Port

If running on a different port, update the URL:
```json
{
  "mcpServers": {
    "openmemory": {
      "type": "sse",
      "url": "http://localhost:9000/mcp/augment/sse/rob"
    }
  }
}
```

---

## Using OpenMemory

Once configured, OpenMemory works automatically! See the [Usage Guide](./USAGE_GUIDE.md) for:
- How memories are automatically stored and retrieved
- Example conversations
- Tips for best results
- Privacy controls and memory management

**Quick Start**: Just talk naturally with your AI assistant. It will automatically:
- 🔍 Search your memories on every query
- 💾 Store important information you share
- 📋 List memories when you ask

No special prompts or commands needed!

---

## References

- [OpenMemory Usage Guide](./USAGE_GUIDE.md) - How to use OpenMemory with your AI assistant
- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
- [Augment MCP Documentation](https://docs.augmentcode.com/cli/integrations)
- [OpenMemory Architecture](./ARCHITECTURE.md)
- [OpenMemory API Documentation](http://localhost:8765/docs)

