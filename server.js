const express = require('express');
const path = require('path');
const cors = require('cors');
const app = express();

app.use(cors());
app.use(express.json());
app.use(express.static(__dirname));

// ===== KEY DATABASE - In Memory =====
// Format: { key: "KV-XXXX-XXXX", email: "user@email.com" or null, used: false, createdAt: date }
// Add your existing keys here if you already made some:
let KEYS = [
  // Example - DELETE this after you test, or keep it for testing:
  // { key: "KV-TEST-1234", email: null, used: false, createdAt: new Date().toISOString() }
];

// ===== SERVE prime-keys.html =====
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'prime-keys.html'));
});

// ===== APP CALLS THIS - VERIFY KEY =====
// App sends: { email: "user@gmail.com", key: "KV-XXXX" }
// Returns: { valid: true } or { valid: false, reason: "..." }
app.post('/api/verify-key', (req, res) => {
  const { email, key } = req.body || {};
  if (!key) return res.json({ valid: false, reason: 'No key provided' });

  const cleanKey = String(key).trim().toUpperCase();
  const found = KEYS.find(k => k.key.toUpperCase() === cleanKey);

  if (!found) {
    return res.json({ valid: false, reason: 'Key not found' });
  }

  // If key was already tied to a different email, block it
  if (found.email && email && found.email.toLowerCase() !== String(email).toLowerCase()) {
    return res.json({ valid: false, reason: 'Key belongs to another email' });
  }

  // Lock key to this email on first use
  if (!found.email && email) {
    found.email = String(email).toLowerCase();
    found.used = true;
  }

  return res.json({ valid: true, success: true, status: 'valid', email: found.email });
});

// ===== CREATE NEW KEY - From prime-keys.html =====
app.post('/api/create-key', (req, res) => {
  const { email } = req.body || {};
  const part = () => Math.random().toString(36).substring(2, 6).toUpperCase();
  const newKey = `KV-${part()}-${part()}`;
  const entry = { key: newKey, email: email ? String(email).toLowerCase() : null, used: false, createdAt: new Date().toISOString() };
  KEYS.push(entry);
  return res.json({ success: true, key: newKey });
});

// ===== LIST KEYS - For you to see in browser =====
app.get('/api/keys', (req, res) => {
  res.json({ count: KEYS.length, keys: KEYS });
});

const PORT = process.env.PORT || 10000;
app.listen(PORT, () => console.log('KAYVIEW AMBIENT HOST RUNNING ON ' + PORT));
