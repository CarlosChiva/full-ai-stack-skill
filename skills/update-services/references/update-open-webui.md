---
name: "Update Open-WebUI"
description: "Manual steps to update the Open-WebUI Docker container with various configuration options."
tags: [open-webui, update, docker, container, configuration]
---

# Skill: Updating Open-WebUI Service

Follow these steps to update the Open-WebUI service manually without using an automated script.


## Step 1: Pull the Latest Image

Download the latest version of the Open-WebUI image:

```bash
docker pull ghcr.io/open-webui/open-webui:main
```


## Step 2: Ask User About Configuration

Before recreating the container, ask the user:

> "Would you like to customize the default container configuration (port, data persistence, network mode)?"


## Step 3: Stop and Remove the Old Container

If the user agrees or skips this step, stop and remove the existing container:

```bash
docker stop open-webui
docker rm open-webui
```


## Step 4: Choose a Startup Configuration

Present these options to the user:

### Default Configuration (Exposed on port 8080)

Most common setup. Accessible at `http://localhost:8080`.

```bash
docker run -d -p 8080:8080 --name open-webui --restart always -v open-webui:/app/backend/data ghcr.io/open-webui/open-webui:main
```

### Host Network Mode (No Port Mapping)

Uses the host network directly. Best for maximum performance.

```bash
docker run -d --network=host --name open-webui --restart always -v open-webui:/app/backend/data ghcr.io/open-webui/open-webui:main
```

*Accessible at `http://localhost:8080`.*

### Custom Port Configuration

Map to a different host port (e.g., 3000).

```bash
docker run -d -p 3000:8080 --name open-webui --restart always -v open-webui:/app/backend/data ghcr.io/open-webui/open-webui:main
```

*Accessible at `http://localhost:3000`.*

### With Environment Variables

Set additional variables like `OLLAMA_BASE_URL` to connect to a specific Ollama instance:

```bash
docker run -d -p 8080:8080 --name open-webui --restart always \
  -v open-webui:/app/backend/data \
  -e OLLAMA_BASE_URL=http://localhost:11434 \
  -e WEBUI_SECRET_KEY=$(openssl rand -hex 32) \
  ghcr.io/open-webui/open-webui:main
```

**Other useful environment variables:**

- **OLLAMA_BASE_URL** — URL of the Ollama server (e.g., `http://localhost:11434`)
- **WEBUI_SECRET_KEY** — Secret key for session authentication
- **ENABLE_OLLAMA_SERVER** — Set to `true` to run a built-in Ollama server (default: `false`)


## Step 5: Verify the Update

Check that the container is running:

```bash
docker ps --filter name=open-webui
```

View the container logs:

```bash
docker logs open-webui
```


## Complete Example Flow

Updating with default configuration:

```bash
# 1. Pull latest image
docker pull ghcr.io/open-webui/open-webui:main

# 2. Stop and remove old container
docker stop open-webui
docker rm open-webui

# 3. Run new container on port 8080
docker run -d -p 8080:8080 --name open-webui --restart always -v open-webui:/app/backend/data ghcr.io/open-webui/open-webui:main

# 4. Verify
docker ps --filter name=open-webui
docker logs open-webui
```
 

## Best Practices

- Always run `docker ps --filter name=open-webui` after updating to confirm the container is healthy.
- Keep the named volume `open-webui` persistent — do not remove it, or you will lose all user data.
- Use `WEBUI_SECRET_KEY` in production to secure the web UI.
- Use `ENABLE_OLLAMA_SERVER=true` only if you want Open-WebUI to manage an embedded Ollama instance.
- Use `--network=host` mode when running on Linux for better performance (no NAT overhead).
