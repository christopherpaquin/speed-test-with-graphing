# Installing the Speedtest Zabbix Template

This guide provides step-by-step instructions for installing the Speedtest Monitoring template on your Zabbix server.

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
```bash
# From Zabbix server or any Linux machine
wget https://raw.githubusercontent.com/christopherpaquin/speed-test-with-graphing/main/zabbix_template_speedtest.xml
```

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
   # On Zabbix server
   zabbix_get -s <hostname> -k speedtest.download
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
   - Zabbix server logs: `/var/log/zabbix/zabbix_server.log`
   - Zabbix agent logs: `journalctl -u zabbix-agent`

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
   - Test agent: `zabbix_get -s <host> -k speedtest.download`
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

