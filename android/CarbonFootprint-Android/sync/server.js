/* Copyright (c) 2026 Cian8023 · Licensed under Apache-2.0 */
/**
 * 家庭碳账户 · 本地同步服务（E1 多端同步）
 *
 * 两台设备（模拟器/真机）都连这台宿主机服务，通过 HTTP 交换成员快照，
 * 实现真正的多端数据合并。数据落盘到同目录 data.json，重启不丢组。
 *
 * 启动：node sync/server.js 8081
 */

const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = parseInt(process.argv[2] || '8081', 10);
const DATA_FILE = path.join(__dirname, 'data.json');

let db = {};
try {
  db = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
  if (!db || typeof db !== 'object') {
    db = {};
  }
} catch (e) {
  db = {};
}

function persist() {
  try {
    fs.writeFileSync(DATA_FILE, JSON.stringify(db, null, 2), 'utf8');
  } catch (e) {
    console.error('[warn] 落盘失败：', e.message);
  }
}

function sendJson(res, status, obj) {
  const body = JSON.stringify(obj);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(body)
  });
  res.end(body);
}

function readBody(req) {
  return new Promise((resolve) => {
    let raw = '';
    req.on('data', (c) => {
      raw += c;
      if (raw.length > 1e6) {
        req.destroy();
      }
    });
    req.on('end', () => {
      try {
        resolve(raw ? JSON.parse(raw) : {});
      } catch (e) {
        resolve({});
      }
    });
  });
}

function snapshotOf(b) {
  return {
    deviceId: String(b.deviceId || ''),
    name: String(b.name || '成员'),
    totalG: Number(b.totalG) || 0,
    balance: Number(b.balance) || 0,
    weekG: Number(b.weekG) || 0,
    updatedAt: Date.now()
  };
}

function membersOf(code) {
  const g = db[code];
  return g ? Object.keys(g.members).map((k) => g.members[k]) : [];
}

const server = http.createServer(async (req, res) => {
  const u = new URL(req.url, 'http://localhost');
  const p = u.pathname.replace(/\/+$/, '') || '/';

  if (p === '/api/health') {
    return sendJson(res, 200, { code: 0, status: 'ok', groups: Object.keys(db).length });
  }

  // 建组：code 由客户端生成，冲突返回 409
  if (p === '/api/family/create' && req.method === 'POST') {
    const b = await readBody(req);
    const code = String(b.code || '').trim().toUpperCase();
    if (code === '') {
      return sendJson(res, 400, { code: 400, msg: 'code required' });
    }
    if (db[code]) {
      return sendJson(res, 409, { code: 409, msg: 'code exists' });
    }
    db[code] = { createdAt: Date.now(), members: {} };
    if (b.deviceId) {
      db[code].members[b.deviceId] = snapshotOf(b);
    }
    persist();
    console.log(`[${new Date().toLocaleTimeString()}] 建组 ${code}（${b.name || '?'}）`);
    return sendJson(res, 200, { code: 0, data: { code: code, members: membersOf(code) } });
  }

  // 加入组
  if (p === '/api/family/join' && req.method === 'POST') {
    const b = await readBody(req);
    const code = String(b.code || '').trim().toUpperCase();
    if (!db[code]) {
      return sendJson(res, 404, { code: 404, msg: 'group not found' });
    }
    if (b.deviceId) {
      db[code].members[b.deviceId] = snapshotOf(b);
      persist();
    }
    console.log(`[${new Date().toLocaleTimeString()}] 加入 ${code}（${b.name || '?'}）`);
    return sendJson(res, 200, { code: 0, data: { code: code, members: membersOf(code) } });
  }

  // 退出组：移除成员；组空了就解散
  if (p === '/api/family/leave' && req.method === 'POST') {
    const b = await readBody(req);
    const code = String(b.code || '').trim().toUpperCase();
    const deviceId = String(b.deviceId || '');
    if (!db[code]) {
      return sendJson(res, 404, { code: 404, msg: 'group not found' });
    }
    if (deviceId && db[code].members[deviceId]) {
      delete db[code].members[deviceId];
    }
    if (Object.keys(db[code].members).length === 0) {
      delete db[code];
      console.log(`[${new Date().toLocaleTimeString()}] 解散 ${code}（已无成员）`);
    } else {
      console.log(`[${new Date().toLocaleTimeString()}] 退出 ${code}（${deviceId}）`);
    }
    persist();
    return sendJson(res, 200, { code: 0 });
  }

  // 上报本机快照
  if (p === '/api/family/report' && req.method === 'POST') {
    const b = await readBody(req);
    const code = String(b.code || '').trim().toUpperCase();
    if (!db[code]) {
      return sendJson(res, 404, { code: 404, msg: 'group not found' });
    }
    if (!b.deviceId) {
      return sendJson(res, 400, { code: 400, msg: 'deviceId required' });
    }
    db[code].members[b.deviceId] = snapshotOf(b);
    persist();
    console.log(`[${new Date().toLocaleTimeString()}] 上报 ${code} ${b.name || '?'} totalG=${b.totalG}`);
    return sendJson(res, 200, { code: 0, data: membersOf(code) });
  }

  // 拉取组内成员
  if (p === '/api/family/members' && req.method === 'GET') {
    const code = String(u.searchParams.get('code') || '').trim().toUpperCase();
    if (!db[code]) {
      return sendJson(res, 404, { code: 404, msg: 'group not found' });
    }
    return sendJson(res, 200, { code: 0, data: membersOf(code) });
  }

  sendJson(res, 404, { code: 404, msg: 'not found' });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log('────────────────────────────────────────────────────');
  console.log('  家庭碳账户 · 同步服务已启动');
  console.log('────────────────────────────────────────────────────');
  console.log(`  监听地址   http://0.0.0.0:${PORT}`);
  console.log(`  数据文件   ${DATA_FILE}`);
  console.log(`  现有家庭组 ${Object.keys(db).length} 个`);
  console.log('  接口：');
  console.log('    POST /api/family/create   建组');
  console.log('    POST /api/family/join     加入');
  console.log('    POST /api/family/leave    退出（组空则解散）');
  console.log('    POST /api/family/report   上报快照');
  console.log('    GET  /api/family/members?code=CF123456  拉取成员');
  console.log('    GET  /api/health          健康检查');
  console.log('────────────────────────────────────────────────────');
});
