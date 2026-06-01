const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8000;
const DB_FILE = path.join(__dirname, 'personas_db.json');

// Ensure DB file exists
function loadDb() {
  if (fs.existsSync(DB_FILE)) {
    try {
      return JSON.parse(fs.readFileSync(DB_FILE, 'utf8'));
    } catch (e) {
      console.error("Error reading database:", e);
    }
  }
  return {
    users: { "mock_user@example.com": { email: "mock_user@example.com", is_premium: true } },
    personas: {}
  };
}

function saveDb(data) {
  try {
    fs.writeFileSync(DB_FILE, JSON.stringify(data, null, 2), 'utf8');
  } catch (e) {
    console.error("Error saving database:", e);
  }
}

const server = http.createServer((req, res) => {
  // CORS Headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  const url = new URL(req.url, `http://${req.headers.host}`);
  const pathname = url.pathname;
  
  // Route: GET /personas/{email}
  if (req.method === 'GET' && pathname.startsWith('/personas/')) {
    const email = pathname.replace('/personas/', '');
    const db = loadDb();
    const personas = db.personas[email] || [];
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(personas));
    return;
  }

  // Route: POST /personas/{email}
  if (req.method === 'POST' && pathname.startsWith('/personas/')) {
    const email = pathname.replace('/personas/', '');
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      try {
        const persona = JSON.parse(body);
        const db = loadDb();
        if (!db.personas[email]) {
          db.personas[email] = [];
        }
        
        // Update if existing, else insert
        const existingIdx = db.personas[email].findIndex(p => p.id === persona.id);
        if (existingIdx !== -1) {
          db.personas[email][existingIdx] = persona;
          console.log(`Updated persona: ${persona.name}`);
        } else {
          db.personas[email].push(persona);
          console.log(`Created persona: ${persona.name}`);
        }
        
        saveDb(db);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ message: 'Persona saved successfully', persona_id: persona.id }));
      } catch (e) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Invalid JSON body' }));
      }
    });
    return;
  }

  // Route: DELETE /personas/{email}/{id}
  if (req.method === 'DELETE' && pathname.startsWith('/personas/')) {
    // Expected path: /personas/{email}/{id}
    const parts = pathname.split('/');
    if (parts.length >= 4) {
      const email = parts[2];
      const id = parts[3];
      const db = loadDb();
      if (db.personas[email]) {
        const originalLen = db.personas[email].length;
        db.personas[email] = db.personas[email].filter(p => p.id !== id);
        if (db.personas[email].length < originalLen) {
          saveDb(db);
          console.log(`Deleted persona ID: ${id}`);
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ message: 'Persona deleted successfully' }));
          return;
        }
      }
      res.writeHead(404, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'Persona not found' }));
      return;
    }
  }

  // Route: POST /auth/register
  if (req.method === 'POST' && pathname === '/auth/register') {
    const email = url.searchParams.get('email');
    if (email) {
      const db = loadDb();
      if (!db.users[email]) {
        db.users[email] = { email, is_premium: false };
        saveDb(db);
      }
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ message: 'Registration successful', email }));
      return;
    }
    res.writeHead(400, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Email parameter required' }));
    return;
  }

  // Default Fallback
  res.writeHead(404, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ error: 'Not Found' }));
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`Node.js persistent backend listening on http://127.0.0.1:${PORT}`);
});
