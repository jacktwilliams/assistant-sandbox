FROM ubuntu:24.04

# Update system
RUN apt update && apt upgrade -y

# Install essential tools
RUN apt install -y curl git ripgrep nano wget sudo gosu

# Install Node.js 24 (Latest LTS)
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && \
    apt install -y nodejs

# Install Claude Code globally for all users
RUN npm install -g @anthropic-ai/claude-code

# Create non-root user for Claude execution
# Using 1001 as default to avoid conflicts with ubuntu user (usually 1000)
ENV CLAUDE_USER=claude \
    CLAUDE_UID=1001 \
    CLAUDE_GID=1001 \
    CLAUDE_HOME=/home/claude

RUN groupadd -g "$CLAUDE_GID" "$CLAUDE_USER" && \
    useradd -u "$CLAUDE_UID" -g "$CLAUDE_GID" -m -s /bin/bash "$CLAUDE_USER" && \
    echo "$CLAUDE_USER ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/$CLAUDE_USER" && \
    chmod 440 "/etc/sudoers.d/$CLAUDE_USER"

# Copy entrypoint script and make executable
COPY entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Set entrypoint to handle permissions and user switch
ENTRYPOINT ["/docker-entrypoint.sh"]

# Default command
CMD ["/bin/bash"]