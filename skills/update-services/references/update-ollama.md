# Skill: Updating Ollama Service

Follow these steps to update the Ollama service using the automated script.

---

## Step 1: Request Credentials
The update script requires root/sudo privileges. 
- **Action**: Before running the script, ask the user for their root/sudo password.
- **Rule**: Do not attempt to run the script without the password.

---

## Step 2: Configure Environment Variables (Optional)
The script allows passing environment variables as arguments to configure Ollama.
- **Action**: Ask the user if they want to apply any specific configuration.
- **Available Variables**:

### 📋 List of Available Environment Variables

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

### 📋 Flow for Environment Variables Configuration:

1. **Ask the user** if they want to configure any environment variables.
2. **If YES**, present the list of available variables (see below).
3. **For each variable the user selects**:
   - Ask: "What value would you like to set for [VARIABLE_NAME]?"
   - Wait for the user's response.
   - Validate the format if possible (e.g., IP:port format for OLLAMA_HOST).
4. **Collect all selected variables** with their user-provided values.
5. **If NO**, proceed with default configuration.
6. **Once you have the configuration to launch script** ask to user before to launch script. Only run the script after of user confirmation.
---

## Step 3: Script Execution and Examples

To run the script, pass the password using `echo '[password]' | sudo -S` followed by the absolute path of the script and the environment variables as arguments.

### 📜 Execution Template
```bash
echo '[password]' | sudo -S /home/dread/.agents/skills/update-services/scripts/install_ollama.sh [ENV_VARIABLE=value]
```

### 💡 Examples

**Example 1: Update with default values (No extra parameters)**
```bash
echo 'your_password' | sudo -S /home/dread/.agents/skills/update-services/scripts/install_ollama.sh
```

**Example 2: Open access to the local network (LAN)**
```bash
echo 'your_password' | sudo -S /home/dread/.agents/skills/update-services/scripts/install_ollama.sh OLLAMA_HOST=0.0.0.0:11434
```

**Example 3: Use specific GPUs and change the models path**

```bash
echo 'your_password' | sudo -S /home/dread/.agents/skills/update-services/scripts/install_ollama.sh CUDA_VISIBLE_DEVICES=0,1 OLLAMA_MODELS=/mnt/storage/models
```

