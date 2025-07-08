# Claude Code CLI Docker Container

## Project Overview
This project sets up a Docker container for running Claude Code CLI with OAuth authentication.

## Current Status
- Docker container builds successfully with Ubuntu 24.04, Node.js 24, and Claude CLI
- Container runs as claude user (UID 1001) for security

## Commit Guidelines
- Keep commit messages under 3 sentences
- Use prose only, no bullet points or technical details
- Focus on the "why" rather than the "what"

## SQUID Proxy Configuration
- SQUID runs as a Docker container in docker-compose setup
- Configuration file: Local `squid.conf` is mounted to container's `/etc/squid/squid.conf`
- To update config: Edit local `squid.conf` file, then run `docker-compose restart squid`
- View logs: `docker-compose logs squid`
- Clear logs: `docker-compose exec squid sh -c "truncate -s 0 /var/log/squid/access.log && truncate -s 0 /var/log/squid/cache.log"`
- Check denied domains: `docker-compose logs squid | grep "TCP_DENIED" | grep "CONNECT" | sed 's/.*CONNECT //' | cut -d':' -f1 | sort | uniq -c`
- Validate config: `docker-compose exec squid squid -k parse`
- Current allowed domains in ACL: .github.com, .npmjs.org, .pypi.org, .python.org, .ubuntu.com, .google.com, .anthropic.com, .googleapis.com, facebook.com