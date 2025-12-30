# 🔧 Troubleshooting Zabbix "Unsupported item key" Error

## Problem

When running `zabbix_get` from the Zabbix server, you get:
```
ZBX_NOTSUPPORTED: Unsupported item key.
```

This means the Zabbix **agent** on the monitored host doesn't recognize the UserParameter keys.

## Root Cause

The UserParameters must be configured on the **monitored host** (where the Zabbix agent runs), not on the Zabbix server. The error indicates that:

1. The UserParameters config file doesn't exist on the monitored host
2. The Zabbix agent hasn't been restarted after configuration
3. The Zabbix agent can't find or execute the script
4. The Zabbix agent configuration isn't loading the UserParameters file

## Solution Steps

### Step 1: Verify Setup on Monitored Host

**SSH to the monitored host:**
```bash
ssh root@<MONITORED_HOST_IP>
```

> 💡 **Note:** Replace `<MONITORED_HOST_IP>` with your monitored host's IP address (configured in the `vars` file as `MONITORED_HOST_IP`).

### Step 2: Check UserParameters Config File

```bash
# Check if config file exists
cat /etc/zabbix/zabbix_agentd.conf.d/speedtest.conf
```

**Expected Output:**
```
# Speedtest UserParameters for Zabbix
UserParameter=speedtest.download,/usr/local/bin/zbx-speedtest.py speedtest.download
UserParameter=speedtest.upload,/usr/local/bin/zbx-speedtest.py speedtest.upload
...
```

**If file doesn't exist:**
- Run `sudo ./setup_zabbix.sh` on the monitored host
- Or manually create the file (see setup_zabbix.sh for content)

### Step 3: Check Script Exists and is Executable

```bash
# Check script exists
ls -l /usr/local/bin/zbx-speedtest.py

# Test script directly
/usr/local/bin/zbx-speedtest.py speedtest.download
```

**Expected Output:**
```
393.62
```

**If script doesn't exist:**
- Run `sudo ./setup_zabbix.sh` on the monitored host
- Or copy manually: `sudo cp zbx-speedtest.py /usr/local/bin/zbx-speedtest.py`

### Step 4: Check Zabbix Agent Status

```bash
# Check if agent is running
systemctl status zabbix-agent

# Or for agent2
systemctl status zabbix-agent2
```

**If agent is not running:**
```bash
sudo systemctl start zabbix-agent
# or
sudo systemctl start zabbix-agent2
```

### Step 5: Check Zabbix Agent Configuration

```bash
# Check main agent config
grep -i "Include" /etc/zabbix/zabbix_agentd.conf
# or
grep -i "Include" /etc/zabbix/zabbix_agent2.conf
```

**Should show:**
```
Include=/etc/zabbix/zabbix_agentd.conf.d/*.conf
```

**If Include directive is missing or commented:**
- Edit `/etc/zabbix/zabbix_agentd.conf` or `zabbix_agent2.conf`
- Add or uncomment: `Include=/etc/zabbix/zabbix_agentd.conf.d/*.conf`

### Step 6: Restart Zabbix Agent

```bash
# Restart agent to load new configuration
sudo systemctl restart zabbix-agent
# or
sudo systemctl restart zabbix-agent2

# Check status
sudo systemctl status zabbix-agent
```

### Step 7: Check Agent Logs

```bash
# Check for errors
sudo journalctl -u zabbix-agent -n 50 | grep -i speedtest
sudo journalctl -u zabbix-agent -n 50 | grep -i error

# Or for agent2
sudo journalctl -u zabbix-agent2 -n 50 | grep -i speedtest
```

**Look for:**
- Errors loading UserParameters
- Script execution errors
- Permission errors

### Step 8: Test from Monitored Host

**On the monitored host, test locally:**
```bash
# Test script
/usr/local/bin/zbx-speedtest.py speedtest.download

# Test as zabbix user (important!)
sudo -u zabbix /usr/local/bin/zbx-speedtest.py speedtest.download
```

**If it works locally but not from server:**
- Check firewall rules
- Check Zabbix agent is listening on port 10050
- Verify server IP is allowed in agent config

### Step 9: Test from Zabbix Server

**From Zabbix server (in container):**
```bash
# Test connection
podman exec -it zabbix-server-pgsql zabbix_get -s <MONITORED_HOST_IP> -k agent.ping

# Test speedtest metric
podman exec -it zabbix-server-pgsql zabbix_get -s <MONITORED_HOST_IP> -k speedtest.download
```

> 💡 **Note:** Replace `<MONITORED_HOST_IP>` with your monitored host's IP address (configured in the `vars` file as `MONITORED_HOST_IP`).

**If agent.ping works but speedtest.download doesn't:**
- UserParameters are not configured or not loaded
- Go back to Step 2-6

## Quick Fix Checklist

Run these commands on the **monitored host**:

