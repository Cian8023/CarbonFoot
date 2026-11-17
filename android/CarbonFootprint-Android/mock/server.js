#!/usr/bin/env node
/* Copyright (c) 2026 Cian8023 · Licensed under Apache-2.0 */
/**
 * 碳足迹 · 城市碳普惠 Mock 服务
 * ------------------------------------------------------------
 * 零依赖，只用 Node 内置模块。用于演示 E3「碳普惠积分对接」：
 * 应用在「我的 > 设置 > 服务配置」填入本机地址（如 http://127.0.0.1:8080），
 * 即可从「内置模拟权益池」切换为「已连接城市碳普惠平台」。
 *
 * 接口契约（与 entry/src/main/ets/service/InclusiveService.ets 对齐）：
 *   GET  /api/benefits          → 200 { code: 0, data: Benefit[] }
 *   POST /api/exchange          → 200 { code: 0, message: '兑换成功', data: {...} }
 *   GET  /api/health            → 200 { code: 0, status: 'ok' }
 *
 * Benefit = { id, name, icon, cost, stock, desc }
 *
 * 启动：node server.js [port]        （默认 8080）
 */

'use strict';

const http = require('http');
const { URL } = require('url');

const PORT = Number(process.argv[2]) || 8080;

/** 权益池（与 App 内置模拟池同形，但 id 前缀不同，便于确认已连上远端） */
let benefits = [
  { id: 'bus_2',     name: '公交电子券（2 次）', icon: '乘', cost: 100, stock: 999, desc: '城市公交 2 次免费乘坐' },
  { id: 'metro_50',  name: '地铁 5 折券',       icon: '铁', cost: 150, stock: 999, desc: '地铁乘车 5 折优惠 1 次' },
  { id: 'bag_cotton',name: '环保帆布袋',        icon: '袋', cost: 200, stock: 999, desc: '可降解棉帆布购物袋 1 个' },
  { id: 'tree_seed', name: '云认养树苗',        icon: '苗', cost: 500, stock: 999, desc: '认养沙棘树苗 1 株，获电子证书' },
  { id: 'coffee_cup',name: '自带杯咖啡券',      icon: '饮', cost: 300, stock: 999, desc: '合作咖啡店自带杯减免券' },
  { id: 'garden_20', name: '植物园门票 8 折',   icon: '园', cost: 400, stock: 999, desc: '城市植物园门票 8 折优惠' }
];

/** 兑换流水（内存态，重启即清空） */
const orders = [];

function sendJson(res, statusCode, payload) {
  const body = JSON.stringify(payload);
  res.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(body),
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type,Accept',
    'Cache-Control': 'no-store'
  });
  res.end(body);
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let size = 0;
    req.on('data', (c) => {
      size += c.length;
      // 防止超大请求体打爆内存
      if (size > 1024 * 1024) {
        reject(new Error('请求体过大'));
        req.destroy();
        return;
      }
      chunks.push(c);
    });
    req.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')));
    req.on('error', reject);
  });
}

