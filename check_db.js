const Database = require('better-sqlite3');
const db = new Database('.tmp/data.db');
const perms = db.prepare("SELECT action, enabled FROM up_permissions WHERE action LIKE '%appointment%' LIMIT 20").all();
console.log(JSON.stringify(perms, null, 2));
const roles = db.prepare("SELECT id, name, type FROM up_roles").all();
console.log('ROLES:', JSON.stringify(roles));
