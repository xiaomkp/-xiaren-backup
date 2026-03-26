const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 1920, height: 1080 },
    userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36',
  });
  
  const page = await context.newPage();
  
  // Enable request interception to see what's being loaded
  const apiRequests = [];
  page.on('response', async response => {
    const url = response.url();
    if (url.includes('1688') && (url.includes('json') || url.includes('api'))) {
      apiRequests.push({ url, status: response.status() });
    }
  });

  console.log('Navigating to 1688 youzhan search...');
  await page.goto('https://s.1688.com/youzhan/search.htm?keywords=%E6%94%B6%E7%BA%B3%E7%AE%B1&beginPage=1', {
    waitUntil: 'domcontentloaded',
    timeout: 30000
  });

  // Wait a bit for JS to render
  await page.waitForTimeout(5000);
  
  console.log('Page loaded, checking content...');
  
  // Try to find product data in the page
  const productData = await page.evaluate(() => {
    // Look for any script tags with JSON data
    const scripts = document.querySelectorAll('script');
    const results = [];
    
    scripts.forEach((script, idx) => {
      const content = script.textContent;
      if (content && content.includes('offer') && content.includes('price')) {
        // Try to extract JSON data
        const match = content.match(/\{[^{}]*"offerId"[^{}]*\}/);
        if (match) {
          results.push(match[0].substring(0, 500));
        }
      }
    });
    
    // Also check for data in window variables
    const windowData = [];
    for (const key of Object.keys(window)) {
      if (key.toLowerCase().includes('offer') || key.toLowerCase().includes('product')) {
        try {
          const val = JSON.stringify(window[key]);
          if (val && val.length < 5000 && val.includes('offerId')) {
            windowData.push({ key, preview: val.substring(0, 300) });
          }
        } catch (e) {}
      }
    }
    
    // Get all text content from the page as a fallback
    const bodyText = document.body ? document.body.innerText.substring(0, 3000) : '';
    
    return { results, windowData, bodyText };
  });
  
  console.log('\n=== Window variables with offer data ===');
  productData.windowData.forEach(d => {
    console.log(`Key: ${d.key}`);
    console.log(`Preview: ${d.preview}`);
    console.log('---');
  });
  
  console.log('\n=== Body text preview ===');
  console.log(productData.bodyText.substring(0, 2000));
  
  console.log('\n=== API requests captured ===');
  apiRequests.forEach(req => {
    console.log(`${req.status} ${req.url.substring(0, 200)}`);
  });
  
  await browser.close();
  console.log('\nDone.');
})();
