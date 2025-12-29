# LLM Setup Guide

This guide explains how to configure LLMs and embedders in OpenMemory for memory processing and categorization.

## Overview

OpenMemory uses LLMs in two places:

1. **Memory Processing (Mem0)**: Extracts facts, deduplicates, and updates memories
2. **Categorization (Optional)**: Automatically categorizes memories into topics

## Configuration Methods

You can configure LLMs through:
1. **Web UI** (Settings page) - Recommended for most users
2. **API calls** - For programmatic configuration
3. **Config files** - For deployment and version control

---

## Memory Processing LLM (Mem0)

The Mem0 LLM is used for core memory operations: fact extraction, deduplication, and memory updates.

### Supported Providers

#### 1. OpenAI (Recommended)

**Configuration:**
```json
{
  "mem0": {
    "llm": {
      "provider": "openai",
      "config": {
        "model": "gpt-4o-mini",
        "temperature": 0.1,
        "max_tokens": 2000,
        "api_key": "env:OPENAI_API_KEY"
      }
    }
  }
}
```

**Environment Variable:**
```bash
OPENAI_API_KEY=sk-your-key-here
```

**Recommended Models:**
- `gpt-4o-mini` - Best balance of cost and performance
- `gpt-4o` - Highest quality, more expensive
- `gpt-3.5-turbo` - Fastest, lowest cost

---

#### 2. Ollama (Local, Free)

**Configuration:**
```json
{
  "mem0": {
    "llm": {
      "provider": "ollama",
      "config": {
        "model": "phi3:mini",
        "temperature": 0.1,
        "max_tokens": 2000,
        "ollama_base_url": "http://host.docker.internal:11434"
      }
    }
  }
}
```

