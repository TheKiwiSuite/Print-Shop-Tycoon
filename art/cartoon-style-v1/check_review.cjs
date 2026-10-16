const {chromium}=require('playwright');
const fs=require('node:fs'),path=require('node:path'),{pathToFileURL}=require('node:url');
(async()=>{
const browser=await chromium.launch({...(process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE ? {executablePath:process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE} : {}),headless:true});
const page=await browser.newPage({viewport:{width:1440,height:1050},deviceScaleFactor:1});const errors=[];page.on('pageerror',e=>errors.push(String(e)));
const base=pathToFileURL(path.join(__dirname,'index.html')).href;
await page.goto(base);await page.evaluate(async()=>{await Promise.all(items.flatMap(i=>[i.sheet,i.guide]).map(url=>new Promise((resolve,reject)=>{let im=new Image();im.onload=resolve;im.onerror=()=>reject(Error(url));im.src=url}))) });
if(await page.locator('.card').count()!==10)throw Error('Missing equipment cards');
const ids=['dtf','sticker','heat','art','finish','pack','storage','banner','cnc','dock'];
for(const id of ids){await page.locator('#equipment').selectOption(id);if(await page.locator('.angle').count()!==16)throw Error('Missing angles '+id);await page.locator('.angle').nth(15).click();await page.locator('#next').click();if(await page.locator('#angle').textContent()!=='0°')throw Error('Next wrap failed');await page.locator('#prev').click();if(await page.locator('#angle').textContent()!=='337.5°')throw Error('Previous wrap failed');for(const link of ['download','guide'])if(!fs.existsSync(path.join(__dirname,await page.locator('#'+link).getAttribute('href'))))throw Error('Missing file '+id)}
await page.locator('#play').click();await page.waitForFunction(()=>document.getElementById('angle').textContent!=='337.5°');await page.locator('#play').click();if(await page.locator('#play').textContent()!=='Play rotation')throw Error('Pause failed');
await page.goto(base+'?overview=1');await page.waitForTimeout(700);await page.locator('main').screenshot({path:path.join(__dirname,'illustrated-overview.png')});
await page.goto(base+'?kind=sticker');await page.waitForTimeout(700);await page.locator('.comparison').screenshot({path:path.join(__dirname,'sticker-comparison.png')});
await page.setViewportSize({width:700,height:1100});await page.reload();if(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth))throw Error('Narrow overflow');await page.screenshot({path:path.join(__dirname,'narrow-review.png')});
if(errors.length)throw Error(errors.join('\n'));await browser.close();
fs.writeFileSync(path.join(__dirname,'ui-check.json'),JSON.stringify({passed:true,equipment:10,views:160,checks:['all image files load','all 10 selections','16 views each','next/previous wrap','play/pause','download/source links','700px no horizontal overflow','no page errors']},null,2));console.log('REVIEW_CHECKS_PASS 10 sets, 160 views');
})().catch(e=>{console.error(e);process.exit(1)});
