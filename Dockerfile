FROM ubuntu:24.04

# Update system
RUN apt update && apt upgrade -y

# Install essential tools including networking utilities for MCP communication
RUN apt install -y curl git ripgrep nano wget sudo gosu socat netcat-openbsd

# Install Node.js 24 (Latest LTS)
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && \
    apt install -y nodejs

# Install Claude Code and Gemini CLI globally for all users
RUN npm install -g @anthropic-ai/claude-code @google/gemini-cli

# Install Java 21 and Maven
RUN apt update && \
    apt install -y openjdk-21-jdk maven

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

# Copy and run personalization script if it exists
COPY . /tmp/build-context/
RUN if [ -f /tmp/build-context/personalization.sh ]; then \
        cp /tmp/build-context/personalization.sh /tmp/personalization.sh && \
        chmod +x /tmp/personalization.sh && \
        su - "$CLAUDE_USER" -c "/tmp/personalization.sh" && \
        rm /tmp/personalization.sh; \
    fi && \
    rm -rf /tmp/build-context

# Configure bash history for the claude user
RUN echo 'export HISTFILE=/home/claude/.bash_history' >> /home/claude/.bashrc && \
    echo 'export HISTSIZE=1000' >> /home/claude/.bashrc && \
    echo 'export HISTFILESIZE=2000' >> /home/claude/.bashrc && \
    echo 'shopt -s histappend' >> /home/claude/.bashrc && \
    chown claude:claude /home/claude/.bashrc

# Default command
CMD ["/bin/bash"]