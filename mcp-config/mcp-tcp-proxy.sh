#!/bin/bash

# MCP TCP Proxy Script
# Bridges stdio to TCP connection for MCP servers running on Docker host

set -e

# Default configuration
HOST="${MCP_HOST:-host.docker.internal}"
PORT="${MCP_PORT:-3001}"
SERVER_NAME="${MCP_SERVER_NAME:-unknown}"

# Function to log messages to stderr (Claude Code ignores stderr from MCP servers)
log() {
    echo "[mcp-proxy:$SERVER_NAME] $*" >&2
}

# Function to test connectivity
test_connection() {
    if nc -z "$HOST" "$PORT" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Main proxy function
run_proxy() {
    log "Starting TCP proxy: $HOST:$PORT"
    
    # Test connection first
    if ! test_connection; then
        log "ERROR: Cannot connect to $HOST:$PORT"
        log "Make sure MCP server is running on the host"
        exit 1
    fi
    
    log "Connection test passed, starting proxy"
    
    # Use socat to bridge stdio to TCP
    # -d for debugging (goes to stderr)
    # -v for verbose (goes to stderr)
    # Remove these flags in production if logs get too noisy
    exec socat -d -v STDIO TCP:"$HOST":"$PORT"
}

# Handle signals gracefully
trap 'log "Proxy shutting down"; exit 0' SIGTERM SIGINT

# Run the proxy
run_proxy