**Setup:**
1. Install Ollama: `brew install ollama` (macOS) or visit [ollama.ai](https://ollama.ai)
2. Pull a model: `ollama pull phi3:mini`
3. Verify running: `ollama list`

**Recommended Models:**
- `phi3:mini` - Fast, good quality (3.8GB)
- `llama3.1:8b` - Better quality (4.7GB)
- `mistral` - Good balance (4.1GB)

**Docker Note:** Use `http://host.docker.internal:11434` to reach Ollama on host machine.

---

#### 3. Z.AI (Zhipu AI)

Z.AI provides OpenAI-compatible API with GLM models.

**Option A: Using LiteLLM (Recommended)**
```json
{
  "mem0": {
    "llm": {
      "provider": "litellm",
      "config": {
        "model": "openai/glm-4.7",
        "temperature": 0.1,
        "max_tokens": 2000,
        "api_key": "env:ZAI_API_KEY",
        "api_base": "https://api.z.ai/api/paas/v4"
      }
    }
  }
}
```

**Option B: Using OpenAI Provider**
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
        "openai_base_url": "https://api.z.ai/api/paas/v4"
      }
    }
  }
}
```

**Environment Variable:**
```bash
ZAI_API_KEY=your-zai-api-key
```

**Available Models:**
- `glm-4.7` - Latest, most capable
- `glm-4.6` - Previous version
- `glm-4.5` - Lighter version
- `glm-4.5-air` - Fastest, most cost-effective

---

## Embedder Configuration

The embedder converts text to vector embeddings for semantic search.

### Embeddings Comparison

| Provider | Models | Dimensions | Cost | Notes |
|----------|--------|------------|------|-------|
| **HuggingFace** | all-MiniLM-L6-v2 | 384 | Free | Default; runs locally; fast |
| **OpenAI** | text-embedding-3-small | 1536 | $0.02/1M tokens | High quality; widely used |
| **OpenAI** | text-embedding-3-large | 3072 | $0.13/1M tokens | Highest quality; expensive |
| **Z.AI** | embedding-2 | 1024 | Varies | Pairs well with GLM models |
| **Z.AI** | embedding-3 | 2048 | Varies | High-dimensional; best for Z.AI ecosystem |
| **Ollama** | nomic-embed-text | 768 | Free | Local; good quality |
| **Ollama** | mxbai-embed-large | 1024 | Free | Local; higher dimensions |

**Important:** Changing embedder dimensions requires recreating the Qdrant collection.

### Supported Providers

#### 1. HuggingFace (Default, Free)

**Configuration:**
```json
{
  "mem0": {
    "embedder": {
      "provider": "huggingface",
      "config": {
        "model": "sentence-transformers/all-MiniLM-L6-v2"
      }
    }
  }
}
```

**Characteristics:**
- **Dimensions**: 384
- **Speed**: Fast (runs locally)
- **Cost**: Free
- **Quality**: Good for most use cases

**Alternative Models:**
- `sentence-transformers/all-mpnet-base-v2` - Higher quality (768 dims)
- `BAAI/bge-small-en-v1.5` - Optimized for retrieval (384 dims)

---

#### 2. OpenAI Embeddings

**Configuration:**
```json
{
  "mem0": {
    "embedder": {
      "provider": "openai",
      "config": {
        "model": "text-embedding-3-small",
        "api_key": "env:OPENAI_API_KEY"
      }
    }
  }
}
```

**Models:**
- `text-embedding-3-small` - 1536 dimensions, $0.02/1M tokens
- `text-embedding-3-large` - 3072 dimensions, $0.13/1M tokens

**Note:** Changing embedder requires recreating Qdrant collection (different dimensions).

---

#### 3. Z.AI Embeddings

**Configuration:**
```json
{
  "mem0": {
    "embedder": {
      "provider": "openai",
      "config": {
        "model": "embedding-3",
        "api_key": "env:ZAI_API_KEY",
        "openai_base_url": "https://api.z.ai/api/paas/v4"
      }
    }
  }
}
```

**Environment Variable:**
```bash
ZAI_API_KEY=your-zai-api-key
```

**Available Models:**
- `embedding-2` - 1024 dimensions
- `embedding-3` - 2048 dimensions (recommended)

**Benefits:**
- Pairs well with GLM models for end-to-end Z.AI ecosystem
- High-dimensional embeddings (2048) for better semantic search
- OpenAI-compatible API

---

#### 4. Ollama Embeddings

**Configuration:**
```json
{
  "mem0": {
    "embedder": {
      "provider": "ollama",
      "config": {
        "model": "nomic-embed-text",
        "ollama_base_url": "http://host.docker.internal:11434"
      }
    }
  }
}
```

**Setup:**
```bash
ollama pull nomic-embed-text
```

**Recommended Models:**
- `nomic-embed-text` - 768 dimensions, high quality
- `mxbai-embed-large` - 1024 dimensions

---

## Categorization LLM (Optional)

Automatic categorization is **disabled by default**. Enable it to automatically tag memories.

### Enable Categorization

**Environment Variable:**
```bash
ENABLE_CATEGORIZATION=true
CATEGORIZATION_PROVIDER=openai  # or ollama, zai
CATEGORIZATION_MODEL=gpt-4o-mini
```

**Categories:**
- personal, work, health, finance, travel, education, preferences, relationships

### Provider Options

#### 1. OpenAI (Most Reliable)

```bash
ENABLE_CATEGORIZATION=true
CATEGORIZATION_PROVIDER=openai
CATEGORIZATION_MODEL=gpt-4o-mini
OPENAI_API_KEY=sk-your-key
```

**Features:**
- Structured output with JSON schema
- Guaranteed valid JSON
- Most reliable categorization

---

#### 2. Z.AI (Zhipu AI)

```bash
ENABLE_CATEGORIZATION=true
CATEGORIZATION_PROVIDER=zai
CATEGORIZATION_MODEL=glm-4.7
ZAI_API_KEY=your-zai-key
```

**Features:**
- OpenAI-compatible structured output
- Supports GLM-4.7, GLM-4.6, GLM-4.5
- Good reliability

---

#### 3. Ollama (Local, Best Effort)

```bash
ENABLE_CATEGORIZATION=true
CATEGORIZATION_PROVIDER=ollama
CATEGORIZATION_MODEL=phi3:mini
```

**Features:**
- Runs locally, no API key needed
- Uses JSON mode (not guaranteed)
- Less reliable than OpenAI/Z.AI

**Note:** Ollama's JSON output may occasionally fail to parse. Use OpenAI or Z.AI for production.

---

## Configuration via Web UI

1. Navigate to **Settings** page
2. Scroll to **LLM Configuration**
3. Select provider from dropdown
4. Fill in model name and API key
5. Click **Save Configuration**

The memory client will automatically reinitialize with new settings.

---

## Configuration via API

### Update LLM

```bash
curl -X PUT http://localhost:8765/api/v1/config/mem0/llm \
  -H 'Content-Type: application/json' \
  -d '{
    "provider": "openai",
    "config": {
      "model": "gpt-4o-mini",
      "temperature": 0.1,
      "max_tokens": 2000,
      "api_key": "env:OPENAI_API_KEY"
    }
  }'
