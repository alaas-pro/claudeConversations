# Claude Tmux Scripts

Two bash scripts for capturing and processing Claude Code conversations with automatic knowledge base integration.

## 📁 Scripts

### `claude-tmux-lessons.sh` (Recommended)
**Smart lesson extraction script**

Automatically asks Claude to extract key lessons when you type `exitnow`, then saves both conversation and lesson summary to your knowledge base.

**Usage:**
```bash
./claude-tmux-lessons.sh
# Have your conversation
# Type 'exitnow' when done
# Script automatically extracts lessons and saves
```

### `claude-tmux-auto.sh`
**Basic conversation capture script**

Captures Claude conversations when you exit and imports to Archon knowledge base. You need to manually ask Claude for lessons during the conversation.

**Usage:**
```bash
./claude-tmux-auto.sh
# Have your conversation
# Manually ask: "Extract lessons from our conversation"
# Type 'exit' when done
```

## 🚀 Quick Start

1. **Navigate to archon directory:**
   ```bash
   cd /home/boma/curious/archon
   ```

2. **Run the smart version:**
   ```bash
   ./claude-tmux-lessons.sh
   ```

3. **Have your conversation with Claude**

4. **Extract lessons automatically:**
   ```
   exitnow
   ```

## 📁 Output

Both scripts save conversations to:
```
/home/boma/claude-conversations/claude_tmux_TIMESTAMP.md
```

Files are automatically imported to Archon knowledge base for searching and reference.

## 🔧 Requirements

- tmux
- curl
- Python 3
- Running Archon server (port 8181)

## 💡 Key Differences

| Feature | lessons.sh | auto.sh |
|---------|------------|---------|
| **Lesson extraction** | Automatic | Manual |
| **Exit command** | `exitnow` | `exit` |
| **Intelligence** | Smart prompting | Basic capture |
| **Convenience** | Hands-free | Remember to ask |

**Recommendation:** Use `claude-tmux-lessons.sh` for automatic lesson extraction.
