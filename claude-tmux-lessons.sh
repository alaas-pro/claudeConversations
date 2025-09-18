#!/bin/bash
# Claude tmux with automatic lesson extraction using send-keys

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SESSION_NAME="claude_${TIMESTAMP}"
FINAL_FILE="/home/User/claude-conversations/claude_tmux_${TIMESTAMP}.md"

mkdir -p "/home/User/claude-conversations"

echo "🚀 Starting Claude with automatic lesson extraction..."
echo "📝 When you type 'exitnow', lessons will be extracted automatically"
echo ""

# Start tmux session in detached mode
tmux new-session -d -s "$SESSION_NAME" -c "$(pwd)"
tmux send-keys -t "$SESSION_NAME" "claude" Enter

# Set up a monitor for the exit command
# Create a wrapper that watches for 'exitnow' command
tmux send-keys -t "$SESSION_NAME" "alias exitnow='echo \"Extracting lessons...\"; exit'" Enter

# Attach to the session
tmux attach-session -t "$SESSION_NAME"

# After detaching, check if user wants lessons
echo ""
read -p "Extract lessons before saving? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Send lesson extraction command to Claude if still running
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo "📝 Requesting lesson extraction..."
        tmux send-keys -t "$SESSION_NAME" "Please extract key lessons from our conversation. Focus on technical problems solved, insights gained, patterns learned, and mistakes to avoid." Enter
        sleep 5  # Give Claude time to respond
        tmux send-keys -t "$SESSION_NAME" "exit" Enter
        sleep 2
    fi
fi

# Capture the session
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    tmux capture-pane -t "$SESSION_NAME" -p -S - > "$FINAL_FILE.raw"
    tmux kill-session -t "$SESSION_NAME" 2>/dev/null
fi

# Process the captured content (rest remains the same as original)
if [ -f "$FINAL_FILE.raw" ]; then
    python3 -c "
import re
with open('$FINAL_FILE.raw', 'r') as f:
    lines = f.readlines()

conversation = []
in_response = False
in_input = False

for line in lines:
    line = line.rstrip()
    if line.startswith('> '):
        conversation.append(line)
        in_response = False
        in_input = True
    elif line.startswith('● '):
        conversation.append(line)
        in_response = True
        in_input = False
    elif in_input and line.strip() and not line.startswith('●'):
        conversation.append(line)
    elif in_response and line.strip():
        conversation.append(line)
        
    if in_input and (not line.strip() or line.startswith('●')):
        in_input = False

with open('$FINAL_FILE.tmp', 'w') as f:
    f.write('\n'.join(conversation))
"
fi

# Create final file
cat > "$FINAL_FILE" << EOF
# Claude Code Conversation  
**Session:** $(date '+%Y-%m-%d %H:%M:%S')

## Conversation

EOF

if [ -f "$FINAL_FILE.tmp" ]; then
    cat "$FINAL_FILE.tmp" >> "$FINAL_FILE"
    rm -f "$FINAL_FILE.tmp"
fi

rm -f "$FINAL_FILE.raw"

# Import to Archon
echo "🔄 Importing to Archon..."
if command -v curl >/dev/null 2>&1 && [ -f "$FINAL_FILE" ]; then
    FILENAME=$(basename "$FINAL_FILE")
    DOCKER_PATH="/root/claude-conversations/$FILENAME"
    
    RESPONSE=$(curl -s -X POST http://localhost:8181/api/conversations/import \
        -H "Content-Type: application/json" \
        -d "{\"file_path\": \"$DOCKER_PATH\", \"extract_lessons\": true}" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$RESPONSE" ]; then
        SUCCESS=$(echo "$RESPONSE" | python3 -c "import sys, json; data = json.load(sys.stdin); print(data.get('success', False))" 2>/dev/null || echo "false")
        if [ "$SUCCESS" = "True" ]; then
            echo "✅ Imported to Archon successfully"
        fi
    fi
fi

echo "📖 Saved to: $FINAL_FILE"
