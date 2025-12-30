# 📡 Installing the Speedtest Zabbix Template

> Step-by-step instructions for installing the Speedtest Monitoring template on your Zabbix server.

![Zabbix](https://img.shields.io/badge/zabbix-5.0+-blue)
![Template](https://img.shields.io/badge/template-ready-success)
![RHEL](https://img.shields.io/badge/RHEL-10-red)
![License](https://img.shields.io/badge/license-MIT-green)

---

## 📋 Table of Contents

- [Prerequisites](#-prerequisites)
- [Containerized Zabbix Deployments](#-containerized-zabbix-deployments)
- [Method 1: Import via Web Interface](#-method-1-import-via-web-interface-recommended)
- [Method 2: Apply Template to Host](#-method-2-apply-template-to-host)
- [Verification](#-verification)
- [Troubleshooting](#-troubleshooting)
- [Post-Installation Configuration](#-post-installation-configuration)
- [Updating the Template](#-updating-the-template)
- [Quick Reference](#-quick-reference)
- [Getting Help](#-getting-help)
- [Installation Checklist](#-installation-checklist)

---

## 📋 Prerequisites

Before installing the template, ensure you have:

1. **Zabbix Server** - Version 5.0 or higher
2. **Zabbix Web Interface** - Access with admin privileges
3. **Template File** - `zabbix_template_speedtest.xml` from this repository
4. **Monitored Host** - A host with the Zabbix agent configured and speedtest integration set up

### Verify Host Setup

On your monitored host, verify the Zabbix integration is working:

```bash
# Test from Zabbix server
zabbix_get -s <hostname> -k speedtest.download
zabbix_get -s <hostname> -k speedtest.upload
zabbix_get -s <hostname> -k speedtest.ping
```

**Expected Output:**
```
393.62
41.33
26.01
```

If these commands return values (not "Not supported"), the host is ready for the template.

---

## 🐳 Containerized Zabbix Deployments

> **Note:** These instructions are for **RHEL 10** deployments using **Podman**. For Docker deployments, replace `podman` with `docker` in all commands.

If your Zabbix server is running in a container (Podman, Docker, Kubernetes, etc.), the commands and procedures are slightly different.

### 🐳 Podman Deployment (RHEL 10)

> **RHEL 10 Note:** RHEL 10 uses Podman by default instead of Docker. All commands use `podman` instead of `docker`.

#### Accessing Zabbix Server Container

**Find the container name:**
```bash
podman ps | grep zabbix
```

**Access the container:**
```bash
# Access Zabbix server container
podman exec -it <zabbix-server-container-name> /bin/bash

# Or if using podman-compose (if installed)
podman-compose exec zabbix-server /bin/bash
```

> 💡 **Note:** On RHEL 10, use `podman` instead of `docker`. Podman is rootless by default, so you may not need `sudo`.

#### Running zabbix_get from Container

**Option 1: Execute command directly**
```bash
# From host machine (RHEL 10)
podman exec <zabbix-server-container-name> zabbix_get -s <hostname> -k speedtest.download

# Or with podman-compose (if installed)
podman-compose exec zabbix-server zabbix_get -s <hostname> -k speedtest.download
```

**Option 2: Access container shell first**
```bash
# Enter container
podman exec -it <zabbix-server-container-name> /bin/bash

# Then run commands inside container
zabbix_get -s <hostname> -k speedtest.download
zabbix_get -s <hostname> -k speedtest.upload
zabbix_get -s <hostname> -k speedtest.ping
```

#### Downloading Template File in Container

**Option 1: Download inside container**
```bash
# Enter container
podman exec -it <zabbix-server-container-name> /bin/bash

# Download template
wget https://raw.githubusercontent.com/christopherpaquin/speed-test-with-graphing/main/zabbix_template_speedtest.xml

# Or use curl
curl -O https://raw.githubusercontent.com/christopherpaquin/speed-test-with-graphing/main/zabbix_template_speedtest.xml
```

**Option 2: Copy from host to container**
```bash
# From host machine (RHEL 10), copy file into container
podman cp zabbix_template_speedtest.xml <zabbix-server-container-name>:/tmp/

# Then access container and move file
podman exec -it <zabbix-server-container-name> /bin/bash
mv /tmp/zabbix_template_speedtest.xml /tmp/
```

**Option 3: Use volume mount**
If you have a volume mounted, copy the file to the mounted directory:
```bash
# Copy to mounted volume directory
cp zabbix_template_speedtest.xml /path/to/mounted/volume/

# File will be accessible inside container at mounted path
```

#### Accessing Zabbix Web Interface

The web interface is typically accessible via:
- **Port mapping:** `http://localhost:<mapped-port>/zabbix`
- **Container network:** `http://<container-ip>/zabbix`
- **Podman-compose:** Check your `podman-compose.yml` or `docker-compose.yml` for port mappings

**Find the port:**
```bash
podman ps | grep zabbix
# Look for port mapping like: 0.0.0.0:8080->80/tcp
```

#### Checking Zabbix Server Logs (Container)

```bash
# View logs (RHEL 10 / Podman)
podman logs <zabbix-server-container-name>

# Follow logs
podman logs -f <zabbix-server-container-name>

# Or with podman-compose (if installed)
podman-compose logs zabbix-server
podman-compose logs -f zabbix-server
```

> 💡 **RHEL 10 Note:** Podman logs work similarly to Docker, but Podman is rootless by default, so you typically don't need `sudo`.

### Kubernetes Deployment

#### Accessing Zabbix Server Pod

**Find the pod:**
```bash
kubectl get pods -n <namespace> | grep zabbix-server
```

**Access the pod:**
```bash
# Access Zabbix server pod
kubectl exec -it <zabbix-server-pod-name> -n <namespace> -- /bin/bash

# Or if using default namespace
kubectl exec -it <zabbix-server-pod-name> -- /bin/bash
```

#### Running zabbix_get from Pod

**Option 1: Execute command directly**
```bash
# From host machine
kubectl exec <zabbix-server-pod-name> -n <namespace> -- zabbix_get -s <hostname> -k speedtest.download
```

**Option 2: Access pod shell first**
```bash
# Enter pod
kubectl exec -it <zabbix-server-pod-name> -n <namespace> -- /bin/bash

# Then run commands inside pod
zabbix_get -s <hostname> -k speedtest.download
zabbix_get -s <hostname> -k speedtest.upload
zabbix_get -s <hostname> -k speedtest.ping
```

#### Downloading Template File in Pod

**Option 1: Download inside pod**
```bash
# Enter pod
kubectl exec -it <zabbix-server-pod-name> -n <namespace> -- /bin/bash

# Download template
wget https://raw.githubusercontent.com/christopherpaquin/speed-test-with-graphing/main/zabbix_template_speedtest.xml

# Or use curl
curl -O https://raw.githubusercontent.com/christopherpaquin/speed-test-with-graphing/main/zabbix_template_speedtest.xml
```

**Option 2: Copy from host to pod**
```bash
# From host machine, copy file into pod
kubectl cp zabbix_template_speedtest.xml <namespace>/<zabbix-server-pod-name>:/tmp/

# Then access pod and verify
kubectl exec -it <zabbix-server-pod-name> -n <namespace> -- ls -l /tmp/zabbix_template_speedtest.xml
```

**Option 3: Use ConfigMap (Recommended for Kubernetes)**
```bash
# Create ConfigMap from template file
kubectl create configmap zabbix-speedtest-template \
  --from-file=zabbix_template_speedtest.xml \
  -n <namespace>

# Mount ConfigMap in Zabbix server deployment
# Edit your deployment YAML to mount the ConfigMap
# Then access file at mounted path inside pod
```

#### Accessing Zabbix Web Interface (Kubernetes)

**Find the service:**
```bash
kubectl get svc -n <namespace> | grep zabbix
```

**Access via port-forward:**
```bash
# Forward port to local machine
kubectl port-forward svc/<zabbix-service-name> 8080:80 -n <namespace>

# Then access: http://localhost:8080/zabbix
```

**Access via NodePort or LoadBalancer:**
```bash
# Check service type and external IP
kubectl get svc <zabbix-service-name> -n <namespace>

# Access via external IP or NodePort
# http://<external-ip>/zabbix
# or
# http://<node-ip>:<nodeport>/zabbix
```

#### Checking Zabbix Server Logs (Kubernetes)

```bash
# View logs
kubectl logs <zabbix-server-pod-name> -n <namespace>

# Follow logs
kubectl logs -f <zabbix-server-pod-name> -n <namespace>

# View logs from all containers in pod
kubectl logs <zabbix-server-pod-name> -n <namespace> --all-containers=true
```

### Container-Specific Considerations

#### File Paths

In containers, file paths may differ:
- **Config files:** May be in `/etc/zabbix/` or mounted volumes
- **Log files:** May be in `/var/log/zabbix/` or stdout/stderr
- **Data files:** May be in persistent volumes

**Find actual paths:**
```bash
# Docker
docker exec <container-name> find / -name "zabbix_server.conf" 2>/dev/null

# Kubernetes
kubectl exec <pod-name> -n <namespace> -- find / -name "zabbix_server.conf" 2>/dev/null
```

#### Persistent Storage

Ensure template imports persist across container restarts:
- **Docker:** Use named volumes or bind mounts
- **Kubernetes:** Use PersistentVolumes (PV) and PersistentVolumeClaims (PVC)

#### Network Access

Containers need network access to:
- Monitored hosts (for zabbix_get)
- Zabbix database (if separate container)
- External repositories (for downloading templates)

**Test connectivity:**
```bash
# From container/pod
ping <monitored-host-ip>
telnet <monitored-host-ip> 10050  # Zabbix agent port
```

### Quick Reference: Container Commands

**Podman (RHEL 10):**
```bash
# Execute command
podman exec <container> <command>

# Access shell
podman exec -it <container> /bin/bash

# Copy file
podman cp <file> <container>:/path/

# View logs
podman logs <container>

# List containers
podman ps

# Start/stop container
podman start <container>
podman stop <container>
```

**Docker (Alternative):**
```bash
# Execute command
docker exec <container> <command>

# Access shell
docker exec -it <container> /bin/bash

# Copy file
docker cp <file> <container>:/path/

# View logs
docker logs <container>
```

> ⚠️ **RHEL 10:** Use `podman` instead of `docker`. Podman is the default container runtime on RHEL 10.

**Kubernetes:**
```bash
# Execute command
kubectl exec <pod> -n <namespace> -- <command>

# Access shell
kubectl exec -it <pod> -n <namespace> -- /bin/bash

# Copy file
kubectl cp <file> <namespace>/<pod>:/path/

# View logs
kubectl logs <pod> -n <namespace>
```

---

## 📥 Method 1: Import via Web Interface (Recommended)

This is the easiest method and works for most users.

### Step 1: Download the Template File

**Option A: From GitHub Repository**
1. Navigate to: `https://github.com/christopherpaquin/speed-test-with-graphing`
2. Click on `zabbix_template_speedtest.xml`
3. Click **Raw** button to view the raw file
4. Right-click and select **Save As** (or use Ctrl+S / Cmd+S)
5. Save the file to your local computer

**Option B: Clone the Repository**
```bash
git clone https://github.com/christopherpaquin/speed-test-with-graphing.git
cd speed-test-with-graphing
# Template file is at: zabbix_template_speedtest.xml
```

**Option C: Download via Command Line**

**For standard (non-containerized) Zabbix:**
```bash
# From Zabbix server or any Linux machine
wget https://raw.githubusercontent.com/christopherpaquin/speed-test-with-graphing/main/zabbix_template_speedtest.xml
```

**For containerized Zabbix:**
- See [Containerized Zabbix Deployments](#-containerized-zabbix-deployments) section above for container-specific download instructions

### Step 2: Access Zabbix Web Interface

1. Open your web browser
2. Navigate to your Zabbix server URL (e.g., `http://your-zabbix-server/zabbix`)
3. Log in with an account that has **Admin** or **Super Admin** privileges

### Step 3: Import the Template

1. In the Zabbix web interface, go to:
   - **Configuration** → **Templates**
   
2. Click the **Import** button (usually in the top-right corner)

3. Click **Choose File** or **Browse** button

4. Select the `zabbix_template_speedtest.xml` file you downloaded

5. Review the import preview:
   - You should see "Speedtest Monitoring" template listed
   - Check that it shows items, triggers, and graphs

6. Click **Import** button

7. Wait for the import to complete - you should see a success message:
   ```
   Template imported successfully
   ```

### Step 4: Verify Template Import

1. Stay in **Configuration** → **Templates**
2. Use the search/filter box and type: `Speedtest`
3. You should see **Speedtest Monitoring** in the list
4. Click on it to view details:
   - Should show 11 items
   - Should show 7 triggers
   - Should show 4 graphs

---

## 🔗 Method 2: Apply Template to Host

Now that the template is imported, you need to link it to your monitored host.

### Step 1: Navigate to Host Configuration

1. Go to **Configuration** → **Hosts**
2. Find your host in the list (the one running speedtest)
3. Click on the **Host name** (not the checkbox)

### Step 2: Link the Template

1. In the host configuration page, click on the **Templates** tab

2. In the **Link new templates** section:
   - Click the **Select** button
   - A popup window will appear
   - Type `Speedtest` in the search box
   - Select **Speedtest Monitoring** from the list
   - Click **Select** to confirm

3. The template should now appear in the **Linked templates** list

4. Click **Update** button at the bottom to save

### Step 3: Verify Template is Linked

1. Go back to **Configuration** → **Hosts**
2. Click on your host name again
3. Go to **Templates** tab
4. Verify **Speedtest Monitoring** is listed in **Linked templates**

---

## ✅ Verification

After applying the template, verify that data is being collected.

### Step 1: Check Latest Data

1. Go to **Monitoring** → **Latest data**
2. In the **Host** filter, select your host
3. In the **Name** filter, type: `Speedtest`
4. Click **Apply**

**Expected Result:**
- You should see 11 items listed
- Each item should show a value (not "No data")
- Values should update based on your speedtest interval

### Step 2: Check Individual Items

Click on any item to see:
- Current value
- History graph
- Details about the item

### Step 3: View Graphs

1. Go to **Monitoring** → **Graphs**
2. Select your host from the dropdown
3. You should see 4 graphs:
   - **Download Speed**
   - **Upload Speed**
   - **Ping/Latency**
   - **Speed Test Overview**

4. Click on any graph to view it in detail

### Step 4: Test Triggers (Optional)

1. Go to **Monitoring** → **Problems**
2. If any triggers fire (based on your thresholds), they will appear here
3. You can test triggers by temporarily lowering thresholds in the template

---

## 🔧 Troubleshooting

### Problem: Template Import Fails

**Symptoms:**
- Error message during import
- Template doesn't appear in list

**Solutions:**

1. **Check Zabbix Version:**
   ```bash
   # On Zabbix server
   zabbix_server --version
   ```
   - Template requires Zabbix 5.0+
   - If using older version, upgrade Zabbix

2. **Verify XML File:**
   ```bash
   # Check if XML is valid
   xmllint --noout zabbix_template_speedtest.xml
   ```
   - Should return no errors

3. **Check Permissions:**
   - Ensure you're logged in as Admin or Super Admin
   - Check file permissions if uploading from server

4. **Try Manual Import:**
   - Copy XML content
   - Paste directly into import text box
   - Click Import

### Problem: Items Show "Not Supported"

**Symptoms:**
- Items appear in Latest data
- All show "Not supported" status
- No values collected

**Solutions:**

1. **Verify Zabbix Agent is Running:**
   ```bash
   # On monitored host
   sudo systemctl status zabbix-agent
   ```

2. **Test UserParameters:**
   ```bash
   # On Zabbix server (standard deployment)
   zabbix_get -s <hostname> -k speedtest.download
   
   # On Zabbix server (Podman - RHEL 10)
   podman exec <zabbix-server-container> zabbix_get -s <hostname> -k speedtest.download
   
   # On Zabbix server (Docker - alternative)
   docker exec <zabbix-server-container> zabbix_get -s <hostname> -k speedtest.download
   
   # On Zabbix server (Kubernetes)
   kubectl exec <zabbix-server-pod> -n <namespace> -- zabbix_get -s <hostname> -k speedtest.download
   ```
   - Should return a number, not "Not supported"
   - If "Not supported", check agent configuration

3. **Check UserParameters Config:**
   ```bash
   # On monitored host
   cat /etc/zabbix/zabbix_agentd.conf.d/speedtest.conf
   ```
   - Should show 11 UserParameter lines

4. **Verify Script Exists:**
   ```bash
   # On monitored host
   ls -l /usr/local/bin/zbx-speedtest.py
   /usr/local/bin/zbx-speedtest.py speedtest.download
   ```
   - Script should exist and return a value

5. **Restart Zabbix Agent:**
   ```bash
   # On monitored host
   sudo systemctl restart zabbix-agent
   ```

6. **Check Agent Logs:**
   ```bash
   # On monitored host
   sudo journalctl -u zabbix-agent -n 50 | grep speedtest
   ```
   - Look for errors or warnings

### Problem: Items Return 0 or Empty

**Symptoms:**
- Items show "Supported" but return 0
- Text items are empty

**Solutions:**

1. **Check Speedtest Data:**
   ```bash
   # On monitored host
   cat /opt/projects/speed-test-with-graphing/speedtest_results.json
   ```
   - Should contain JSON data with test results
   - If empty, run: `python3 speedtest_runner.py`

2. **Test Script Manually:**
   ```bash
   # On monitored host
   /usr/local/bin/zbx-speedtest.py speedtest.download
   ```
   - Should return actual value, not 0
   - If 0, re-run setup: `sudo ./setup_zabbix.sh`

3. **Check File Permissions:**
   ```bash
   # On monitored host
   ls -l /opt/projects/speed-test-with-graphing/speedtest_results.json
   ```
   - Should be readable by zabbix user

4. **Test as Zabbix User:**
   ```bash
   # On monitored host
   sudo -u zabbix /usr/local/bin/zbx-speedtest.py speedtest.download
   ```
   - Should return a value

### Problem: Template Doesn't Appear in Host Link List

**Symptoms:**
- Template imported successfully
- But doesn't show when trying to link to host

**Solutions:**

1. **Refresh Browser:**
   - Clear cache or hard refresh (Ctrl+F5)

2. **Check Template Name:**
   - Search for "Speedtest" (case-sensitive)
   - Try "speedtest" or "Speed"

3. **Verify Template is Active:**
   - Go to Configuration → Templates
   - Check that template shows as active (not disabled)

4. **Check Host Group:**
   - Ensure host and template are in compatible groups

### Problem: Graphs Don't Show Data

**Symptoms:**
- Graphs exist but are empty
- No data points visible

**Solutions:**

1. **Wait for Data Collection:**
   - Items update every 5-10 minutes
   - Wait at least 15 minutes after applying template

2. **Check Item History:**
   - Go to Monitoring → Latest data
   - Verify items are collecting data

3. **Check Graph Configuration:**
   - Go to Configuration → Templates → Speedtest Monitoring → Graphs
   - Verify items are linked to graphs

4. **Check Time Range:**
   - In graph view, adjust time range
   - Try "Last hour" or "Last 24 hours"

---

## 📊 Post-Installation Configuration

After successful installation, you may want to customize:

### Adjust Update Intervals

1. Go to **Configuration** → **Templates** → **Speedtest Monitoring** → **Items**
2. Click on an item to edit
3. Modify **Update interval** as needed
4. Click **Update**

### Modify Trigger Thresholds

1. Go to **Configuration** → **Templates** → **Speedtest Monitoring** → **Triggers**
2. Click on a trigger to edit
3. Modify the expression (e.g., change `<100` to `<50`)
4. Click **Update**

### Create Custom Graphs

1. Go to **Configuration** → **Templates** → **Speedtest Monitoring** → **Graphs**
2. Click **Create graph**
3. Add items and configure display
4. Click **Add**

### Set Up Dashboards

1. Go to **Monitoring** → **Dashboards**
2. Create a new dashboard
3. Add widgets for:
   - Speedtest graphs
   - Latest values
   - Trigger status

---

## 🔄 Updating the Template

If you need to update the template:

1. **Export Current Template (Backup):**
   - Configuration → Templates → Speedtest Monitoring
   - Click **Export** button
   - Save the XML file as backup

2. **Import New Version:**
   - Follow import steps above
   - Zabbix will update existing template
   - Linked hosts will automatically use new version

3. **Verify Updates:**
   - Check that new items/triggers appear
   - Verify existing data is preserved

---

## 📝 Quick Reference

### Import Template
```
Configuration → Templates → Import → Choose File → Import
```

### Apply to Host
```
Configuration → Hosts → [Host Name] → Templates → Link new templates → Select → Update
```

### Verify Data
```
Monitoring → Latest data → Filter by host and "Speedtest"
```

### View Graphs
```
Monitoring → Graphs → Select host → View graphs
```

---

## 🆘 Getting Help

If you encounter issues not covered here:

1. **Check Logs:**
   - **Standard deployment:**
     - Zabbix server logs: `/var/log/zabbix/zabbix_server.log`
     - Zabbix agent logs: `journalctl -u zabbix-agent`
   - **Podman deployment (RHEL 10):**
     - Zabbix server logs: `podman logs <zabbix-server-container>`
     - Zabbix agent logs: `podman logs <zabbix-agent-container>`
   - **Docker deployment (alternative):**
     - Zabbix server logs: `docker logs <zabbix-server-container>`
     - Zabbix agent logs: `docker logs <zabbix-agent-container>`
   - **Kubernetes deployment:**
     - Zabbix server logs: `kubectl logs <zabbix-server-pod> -n <namespace>`
     - Zabbix agent logs: `kubectl logs <zabbix-agent-pod> -n <namespace>`

2. **Verify Prerequisites:**
   - Host has Zabbix agent running
   - Speedtest integration is set up
   - UserParameters are working

3. **Review Documentation:**
   - Main README.md
   - ZABBIX_TEMPLATE_README.md
   - TEST_ZABBIX.md

4. **Test Components:**
   - Test script: `/usr/local/bin/zbx-speedtest.py speedtest.download`
   - Test agent:
     - Standard: `zabbix_get -s <host> -k speedtest.download`
     - Podman (RHEL 10): `podman exec <container> zabbix_get -s <host> -k speedtest.download`
     - Docker: `docker exec <container> zabbix_get -s <host> -k speedtest.download`
     - Kubernetes: `kubectl exec <pod> -n <namespace> -- zabbix_get -s <host> -k speedtest.download`
   - Test data: `cat speedtest_results.json`

---

## ✅ Installation Checklist

Use this checklist to ensure complete installation:

- [ ] Zabbix server version 5.0+ verified
- [ ] Template file downloaded (`zabbix_template_speedtest.xml`)
- [ ] Template imported successfully via web interface
- [ ] Template appears in Templates list
- [ ] Host has Zabbix agent configured
- [ ] Speedtest UserParameters working (`zabbix_get` returns values)
- [ ] Template linked to host
- [ ] Items showing in Latest data (not "Not supported")
- [ ] Items returning actual values (not 0)
- [ ] Graphs displaying data
- [ ] Triggers configured (optional)
- [ ] Dashboard created (optional)

Once all items are checked, your Speedtest Zabbix monitoring is fully operational! 🎉

