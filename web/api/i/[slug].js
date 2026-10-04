const fs = require('fs');
const path = require('path');

function esc(s) {
  return String(s).replace(/[&<>"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
}

module.exports = async (req, res) => {
  const { slug } = req.query;
  if (!slug || !/^[A-Za-z0-9]{4,16}$/.test(slug)) {
    return res.status(404).end('Not found');
  }

  let tpl = 'homeparty';
  let name = '모바일 초대장이 도착했어요';
  let description = '열어서 확인해 주세요';

  const sbUrl = process.env.SUPABASE_URL;
  const sbKey = process.env.SUPABASE_ANON_KEY;

  if (sbUrl && sbKey) {
    try {
      const r = await fetch(`${sbUrl}/rest/v1/rpc/get_invite`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': sbKey,
          'Authorization': `Bearer ${sbKey}`
        },
        body: JSON.stringify({ p_slug: slug })
      });
      const data = await r.json();
      const row = Array.isArray(data) ? data[0] : data;
      if (row) {
        tpl = row.tpl || 'homeparty';
        if (row.data?.name) name = row.data.name;
        const parts = [];
        if (row.data?.date) {
          parts.push(new Date(row.data.date + 'T00:00:00+09:00').toLocaleDateString('ko-KR', { year:'numeric', month:'long', day:'numeric' }));
        }
        if (row.data?.place) parts.push(row.data.place);
        if (parts.length) description = parts.join(' · ');
      }
    } catch {}
  }

  const proto = (req.headers['x-forwarded-proto'] || 'https').split(',')[0].trim();
  const siteUrl = `${proto}://${req.headers.host}`;

  // Read index.html and inject OG tags
  let html;
  try {
    const candidates = [
      path.join(process.cwd(), 'index.html'),
      path.join(__dirname, '../../index.html'),
    ];
    for (const p of candidates) {
      if (fs.existsSync(p)) { html = fs.readFileSync(p, 'utf-8'); break; }
    }
  } catch {}

  if (!html) return res.status(500).end('index.html not found');

  html = html
    .replace(/<meta property="og:title"[^>]*>/,    `<meta property="og:title" content="${esc(name)}">`)
    .replace(/<meta property="og:description"[^>]*>/, `<meta property="og:description" content="${esc(description)}">`)
    .replace(/<meta property="og:image"[^>]*>/,     `<meta property="og:image" content="${siteUrl}/og-${esc(tpl)}.svg">`);

  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.setHeader('Cache-Control', 'no-cache, no-store');
  res.end(html);
};
