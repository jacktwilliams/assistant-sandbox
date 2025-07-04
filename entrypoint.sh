#!/bin/bash
set -e

# Environment variables
CLAUDE_USER="${CLAUDE_USER:-claude}"
CLAUDE_HOME="${CLAUDE_HOME:-/home/claude}"

# Debug: Create a debug file to confirm entrypoint is running
echo "Entrypoint running at $(date)" > /tmp/entrypoint-debug.log
echo "Running as user: $(whoami) (UID=$(id -u))" >> /tmp/entrypoint-debug.log
echo "CLAUDE_USER: $CLAUDE_USER" >> /tmp/entrypoint-debug.log
echo "CLAUDE_HOME: $CLAUDE_HOME" >> /tmp/entrypoint-debug.log

# Create symlinks for Claude authentication files
# This allows the claude user to access auth files mounted to /root/

# Ensure claude can traverse /root
chmod 755 /root 2>/dev/null || true

# Handle .claude directory
if [ -d "/root/.claude" ]; then
    echo "Found /root/.claude directory" >> /tmp/entrypoint-debug.log
    chmod -R 755 /root/.claude 2>/dev/null || true
    ln -sfn /root/.claude "$CLAUDE_HOME/.claude"
    chown -h claude:claude "$CLAUDE_HOME/.claude"
    echo "Created symlink: $CLAUDE_HOME/.claude -> /root/.claude" >> /tmp/entrypoint-debug.log
else
    echo "No /root/.claude directory found" >> /tmp/entrypoint-debug.log
fi

# Handle .claude.json file
if [ -f "/root/.claude.json" ]; then
    echo "Found /root/.claude.json file" >> /tmp/entrypoint-debug.log
    chmod 644 /root/.claude.json 2>/dev/null || true
    ln -sfn /root/.claude.json "$CLAUDE_HOME/.claude.json"
    chown -h claude:claude "$CLAUDE_HOME/.claude.json"
    echo "Created symlink: $CLAUDE_HOME/.claude.json -> /root/.claude.json" >> /tmp/entrypoint-debug.log
else
    echo "No /root/.claude.json file found" >> /tmp/entrypoint-debug.log
fi

# Check if symlinks were created successfully
if [ -L "$CLAUDE_HOME/.claude" ]; then
    echo "Symlink $CLAUDE_HOME/.claude exists and points to $(readlink $CLAUDE_HOME/.claude)" >> /tmp/entrypoint-debug.log
fi

if [ -L "$CLAUDE_HOME/.claude.json" ]; then
    echo "Symlink $CLAUDE_HOME/.claude.json exists and points to $(readlink $CLAUDE_HOME/.claude.json)" >> /tmp/entrypoint-debug.log
fi

# Switch to claude user and execute the command
if [ "$(id -u)" = "0" ]; then
    # Running as root, switch to claude user
    echo "Switching from root to $CLAUDE_USER" >> /tmp/entrypoint-debug.log
    exec gosu "$CLAUDE_USER" "$@"
else
    # Already running as claude user
    echo "Already running as claude user" >> /tmp/entrypoint-debug.log
    exec "$@"
fi