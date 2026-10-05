// 城市碳普惠平台 Mock 服务（配合应用「创新拓展 3」联调用）
// 启动：node server.js [端口，默认 8080]
// 接口：
//   GET  /api/benefits  → { code: 200, data: Benefit[] }
//   POST /api/exchange  → { code: 200 }，body: { benefitId, cost }
// 应用侧在「我的 > 设置 > 服务配置」填 http://<本机IP>:8080，点「测试连接」验证。
const http = require('http');

const port = Number(process.argv[2] || 8080);

const benefits = [
  { id: 'mock_bus', name: '公交电子券（2次）', icon: '乘', cost: 100, stock: 999, desc: '城市公交 2 次免费乘坐' },
  { id: 'mock_metro', name: '地铁 5 折券', icon: '铁', cost: 150, stock: 999, desc: '地铁乘车 5 折优惠 1 次' },
  { id: 'mock_bag', name: '环保帆布袋', icon: '袋', cost: 200, stock: 999, desc: '可降解棉帆布购物袋 1 个' },
  { id: 'mock_seed', name: '云认养树苗', icon: '苗', cost: 500, stock: 999, desc: '认养沙棘树苗 1 株，获电子证书' },
  { id: 'mock_coffee', name: '自带杯咖啡券', icon: '饮', cost: 300, stock: 999, desc: '合作咖啡店自带杯减免券' },
  { id: 'mock_ticket', name: '植物园门票 8 折', icon: '园', cost: 400, stock: 999, desc: '城市植物园门票 8 折优惠' }
];

const server = http.createServer((req, res) => {
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  if (req.method === 'GET' && req.url === '/api/benefits') {
    res.end(JSON.stringify({ code: 200, data: benefits }));
    return;
  }
  if (req.method === 'POST' && req.url === '/api/exchange') {
    let body = '';
    req.on('data', (c) => { body += c; });
    req.on('end', () => {
      try {
        const j = JSON.parse(body || '{}');
        const b = benefits.find((x) => x.id === j.benefitId);
        if (!b) {
          res.end(JSON.stringify({ code: 404, msg: 'benefit not found' }));
          return;
        }
        if (b.stock <= 0) {
          res.end(JSON.stringify({ code: 409, msg: 'sold out' }));
          return;
        }
        b.stock -= 1;
        res.end(JSON.stringify({ code: 200, msg: 'ok', name: b.name, left: b.stock }));
      } catch (e) {
        res.end(JSON.stringify({ code: 400, msg: 'bad request' }));
      }
    });
    return;
  }
  res.statusCode = 404;
  res.end(JSON.stringify({ code: 404, msg: 'not found' }));
});

server.listen(port, () => {
  console.log('碳普惠 Mock 服务已启动: http://0.0.0.0:' + port);
});
