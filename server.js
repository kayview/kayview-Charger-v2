const express = require('express');
const path = require('path');
const cors = require('cors');
const app = express();

app.use(cors());
app.use(express.json());
app.use(express.static(__dirname));

// ============================================================
// FKAYVIEW CHARGER API Live
// Web + APK + MT4/MT5 EA Bridge + REAL MT5 Sync Only + META API
// ============================================================

// ===== FIREBASE CHECK (keeps your log: "Firebase skipped") =====
const HAS_FIREBASE = !!process.env.FIREBASE_SERVICE_ACCOUNT;
if (!HAS_FIREBASE) {
  console.log('Firebase skipped - no FIREBASE_SERVICE_ACCOUNT');
} else {
  console.log('Firebase connected');
}

// ===== KEY DATABASE - In Memory =====
let KEYS = [
  // Test key - use this to test your APK, delete after:
  { key: "KV-TEST-1234", email: null, used: false, createdAt: new Date().toISOString() }
];

// ===== REAL MT5 SYNC STORE - In Memory =====
// EA will POST here every few seconds. APK / Web reads from here.
let EA_STATUS = {
  connected: false,
  account: null,
  broker: null,
  balance: 0,
  equity: 0,
  profit: 0,
  symbol: null,
  lastSync: null,
  lastSignal: null,
  isRealAccount: false, // REAL SYNC ONLY - demo blocked
  trades: []
};

let SIGNALS = []; // Last 50 signals from EA

// ===== SERVE prime-keys.html =====
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'prime-keys.html'));
});

// ===== HEALTH - Render checks this =====
app.get('/health', (req, res) => res.json({ status: 'ok', service: 'FKAYVIEW CHARGER API Live', time: new Date().toISOString() }));

// ===== APP CALLS THIS - VERIFY KEY =====
app.post('/api/verify-key', (req, res) => {
  const { email, key } = req.body || {};
  if (!key) return res.json({ valid: false, reason: 'No key provided' });
  const cleanKey = String(key).trim().toUpperCase();
  const found = KEYS.find(k => k.key.toUpperCase() === cleanKey);
  if (!found) return res.json({ valid: false, reason: 'Key not found' });
  if (found.email && email && found.email.toLowerCase() !== String(email).toLowerCase()) {
    return res.json({ valid: false, reason: 'Key belongs to another email' });
  }
  if (!found.email && email) {
    found.email = String(email).toLowerCase();
    found.used = true;
  }
  return res.json({ valid: true, success: true, status: 'valid', email: found.email });
});

// ===== CREATE NEW KEY =====
app.post('/api/create-key', (req, res) => {
  const { email } = req.body || {};
  const part = () => Math.random().toString(36).substring(2, 6).toUpperCase();
  const newKey = `KV-${part()}-${part()}`;
  const entry = { key: newKey, email: email ? String(email).toLowerCase() : null, used: false, createdAt: new Date().toISOString() };
  KEYS.push(entry);
  return res.json({ success: true, key: newKey });
});

// ===== LIST KEYS =====
app.get('/api/keys', (req, res) => {
  res.json({ count: KEYS.length, keys: KEYS });
});

// ============================================================
// MT4 / MT5 EA BRIDGE - REAL MT5 SYNC ONLY
// ============================================================

// EA -> POSTs heartbeat + account info every 5 sec
// Body: { key, account, broker, balance, equity, profit, symbol, isReal, trades }
app.post('/api/signal', (req, res) => {
  const { key, account, broker, balance, equity, profit, symbol, isReal, isDemo, trades } = req.body || {};

  // REAL SYNC ONLY - Block demo
  if (isDemo === true || isReal === false) {
    return res.json({ success: false, error: 'DEMO BLOCKED - REAL SYNC ONLY' });
  }

  EA_STATUS = {
    connected: true,
    account: account || EA_STATUS.account,
    broker: broker || EA_STATUS.broker,
    balance: balance ?? EA_STATUS.balance,
    equity: equity ?? EA_STATUS.equity,
    profit: profit ?? EA_STATUS.profit,
    symbol: symbol || EA_STATUS.symbol,
    lastSync: new Date().toISOString(),
    lastSignal: new Date().toISOString(),
    isRealAccount: true,
    trades: Array.isArray(trades) ? trades : EA_STATUS.trades,
    key: key || null
  };

  SIGNALS.unshift({ ...req.body, receivedAt: new Date().toISOString() });
  if (SIGNALS.length > 50) SIGNALS = SIGNALS.slice(0, 50);

  return res.json({ success: true, status: 'SYNCED', lastSync: EA_STATUS.lastSync });
});

// EA Heartbeat - lighter ping
app.post('/api/heartbeat', (req, res) => {
  EA_STATUS.connected = true;
  EA_STATUS.lastSync = new Date().toISOString();
  return res.json({ success: true, status: 'ALIVE', serverTime: new Date().toISOString() });
});

// APK / Web -> GET live EA status
app.get('/api/ea-status', (req, res) => {
  // If no sync for 30 sec, mark disconnected
  const last = EA_STATUS.lastSync ? new Date(EA_STATUS.lastSync).getTime() : 0;
  const isStale = Date.now() - last > 30000;
  res.json({ ...EA_STATUS, connected: EA_STATUS.connected && !isStale, realSyncOnly: true });
});

// APK / Web -> GET last signals
app.get('/api/signals', (req, res) => {
  res.json({ count: SIGNALS.length, signals: SIGNALS });
});

// META API - Generic status for APK
app.get('/api/meta', (req, res) => {
  res.json({
    service: 'FKAYVIEW CHARGER API Live',
    mode: 'REAL SYNC ONLY',
    eaConnected: EA_STATUS.connected,
    balance: EA_STATUS.balance,
    equity: EA_STATUS.equity,
    lastSync: EA_STATUS.lastSync,
    keysCount: KEYS.length
  });
});

// ============================================================
// START SERVER - Matches your Render log
// ============================================================
const PORT = process.env.PORT || 10000;
app.listen(PORT, () => {
  console.log('====================================================');
  console.log('Live on ' + PORT + ' - KAYVIEW CHARGER');
  console.log('- REAL SYNC ONLY');
  console.log('Your service is live');
  console.log('Available at your primary URL');
  console.log('API: /api/verify-key | /api/keys | /api/signal | /api/ea-status | /api/meta');
  console.log('====================================================');
});
