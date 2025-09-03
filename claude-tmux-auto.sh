
# Attach to session
tmux attach-session -t "$SESSION_NAME"

# Create final file with header
cat > "$FINAL_FILE" << EOF
# Claude Code Conversation  
**Session:** $(date '+%Y-%m-%d %H:%M:%S')

## Conversation

EOF

# Debug: Show what was captured
echo "🔍 Debug info:"
if [ -f "$FINAL_FILE.raw" ]; then
    echo "Raw capture file size: $(wc -l < "$FINAL_FILE.raw") lines"
    echo "First 10 lines of raw capture:"
    head -10 "$FINAL_FILE.raw"
    echo "Lines containing > or ●:"
    grep -E "(>|●)" "$FINAL_FILE.raw" || echo "No lines with > or ●"
    rm -f "$FINAL_FILE.raw"
fi

# Add captured conversation
if [ -f "$FINAL_FILE.tmp" ]; then
    cat "$FINAL_FILE.tmp" >> "$FINAL_FILE"
    rm -f "$FINAL_FILE.tmp"
    echo "✅ Filtered conversation added"
else
    echo "❌ No filtered conversation found"
    echo "No conversation captured" >> "$FINAL_FILE"
fi

echo "📖 Final file:"
cat "$FINAL_FILE"

# Import to mcp
echo ""
echo "🔄 Importing to Archon..."
if command -v curl >/dev/null 2>&1 && [ -f "$FINAL_FILE" ]; then
    # Docker sees the file at /root/claude-conversations/ due to volume mount
    FILENAME=$(basename "$FINAL_FILE")
    DOCKER_PATH="/root/claude-conversations/$FILENAME"
    TITLE="Claude Session $(date '+%Y-%m-%d %H:%M')"
    
    # Use file_path since we have the volume mount
    RESPONSE=$(curl -s -X POST http://localhost:8181/api/conversations/import \
        -H "Content-Type: application/json" \
        -d "{\"file_path\": \"$DOCKER_PATH\", \"title\": \"$TITLE\", \"extract_lessons\": true}" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$RESPONSE" ]; then
        SUCCESS=$(echo "$RESPONSE" | python3 -c "import sys, json; data = json.load(sys.stdin); print(data.get('success', False))" 2>/dev/null || echo "false")
        if [ "$SUCCESS" = "True" ]; then
            echo "✅ Imported to Archon successfully"
            echo "$RESPONSE" | python3 -c "import sys, json; data = json.load(sys.stdin); print(f\"  Conversation ID: {data.get('conversation_id', 'unknown')}\"); print(f\"  Lessons extracted: {data.get('lessons_extracted', 0)}\")" 2>/dev/null || true
        else
            echo "⚠️  Archon import failed:"
            echo "$RESPONSE" | python3 -c "import sys, json; data = json.load(sys.stdin); print(f\"  Error: {data.get('error', 'Unknown error')}\")" 2>/dev/null || echo "  Could not parse error"
        fi
    else
        echo "⚠️  Archon server may not be running (port 8181)"
    fi
else
    echo "⚠️  curl not available or file not found - cannot import to Archon"
fi
