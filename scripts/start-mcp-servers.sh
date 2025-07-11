#!/bin/bash

# MCP Server Startup Script
# Starts MCP servers as background processes that containers can connect to

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MCP_SERVERS_DIR="$PROJECT_ROOT/mcp-servers"
LOGS_DIR="$PROJECT_ROOT/logs/mcp-servers"

# Create necessary directories
mkdir -p "$LOGS_DIR"
mkdir -p "$MCP_SERVERS_DIR"

# Function to check if port is already in use
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "Port $port is already in use"
        return 1
    fi
    return 0
}

# Function to start MCP server with stdio transport
start_mcp_server() {
    local server_name=$1
    local server_path=$2
    local env_vars=$3
    local port=$4
    local python_path=${5:-python3}
    
    echo "Starting MCP server: $server_name"
    
    # Check if port is available
    if ! check_port $port; then
        echo "Warning: Port $port already in use for $server_name"
        return 1
    fi
    
    # Create server-specific log directory
    local server_log_dir="$LOGS_DIR/$server_name"
    mkdir -p "$server_log_dir"
    
    # Start server with environment variables
    cd "$(dirname "$server_path")"
    
    # Set up environment
    export LOGS_DIR="$server_log_dir"
    if [ -n "$env_vars" ]; then
        eval "export $env_vars"
    fi
    
    # Start the server and redirect output to log files
    nohup "$python_path" "$server_path" \
        >"$server_log_dir/stdout.log" \
        2>"$server_log_dir/stderr.log" &
    
    local pid=$!
    echo $pid > "$server_log_dir/server.pid"
    
    echo "Started $server_name (PID: $pid) using $python_path"
    echo "Logs: $server_log_dir/"
    
    # Give server time to start
    sleep 2
    
    # Check if process is still running
    if ! kill -0 $pid 2>/dev/null; then
        echo "Error: $server_name failed to start"
        cat "$server_log_dir/stderr.log"
        return 1
    fi
    
    return 0
}

# Function to stop all MCP servers
stop_all_servers() {
    echo "Stopping all MCP servers..."
    
    for pid_file in "$LOGS_DIR"/*/server.pid; do
        if [ -f "$pid_file" ]; then
            local pid=$(cat "$pid_file")
            local server_name=$(basename "$(dirname "$pid_file")")
            
            echo "Stopping $server_name (PID: $pid)"
            
            if kill -0 $pid 2>/dev/null; then
                kill $pid
                # Wait for graceful shutdown
                sleep 2
                
                # Force kill if still running
                if kill -0 $pid 2>/dev/null; then
                    echo "Force killing $server_name"
                    kill -9 $pid
                fi
            fi
            
            rm -f "$pid_file"
        fi
    done
    
    echo "All MCP servers stopped"
}

# Function to check server status
check_status() {
    echo "MCP Server Status:"
    echo "=================="
    
    for pid_file in "$LOGS_DIR"/*/server.pid; do
        if [ -f "$pid_file" ]; then
            local pid=$(cat "$pid_file")
            local server_name=$(basename "$(dirname "$pid_file")")
            
            if kill -0 $pid 2>/dev/null; then
                echo "✓ $server_name (PID: $pid) - RUNNING"
            else
                echo "✗ $server_name (PID: $pid) - STOPPED"
                rm -f "$pid_file"
            fi
        fi
    done
    
    if [ ! -f "$LOGS_DIR"/*/server.pid ]; then
        echo "No MCP servers found"
    fi
}

# Main command handling
case "${1:-start}" in
    start)
        echo "Starting MCP servers..."
        
        # Stop any existing servers first
        stop_all_servers
        
        # Start idigitesting-mcp server if available
        IDIGITESTING_MCP_DIR="/Users/jawillia/dev/drm/tooling/rm-utilities/idigitesting-mcp"
        IDIGITESTING_MCP_PATH="$IDIGITESTING_MCP_DIR/server.py"
        
        if [ -f "$IDIGITESTING_MCP_PATH" ]; then
            echo "Setting up idigitesting-mcp virtual environment..."
            
            # Ensure venv exists and is set up
            if [ ! -d "$IDIGITESTING_MCP_DIR/venv" ]; then
                cd "$IDIGITESTING_MCP_DIR"
                python3 -m venv venv
                source venv/bin/activate
                pip install -r requirements.txt
                cd - > /dev/null
            fi
            
            # Set up environment variables for idigitesting-mcp  
            IDIGITESTING_ENV="IDIGITESTING_DIR=/Users/jawillia/dev/drm/idigitesting"
            IDIGITESTING_ENV="$IDIGITESTING_ENV IDIGIUTILS_DIR=/Users/jawillia/dev/drm/tooling/idigiutils"
            IDIGITESTING_ENV="$IDIGITESTING_ENV EDPSIMLIB_DIR=/Users/jawillia/dev/drm/tooling/edpsimlib"
            
            # Use the venv python
            IDIGITESTING_MCP_PYTHON="$IDIGITESTING_MCP_DIR/venv/bin/python"
            
            start_mcp_server "idigitesting-mcp" "$IDIGITESTING_MCP_PATH" "$IDIGITESTING_ENV" 3001 "$IDIGITESTING_MCP_PYTHON"
        else
            echo "Warning: idigitesting-mcp server not found at $IDIGITESTING_MCP_PATH"
        fi
        
        echo ""
        check_status
        ;;
        
    stop)
        stop_all_servers
        ;;
        
    restart)
        stop_all_servers
        sleep 1
        "$0" start
        ;;
        
    status)
        check_status
        ;;
        
    logs)
        if [ -n "$2" ]; then
            # Show logs for specific server
            local server_name="$2"
            local log_dir="$LOGS_DIR/$server_name"
            
            if [ -d "$log_dir" ]; then
                echo "=== $server_name stdout ==="
                tail -f "$log_dir/stdout.log" &
                echo "=== $server_name stderr ==="
                tail -f "$log_dir/stderr.log"
            else
                echo "Server $server_name not found"
                exit 1
            fi
        else
            echo "Available servers:"
            ls -1 "$LOGS_DIR" 2>/dev/null || echo "No servers found"
            echo ""
            echo "Usage: $0 logs <server-name>"
        fi
        ;;
        
    *)
        echo "Usage: $0 {start|stop|restart|status|logs [server-name]}"
        echo ""
        echo "Commands:"
        echo "  start    - Start all MCP servers"
        echo "  stop     - Stop all MCP servers" 
        echo "  restart  - Restart all MCP servers"
        echo "  status   - Show server status"
        echo "  logs     - Show available servers or tail logs for specific server"
        exit 1
        ;;
esac