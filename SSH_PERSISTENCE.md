# SSH Persistence Setup

This setup provides persistent SSH connections with modal local/remote switching for Ghostty terminal.

## Features

- **Persistent SSH connections** - No repeated authentication
- **Auto-reconnection** - Handles network drops gracefully  
- **Modal switching** - Easy toggle between local and remote work
- **Visual indicators** - Know which mode you're in
- **Keybindings** - Quick access to new tabs/panes

## Setup

1. Run the setup script:
   ```bash
   ./setup-ssh-persistence.sh
   ```

2. The system is pre-configured to use `coder.hammer-default` as your remote host.
   
   If you need a different host, set it:
   ```bash
   export REMOTE_HOST='user@hostname'
   ```

3. To make a different host permanent:
   ```bash
   echo 'export REMOTE_HOST="user@hostname"' >> ~/.zshrc
   ```

## Usage

### Basic Commands

- `remote` - Switch to remote mode and connect
- `local` - Switch back to local mode  
- `ssh-status` - Check connection status
- `ssh-reconnect` - Force reconnect if needed

### Workflow

1. **Start remote work:**
   ```bash
   remote
   ```

2. **Open new tabs/panes:**
   - Use `Cmd+Shift+R` - automatically connects to remote
   - Or just open new tab normally - will auto-connect in remote mode

3. **Switch to local work:**
   ```bash
   local
   ```

4. **New tabs are now local:**
   - Use `Cmd+Shift+L` for explicit local tabs

### How It Works

- **SSH ControlMaster** keeps one persistent connection alive
- All new SSH sessions reuse this connection (no re-authentication)
- Connection persists for 10 minutes after last use
- Auto-reconnection if connection drops
- Mode switching changes behavior of new tabs

### Troubleshooting

- **Connection stuck?** Use `ssh-reconnect`
- **Check status:** Use `ssh-status`
- **Reset everything:** 
  ```bash
  ssh -O exit $REMOTE_HOST  # Kill master connection
  remote                    # Reconnect
  ```

### Configuration Files Modified

- `~/.ssh/config` - Added ControlMaster settings
- `.config/ghostty/config` - Added keybindings
- `.zshrc` - Added SSH management functions

## Benefits

✅ No more repeated SSH authentication  
✅ Survives network interruptions  
✅ Fast new tab/pane creation  
✅ Easy mode switching  
✅ Visual mode indicators  
✅ Compatible with Ghostty and OpenCode  