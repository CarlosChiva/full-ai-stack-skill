# Skill: Updating Ollama Service

Follow these steps to update the Ollama service manually without using an automated script.

---

## Prerequisites

You need root/sudo privileges to update the Ollama service and modify its systemd unit file.

---

## Step 1: Enter Your Password

Prompt the user for their sudo password, then store it in a variable. All subsequent `sudo` commands will read from this variable using `sudo -S`.

```bash
read -rsp "Enter your sudo password: " SUDO_PASS && echo
```

> **Security note**: The password is stored in a shell variable only for the duration of this session and is never written to disk or logs.

---

## Step 2: Update Ollama

Run the official installation script to update Ollama to the latest version:

```bash
echo "$SUDO_PASS" | sudo -S curl -fsSL https://ollama.com/install.sh | sh
```

---

## Step 3: Ask User About Additional Configuration

Before editing the systemd unit file, ask the user:

> "Would you like to add any custom environment variables to the Ollama service?"

---

## Step 4: Expose Available Environment Variables

If the user says **yes**, present the list of configurable variables:

### Available Environment Variables

- **OLLAMA_MODELS**
  Directory where model files are stored.
  - *Default*: `~/.ollama/models` (Linux/Mac) or `C:\Users\<user>\.ollama\models` (Windows).
  - *Tip*: Change it to another partition if you need to save space on the main drive.

- **OLLAMA_HOST**
  IP address and port the service binds to.
  - *Default*: `127.0.0.1:11434`
  - *Usage*: Use `0.0.0.0:11434` to allow access from other devices in the local network.

- **OLLAMA_ORIGINS**
  Configures allowed HTTP origins (CORS).
  - *Usage*: Comma-separated list (e.g., `http://localhost:3000,https://mysite.com`) or `*` to allow all.

- **OLLAMA_KEEP_ALIVE**
  Time models remain loaded in memory after use.
  - *Default*: `5m` (5 minutes).
  - *Usage*: Integer (seconds), `0` (immediate unload), or negative number (never unload).

- **OLLAMA_NUM_PARALLEL**
  Number of concurrent requests Ollama can process simultaneously.
  - *Default*: `1` (Increase it to utilize better hardware).

- **OLLAMA_MAX_QUEUE**
  Maximum size of the request queue. Exceeded requests will be rejected.
  - *Default*: `512`

- **OLLAMA_MAX_LOADED_MODELS**
  Maximum number of models that can be loaded in VRAM/RAM at the same time.
  - *Default*: `1`

- **OLLAMA_DEBUG**
  Enables detailed debug logs if set to `1`.

- **CUDA_VISIBLE_DEVICES**
  Defines which Graphics Cards (GPUs) Ollama will use.
  - *Usage*: A single ID (e.g., `0`) or comma-separated IDs (e.g., `0,1`) to use multiple GPUs.

---

## Step 5: Add Environment Variables to the Systemd Unit File

For each variable the user selects, run:

```bash
echo "$SUDO_PASS" | sudo -S sed -i '/\[Install\]/i Environment="<VARIABLE_NAME>=<VALUE>"' /etc/systemd/system/ollama.service
```

### Examples

**Set OLLAMA_HOST to expose the service on the local network:**

```bash
echo "$SUDO_PASS" | sudo -S sed -i '/\[Install\]/i Environment="OLLAMA_HOST=0.0.0.0:11434"' /etc/systemd/system/ollama.service
```

**Change the models storage path:**

```bash
echo "$SUDO_PASS" | sudo -S sed -i '/\[Install\]/i Environment="OLLAMA_MODELS=/mnt/storage/models"' /etc/systemd/system/ollama.service
```

**Use specific GPUs:**

```bash
echo "$SUDO_PASS" | sudo -S sed -i '/\[Install\]/i Environment="CUDA_VISIBLE_DEVICES=0,1"' /etc/systemd/system/ollama.service
```

**Set multiple variables (run each on its own line):**

```bash
echo "$SUDO_PASS" | sudo -S sed -i '/\[Install\]/i Environment="OLLAMA_HOST=0.0.0.0:11434"' /etc/systemd/system/ollama.service
echo "$SUDO_PASS" | sudo -S sed -i '/\[Install\]/i Environment="OLLAMA_MODELS=/mnt/storage/models"' /etc/systemd/system/ollama.service
echo "$SUDO_PASS" | sudo -S sed -i '/\[Install\]/i Environment="CUDA_VISIBLE_DEVICES=0"' /etc/systemd/system/ollama.service
```

---

## Step 6: Reload and Restart the Service

After adding any environment variables, reload the systemd daemon and restart Ollama:

```bash
echo "$SUDO_PASS" | sudo -S systemctl daemon-reload
echo "$SUDO_PASS" | sudo -S systemctl restart ollama
```

---

## Verification

Check that the service is running correctly:

```bash
echo "$SUDO_PASS" | sudo -S systemctl status ollama
```

Check that environment variables are applied:

```bash
systemctl show ollama --property=Environment
```

---

## Complete Example Flow

**User wants to expose the service on LAN and use GPU 0:**

```bash
# Enter sudo password
read -rsp "Enter your sudo password: " SUDO_PASS && echo

# 1. Update Ollama
echo "$SUDO_PASS" | sudo -S curl -fsSL https://ollama.com/install.sh | sh

# 2. Add environment variables
echo "$SUDO_PASS" | sudo -S sed -i '/\[Install\]/i Environment="OLLAMA_HOST=0.0.0.0:11434"' /etc/systemd/system/ollama.service
echo "$SUDO_PASS" | sudo -S sed -i '/\[Install\]/i Environment="CUDA_VISIBLE_DEVICES=0"' /etc/systemd/system/ollama.service

# 3. Reload and restart
echo "$SUDO_PASS" | sudo -S systemctl daemon-reload
echo "$SUDO_PASS" | sudo -S systemctl restart ollama

# 4. Verify
echo "$SUDO_PASS" | sudo -S systemctl status ollama
```
 
---

## Best Practices

- Always verify changes with `systemctl show ollama --property=Environment` before relying on them.
- Use `127.0.0.1:11434` for `OLLAMA_HOST` unless remote access is explicitly needed.
- Set `CUDA_VISIBLE_DEVICES` only when you need to restrict Ollama to specific GPUs.
- Keep `OLLAMA_KEEP_ALIVE` reasonable to balance performance and memory usage.