```bash
# 1. Verify setup script exists
cd /opt/projects/speed-test-with-graphing
ls -l setup_zabbix.sh

# 2. Run setup (if not already done)
sudo ./setup_zabbix.sh

# 3. If agent fails to start, use the fix script
sudo ./fix_zabbix_agent_config.sh

# 4. Verify config file
cat /etc/zabbix/zabbix_agentd.conf.d/speedtest.conf

# 5. Verify script
ls -l /usr/local/bin/zbx-speedtest.py
/usr/local/bin/zbx-speedtest.py speedtest.download

# 6. Test config syntax
sudo zabbix_agentd -p -c /etc/zabbix/zabbix_agentd.conf

# 7. Restart agent
sudo systemctl restart zabbix-agent
# or
sudo systemctl restart zabbix-agent2

# 8. Check logs
sudo journalctl -u zabbix-agent -n 20
```

## Common Issues

### Issue 1: Agent2 vs Agent

**Problem:** You might be using Zabbix Agent2 instead of Agent

**Solution:**
- Check which agent is running: `systemctl status zabbix-agent*`
- Agent2 uses `/etc/zabbix/zabbix_agent2.conf.d/` instead of `zabbix_agentd.conf.d/`
- Update setup_zabbix.sh or manually copy config to correct location

### Issue 2: Script Permissions

**Problem:** Zabbix user can't execute the script

**Solution:**
```bash
sudo chmod 755 /usr/local/bin/zbx-speedtest.py
sudo chown root:root /usr/local/bin/zbx-speedtest.py
sudo -u zabbix /usr/local/bin/zbx-speedtest.py speedtest.download
```

### Issue 3: Path Issues

**Problem:** Script can't find speedtest_results.json

**Solution:**
- Verify JSON file exists: `ls -l /opt/projects/speed-test-with-graphing/speedtest_results.json`
- Check script path resolution (script should find JSON automatically)
- Test script: `/usr/local/bin/zbx-speedtest.py speedtest.download`

### Issue 4: Agent Not Loading Config

**Problem:** Agent config doesn't include the .conf.d directory or has syntax errors

**Solution (Quick Fix):**
```bash
# Use the automated fix script
cd /opt/projects/speed-test-with-graphing
sudo ./fix_zabbix_agent_config.sh
```

**Solution (Manual Fix):**
```bash
# Test config syntax first
sudo zabbix_agentd -p -c /etc/zabbix/zabbix_agentd.conf

# Edit agent config
sudo vi /etc/zabbix/zabbix_agentd.conf
# or
sudo vi /etc/zabbix/zabbix_agent2.conf

# Add or uncomment:
Include=/etc/zabbix/zabbix_agentd.conf.d/*.conf

# Test config again
sudo zabbix_agentd -p -c /etc/zabbix/zabbix_agentd.conf

# Restart agent
sudo systemctl restart zabbix-agent
```

**Note:** Use `zabbix_agentd -p` (not `-t`) to test/validate config syntax. The `-t` flag requires an item key.

## Verification

After fixing, verify from Zabbix server:

```bash
# From Zabbix server container
podman exec -it zabbix-server-pgsql zabbix_get -s <MONITORED_HOST_IP> -k agent.ping
podman exec -it zabbix-server-pgsql zabbix_get -s <MONITORED_HOST_IP> -k speedtest.download
podman exec -it zabbix-server-pgsql zabbix_get -s <MONITORED_HOST_IP> -k speedtest.upload
podman exec -it zabbix-server-pgsql zabbix_get -s <MONITORED_HOST_IP> -k speedtest.ping
```

> 💡 **Note:** Replace `<MONITORED_HOST_IP>` with your monitored host's IP address (configured in the `vars` file as `MONITORED_HOST_IP`).

**Expected:**
- `agent.ping` should return `1`
- `speedtest.*` should return numeric values (not "Unsupported")

## Still Not Working?

1. **Check agent version:**
   ```bash
   zabbix_agentd -V
   # or
   zabbix_agent2 -V
   ```

2. **Enable debug logging:**
   ```bash
   # Edit agent config
   sudo vi /etc/zabbix/zabbix_agentd.conf
   # Set: DebugLevel=4
   # Restart agent
   sudo systemctl restart zabbix-agent
   # Check logs
   sudo journalctl -u zabbix-agent -f
   ```

3. **Test UserParameter manually:**
   ```bash
   # On monitored host
   sudo -u zabbix /usr/local/bin/zbx-speedtest.py speedtest.download
   ```

4. **Verify network connectivity:**
   ```bash
   # From Zabbix server
   podman exec -it zabbix-server-pgsql telnet <MONITORED_HOST_IP> 10050
   ```
   
   > 💡 **Note:** Replace `<MONITORED_HOST_IP>` with your monitored host's IP address (configured in the `vars` file as `MONITORED_HOST_IP`).

---

**Remember:** UserParameters must be configured on the **monitored host**, not the Zabbix server!