```

### Update Embedder

```bash
curl -X PUT http://localhost:8765/api/v1/config/mem0/embedder \
  -H 'Content-Type: application/json' \
  -d '{
    "provider": "huggingface",
    "config": {
      "model": "sentence-transformers/all-MiniLM-L6-v2"
    }
  }'
```

### Get Current Configuration

```bash
curl http://localhost:8765/api/v1/config
```

---

## Configuration via Files

### Edit `api/config.json`

```json
{
  "openmemory": {
    "custom_instructions": null
  },
  "mem0": {
    "llm": {
      "provider": "openai",
      "config": {
        "model": "gpt-4o-mini",
        "temperature": 0.1,
        "max_tokens": 2000,
        "api_key": "env:OPENAI_API_KEY"
      }
    },
    "embedder": {
      "provider": "huggingface",
      "config": {
        "model": "sentence-transformers/all-MiniLM-L6-v2"
      }
    }
  }
}
```

### Environment Variables (`.env`)

```bash
# OpenAI
OPENAI_API_KEY=sk-your-key-here

# Z.AI
ZAI_API_KEY=your-zai-key

# Categorization
ENABLE_CATEGORIZATION=false
CATEGORIZATION_PROVIDER=openai
CATEGORIZATION_MODEL=gpt-4o-mini
```

**Restart Required:** Changes to config files require restarting the API container.

---

## Best Practices

### API Key Security

1. **Use environment variables**: Store keys as `env:VAR_NAME` in config
2. **Never commit keys**: Add `.env` to `.gitignore`
3. **Rotate regularly**: Update keys periodically

### Model Selection

**For Memory Processing:**
- **Production**: Z.AI `glm-4.7` (default, best value)
- **Alternative**: OpenAI `gpt-4o-mini` (best reliability)
- **Development**: Ollama `phi3:mini` (free, local)
- **Privacy-focused**: Ollama `llama3.1:8b` (runs locally)

**For Embeddings:**
- **Default**: HuggingFace `all-MiniLM-L6-v2` (free, fast, 384 dims)
- **Higher quality**: OpenAI `text-embedding-3-small` (1536 dims)
- **Z.AI ecosystem**: Z.AI `embedding-3` (2048 dims, pairs with GLM models)
- **Local**: Ollama `nomic-embed-text` (768 dims)

### Performance Tuning

**Temperature:**
- `0.0-0.2` - Deterministic, consistent (recommended for memory processing)
- `0.5-0.7` - Balanced creativity
- `0.8-1.0` - More creative, less consistent

**Max Tokens:**
- `1000-2000` - Sufficient for most memories
- `4000+` - For very long documents

---

## Troubleshooting

### "Memory client is not available"

**Cause:** LLM or embedder configuration is invalid.

**Solutions:**
1. Check API key is set: `echo $OPENAI_API_KEY`
2. Verify model name is correct
3. Check logs: `docker logs openmemory-mcp-1`
4. Test API key with curl

### "Dimension mismatch" in Qdrant

**Cause:** Changed embedder with different dimensions.

**Solution:**
1. Delete Qdrant collection: `curl -X DELETE http://localhost:6333/collections/openmemory`
2. Restart API: `docker-compose restart openmemory-mcp`
3. Collection will be recreated with correct dimensions

### Ollama connection failed

**Cause:** Docker can't reach Ollama on host.

**Solutions:**
1. Verify Ollama running: `ollama list`
2. Use `http://host.docker.internal:11434` (Mac/Windows)
3. Use `http://172.17.0.1:11434` (Linux)
4. Set `OLLAMA_HOST` environment variable

### Categorization not working

**Checks:**
1. `ENABLE_CATEGORIZATION=true` is set
2. Provider and model are configured
3. API key is valid (for OpenAI/Z.AI)
4. Check logs for JSON parsing errors

---

## Advanced Configuration

### Custom Instructions

Add custom instructions for memory processing:

```json
{
  "openmemory": {
    "custom_instructions": "Focus on extracting actionable tasks and deadlines. Prioritize work-related information."
  }
}
```

### Multiple Providers

You can use different providers for different components:

