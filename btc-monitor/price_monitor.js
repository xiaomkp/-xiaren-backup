// BTC价格监控 - Node.js版本
// 监控 Binance / OKX / Huobi 三所交易所价格
// 运行方式: node price_monitor.js

const https = require('https');

const EXCHANGES = {
  Binance: 'https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT',
  OKX: 'https://www.okx.com/api/v5/market/ticker?instId=BTC-USDT',
  Huobi: 'https://api.huobi.pro/market/detail/merged?symbol=btcusdt'
};

const FEE_RATE = 0.002; // 0.2% 手续费

function fetchPrice(name, url) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          let price;
          if (name === 'Binance') price = parseFloat(parsed.price);
          else if (name === 'OKX') price = parseFloat(parsed.data?.[0]?.last);
          else if (name === 'Huobi') price = parseFloat(parsed.tick?.close);
          resolve({ name, price: price || 0, raw: parsed });
        } catch (e) {
          resolve({ name, price: 0, raw: parsed });
        }
      });
    }).on('error', reject);
  });
}

function formatPrice(p) {
  return '$' + p.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function analyzeArbitrage(prices) {
  const pairs = [];
  const names = Object.keys(prices);
  
  for (let i = 0; i < names.length; i++) {
    for (let j = i + 1; j < names.length; j++) {
      const a = names[i];
      const b = names[j];
      const priceA = prices[a].price;
      const priceB = prices[b].price;
      
      if (!priceA || !priceB) continue;
      
      // A低B高：低买高卖
      if (priceA < priceB) {
        const buyPrice = priceA;
        const sellPrice = priceB;
        const profit = sellPrice - buyPrice - (buyPrice * FEE_RATE * 2);
        const profitPct = (profit / buyPrice * 100).toFixed(3);
        pairs.push({ buy: a, sell: b, profit, profitPct, valid: profit > 0 });
      }
      // B低A高：低买高卖
      if (priceB < priceA) {
        const buyPrice = priceB;
        const sellPrice = priceA;
        const profit = sellPrice - buyPrice - (buyPrice * FEE_RATE * 2);
        const profitPct = (profit / buyPrice * 100).toFixed(3);
        pairs.push({ buy: b, sell: a, profit, profitPct, valid: profit > 0 });
      }
    }
  }
  return pairs;
}

async function main() {
  console.log('\n===============================================================');
  console.log('  🦐 BTC 跨交易所价格监控');
  console.log('  更新间隔: 30秒 | 手续费: 0.2%双边');
  console.log('===============================================================\n');

  const results = await Promise.allSettled([
    fetchPrice('Binance', EXCHANGES.Binance),
    fetchPrice('OKX', EXCHANGES.OKX),
    fetchPrice('Huobi', EXCHANGES.Huobi)
  ]);

  const prices = {};
  console.log('  各交易所 BTC/USDT 价格:');
  console.log('----------------------------------------------------------------');
  
  results.forEach((r, i) => {
    const name = ['Binance', 'OKX', 'Huobi'][i];
    if (r.status === 'fulfilled' && r.value.price > 0) {
      prices[name] = r.value;
      const arrow = r.value.price > 0 ? '  ' : '⚠️ ';
      console.log(`  ${arrow}${name.padEnd(10)} ${formatPrice(r.value.price)}`);
    } else {
      console.log(`  ⚠️ ${name.padEnd(10)} 获取失败`);
      prices[name] = { price: 0 };
    }
  });

  console.log('\n----------------------------------------------------------------');
  console.log('  🔍 套利机会分析（买入 → 卖出）:');
  console.log('----------------------------------------------------------------');

  const pairs = analyzeArbitrage(prices);
  if (pairs.length === 0) {
    console.log('  ❌ 暂无法计算，请检查网络/API状态');
  } else {
    pairs
      .sort((a, b) => b.profitPct - a.profitPct)
      .forEach(p => {
        const icon = p.valid ? '✅' : '❌';
        const status = p.valid ? `${formatPrice(p.profit)} (+${p.profitPct}%)` : `无利润 ${formatPrice(p.profit)} (${p.profitPct}%)`;
        console.log(`  ${icon} ${status}  买 ${p.buy} → 卖 ${p.sell}`);
      });
  }

  console.log('\n===============================================================\n');
}

main().catch(console.error);
