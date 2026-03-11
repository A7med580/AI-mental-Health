# Troubleshooting Timeout Error

## Your Current Setup
- ✅ IP configured: `http://192.168.1.2:8000`
- ✅ PC IP matches: `192.168.1.2`
- ❌ Still getting timeout

## Step-by-Step Troubleshooting

### Step 1: Verify Backend is Running

**Open a NEW terminal window** and run:

```powershell
cd "E:\Graduation project\backend"
python main.py
```

You should see:
```
INFO:     Started server process
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
```

**Keep this terminal open** - backend must stay running!

---

### Step 2: Test Backend from PC Browser

While backend is running, open browser on your PC:

```
http://localhost:8000/health
```

Should return: `{"status":"healthy"}`

If this doesn't work → Backend isn't running properly

---

### Step 3: Test Backend from Phone Browser

**Important:** Phone and PC must be on **same Wi-Fi network**

1. Make sure phone is connected to same Wi-Fi as PC
2. Open browser on phone
3. Go to: `http://192.168.1.2:8000/health`

**Expected results:**
- ✅ Works → Network is fine, issue is in Flutter app
- ❌ Timeout/Can't connect → Network/firewall issue

---

### Step 4: Check Windows Firewall

Windows Firewall might be blocking port 8000.

**Option A: Allow Python through Firewall**
1. Windows Settings → Privacy & Security → Windows Security
2. Firewall & network protection
3. Allow an app through firewall
4. Find "Python" and check both "Private" and "Public"

**Option B: Add Port Exception**
1. Windows Settings → Privacy & Security → Windows Security
2. Firewall & network protection → Advanced settings
3. Inbound Rules → New Rule
4. Port → TCP → Specific local ports: `8000`
5. Allow the connection → Apply to all profiles
6. Name: "Python Backend Port 8000"

---

### Step 5: Verify Network Connection

**Check if phone can reach PC:**

On phone, open browser and try:
- `http://192.168.1.2:8000/health` ← Should work
- `http://192.168.1.2:8000/` ← Should show API message

If phone browser can't connect → Network/firewall issue

---

### Step 6: Check Flutter App Logs

When running Flutter app, look for this in console:

```
[ApiConfig] Using physical device IP: http://192.168.1.2:8000
[ApiConfig] Full URL: http://192.168.1.2:8000/screening/adhd
```

If you see different URL → Config not applied correctly

---

### Step 7: Try Alternative IP

Your PC shows TWO IPs:
- `172.19.16.1` (might be VPN/virtual adapter)
- `192.168.1.2` (LAN IP)

Try the other one temporarily:

```dart
// In api_config.dart
static const String? PHYSICAL_DEVICE_IP = 'http://172.19.16.1:8000';
```

Then restart app: `flutter run`

---

## Common Issues & Solutions

### Issue 1: Backend Not Running
**Symptom:** Timeout immediately
**Solution:** Start backend in separate terminal

### Issue 2: Firewall Blocking
**Symptom:** Phone browser can't access `http://192.168.1.2:8000/health`
**Solution:** Add firewall exception (Step 4)

### Issue 3: Different Networks
**Symptom:** Phone and PC on different Wi-Fi
**Solution:** Connect both to same network

### Issue 4: VPN Active
**Symptom:** VPN changes network routing
**Solution:** Disable VPN temporarily

### Issue 5: Hotspot Mode
**Symptom:** Using phone hotspot for PC
**Solution:** Use regular Wi-Fi router instead

---

## Quick Test Commands

### Test Backend Health (from PC):
```powershell
curl http://localhost:8000/health
```

### Test from Phone Browser:
```
http://192.168.1.2:8000/health
```

### Check if Port is Listening:
```powershell
netstat -an | findstr :8000
```
Should show: `0.0.0.0:8000` or `192.168.1.2:8000`

---

## Still Not Working?

1. **Restart backend** (stop with Ctrl+C, start again)
2. **Restart Flutter app** (stop with Ctrl+C, `flutter run` again)
3. **Check phone Wi-Fi** - ensure connected to same network
4. **Try emulator first** - set `PHYSICAL_DEVICE_IP = null` and test on emulator
5. **Check backend logs** - look for incoming requests in backend terminal

---

## Expected Flow When Working

1. Backend running → Shows "Uvicorn running on http://0.0.0.0:8000"
2. Phone browser → `http://192.168.1.2:8000/health` works
3. Flutter app → Connects successfully, no timeout
4. Processing screen → Shows "Processing your screening..."
5. Result → Shows ADHD screening result