**Example 1: Mixed Providers (Cost-Optimized)**
```json
{
  "mem0": {
    "llm": {
      "provider": "openai",
      "config": {"model": "gpt-4o-mini", "api_key": "env:OPENAI_API_KEY"}
    },
    "embedder": {
      "provider": "huggingface",
      "config": {"model": "sentence-transformers/all-MiniLM-L6-v2"}
    }
  }
}
```

**Categorization:**
```bash
CATEGORIZATION_PROVIDER=zai
CATEGORIZATION_MODEL=glm-4.7
```

This setup uses OpenAI for memory processing, HuggingFace for embeddings (free), and Z.AI for categorization.

---

**Example 2: Full Z.AI Ecosystem**
```json
{
  "mem0": {
    "llm": {
      "provider": "openai",
      "config": {
        "model": "glm-4.7",
        "api_key": "env:ZAI_API_KEY",
        "openai_base_url": "https://api.z.ai/api/paas/v4"
      }
    },
    "embedder": {
      "provider": "openai",
      "config": {
        "model": "embedding-3",
        "api_key": "env:ZAI_API_KEY",
        "openai_base_url": "https://api.z.ai/api/paas/v4"
      }
    }
  }
}
```

**Categorization:**
```bash
CATEGORIZATION_PROVIDER=zai
CATEGORIZATION_MODEL=glm-4.7
ZAI_API_KEY=your-zai-key
```

This setup uses Z.AI for everything: GLM-4.7 for memory processing, embedding-3 for semantic search, and GLM-4.7 for categorization. Benefits include unified billing, optimized model compatibility, and high-quality 2048-dimensional embeddings.

---

**Example 3: Fully Local (Privacy-Focused)**
```json
{
  "mem0": {
    "llm": {
      "provider": "ollama",
      "config": {
        "model": "llama3.1:8b",
        "ollama_base_url": "http://host.docker.internal:11434"
      }
    },
    "embedder": {
      "provider": "ollama",
      "config": {
        "model": "nomic-embed-text",
        "ollama_base_url": "http://host.docker.internal:11434"
      }
    }
  }
}
```

**Categorization:**
```bash
CATEGORIZATION_PROVIDER=ollama
CATEGORIZATION_MODEL=llama3.1:8b
```

This setup runs entirely locally with no external API calls. Best for privacy-sensitive use cases.

---

## Quick Reference

### Recommended Configurations

**Best Overall (Production):**
- LLM: OpenAI `gpt-4o-mini`
- Embedder: OpenAI `text-embedding-3-small`
- Categorization: OpenAI `gpt-4o-mini`
- Cost: ~$0.50-2/month for typical usage

**Best Free (Local):**
- LLM: Ollama `llama3.1:8b`
- Embedder: HuggingFace `all-MiniLM-L6-v2`
- Categorization: Disabled or Ollama `phi3:mini`
- Cost: Free (requires local compute)

**Best Z.AI Ecosystem:**
- LLM: Z.AI `glm-4.7`
- Embedder: Z.AI `embedding-3`
- Categorization: Z.AI `glm-4.7`
- Cost: Varies by Z.AI pricing
- Benefits: Unified billing, optimized compatibility, 2048-dim embeddings

**Best Hybrid (Cost-Optimized):**
- LLM: OpenAI `gpt-4o-mini`
- Embedder: HuggingFace `all-MiniLM-L6-v2` (free)
- Categorization: Z.AI `glm-4.7` or disabled
- Cost: ~$0.20-1/month

### Environment Variables Quick Setup

**OpenAI:**
```bash
OPENAI_API_KEY=sk-xxx
```

**Z.AI:**
```bash
ZAI_API_KEY=your-zai-key
CATEGORIZATION_PROVIDER=zai
CATEGORIZATION_MODEL=glm-4.7
```

**Ollama:**
```bash
# No API key needed
# Just ensure Ollama is running: ollama serve
```

**Categorization:**
```bash
ENABLE_CATEGORIZATION=true
CATEGORIZATION_PROVIDER=openai  # or zai, ollama
CATEGORIZATION_MODEL=gpt-4o-mini
```

---

## References

- [Mem0 LLM Documentation](https://docs.mem0.ai/components/llms/overview)
- [Mem0 Embedder Documentation](https://docs.mem0.ai/components/embedders/overview)
- [OpenAI Models](https://platform.openai.com/docs/models)
- [Ollama Models](https://ollama.ai/library)
- [Z.AI Documentation](https://open.bigmodel.cn/dev/api)
- [LiteLLM Providers](https://docs.litellm.ai/docs/providers)