function ts() {
  const d = new Date();
  const p = (n) => String(n).padStart(2, '0');
  return `${p(d.getHours())}:${p(d.getMinutes())}:${p(d.getSeconds())}`;
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  const path = url.pathname.replace(/\/+$/, '') || '/';

  // CORS 预检
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type,Accept'
    });
    res.end();
    return;
  }

  console.log(`[${ts()}] ${req.method} ${path}`);

  try {
    // ---------- 健康检查 ----------
    if (req.method === 'GET' && path === '/api/health') {
      sendJson(res, 200, { code: 0, status: 'ok', uptime: Math.round(process.uptime()) });
      return;
    }

    // ---------- 权益列表 ----------
    if (req.method === 'GET' && path === '/api/benefits') {
      // 只回可兑换的（stock > 0），库存为 0 的仍然返回但由 App 置灰
      sendJson(res, 200, { code: 0, data: benefits });
      return;
    }

    // ---------- 平台行为记录（供 App「从平台导入」使用） ----------
    if (req.method === 'GET' && path === '/api/behavior') {
      // 用「今天零点」做基准，保证同一份数据每次请求时间戳一致，
      // App 侧的「类型|子类|时间」去重才有意义（否则重复导入会翻倍）
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const base = today.getTime();
      const day = 86400000;
      const rows = [
        { type: '出行', subType: '地铁', value: 12.6, at: base - day + 8 * 3600000, label: '地铁行程' },
        { type: '出行', subType: '公交', value: 8.3, at: base - day * 2 + 9 * 3600000, label: '公交行程' },
        { type: '出行', subType: '地铁', value: 15.2, at: base - day * 3 + 18 * 3600000, label: '地铁行程' }
      ];
      sendJson(res, 200, { code: 0, simulated: true, data: rows });
      return;
    }

    // ---------- 积分兑换 ----------
    if (req.method === 'POST' && path === '/api/exchange') {
      const raw = await readBody(req);
      let payload = {};
      try {
        payload = raw ? JSON.parse(raw) : {};
      } catch (e) {
        sendJson(res, 400, { code: 400, message: '请求体不是合法 JSON' });
        return;
      }

      const benefitId = payload.benefitId;
      const cost = Number(payload.cost);

      if (!benefitId) {
        sendJson(res, 400, { code: 400, message: '缺少 benefitId' });
        return;
      }
      const target = benefits.find((b) => b.id === benefitId);
      if (!target) {
        sendJson(res, 404, { code: 404, message: '权益不存在：' + benefitId });
        return;
      }
      if (target.stock <= 0) {
        sendJson(res, 409, { code: 409, message: '该权益已兑完' });
        return;
      }
      if (!Number.isFinite(cost) || cost !== target.cost) {
        // 价格以服务端为准，客户端传错不阻断，只记一条告警
        console.warn(`  ! cost 不一致：客户端 ${payload.cost}，服务端 ${target.cost}，以服务端为准`);
      }

      target.stock -= 1;
      const order = {
        orderId: 'ORD' + Date.now() + Math.floor(Math.random() * 1000),
        benefitId: target.id,
        name: target.name,
        cost: target.cost,
        stockLeft: target.stock,
        at: Date.now()
      };
      orders.push(order);
      console.log(`  ✓ 兑换成功：${target.name}（-${target.cost} 分，余 ${target.stock}）`);
      sendJson(res, 200, { code: 0, message: '兑换成功', data: order });
      return;
    }

    // ---------- 兑换流水（便于路演展示） ----------
    if (req.method === 'GET' && path === '/api/orders') {
      sendJson(res, 200, { code: 0, data: orders.slice(-50).reverse() });
      return;
    }

    // ---------- 兜底 ----------
    sendJson(res, 404, { code: 404, message: '接口不存在：' + path });
  } catch (err) {
    console.error('  × 处理失败：', err && err.message ? err.message : err);
    if (!res.headersSent) {
      sendJson(res, 500, { code: 500, message: '服务端内部错误' });
    }
  }
});

server.listen(PORT, '0.0.0.0', () => {
  const line = '─'.repeat(52);
  console.log(line);
  console.log('  碳足迹 · 城市碳普惠 Mock 服务已启动');
  console.log(line);
  console.log(`  监听地址   http://127.0.0.1:${PORT}`);
  console.log(`  权益列表   GET  /api/benefits`);
  console.log(`  平台行为   GET  /api/behavior   （供 App 导入，模拟数据）`);
  console.log(`  积分兑换   POST /api/exchange   {"benefitId":"bus_2","cost":100}`);
  console.log(`  兑换流水   GET  /api/orders`);
  console.log(`  健康检查   GET  /api/health`);
  console.log(line);
  console.log('  在 App「我的 > 设置 > 服务配置」填入上面的监听地址即可。');
  console.log('  按 Ctrl+C 停止。');
  console.log('');
});

process.on('SIGINT', () => {
  console.log('\nMock 服务已停止。');
  server.close(() => process.exit(0));
});
