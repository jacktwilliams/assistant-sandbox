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

## DNS Filtering Configuration
- Uses dnsmasq for DNS filtering in Docker container setup
- Configuration file: Local `dnsmasq.conf` is mounted to container's `/etc/dnsmasq.conf`
- Restricted containers (restricted-sandbox, workspace1-claude) use custom DNS server at 172.22.0.10
- To update config: Edit local `dnsmasq.conf` file, then run `docker-compose restart dns`
- View logs: `docker-compose logs dns`
- Current allowed domains: anthropic.com, googleapis.com, google.com, npmjs.org
- All other domains are blocked by default (no-resolv with specific server entries)
- To check DNS queries: `docker-compose logs dns` (queries are logged due to log-queries setting)
- Blocked domains show "config error is REFUSED" in logs
- Allowed domains show "forwarded" and "reply" in logs