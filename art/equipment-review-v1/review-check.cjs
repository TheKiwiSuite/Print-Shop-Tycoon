const {chromium}=require('playwright');
const path=require('node:path'),fs=require('node:fs'),{pathToFileURL}=require('node:url');
(async()=>{
 const browser=await chromium.launch({...(process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE ? {executablePath:process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE} : {}),headless:true});
 const page=await browser.newPage({viewport:{width:1440,height:1000},deviceScaleFactor:1});
 const errors=[];page.on('pageerror',e=>errors.push(String(e)));
 const base=pathToFileURL(path.join(__dirname,'index.html')).href;
 const ids=['sticker','heat','art','finish','pack','storage','banner','cnc','dock'];
 const loaded=()=>page.waitForFunction(()=>[...document.images].every(i=>i.complete&&i.naturalWidth>0));
 await page.goto(base);await loaded();
 if(await page.locator('.card').count()!==9)throw Error('Missing equipment');
 for(const id of ids){
   await page.locator('#equipment').selectOption(id);await loaded();
   if(await page.locator('#grid img').count()!==16)throw Error('Missing views '+id);
   if(!(await page.locator('#hero').getAttribute('src')).startsWith(id+'/'))throw Error('Wrong equipment '+id);
   await page.locator('#next').click();if(await page.locator('#angle').textContent()!=='67.5°')throw Error('Next angle '+id);
   await page.locator('#prev').click();if(await page.locator('#angle').textContent()!=='45°')throw Error('Prev angle '+id);
   await page.locator('.angle').nth(15).click();await page.locator('#next').click();
   if(await page.locator('#angle').textContent()!=='0°')throw Error('Wrap angle '+id);
   for(const linkId of ['blend','manifest']){const rel=await page.locator('#'+linkId).getAttribute('href');if(!fs.existsSync(path.join(__dirname,rel)))throw Error('Missing download '+rel)}
 }
 await page.locator('#play').click();await page.waitForFunction(()=>document.getElementById('angle').value!=='0°');await page.locator('#play').click();
 if(await page.locator('#play').textContent()!=='Play rotation')throw Error('Pause failed');
 await page.goto(base+'?overview=1');await loaded();await page.locator('.overview').screenshot({path:path.join(__dirname,'equipment-overview.png')});
 for(const id of ids){await page.goto(base+'?sheet=1&kind='+id);await loaded();await page.locator('#sheet').screenshot({path:path.join(__dirname,id,'all-16-angles.png')})}
 await page.setViewportSize({width:700,height:900});await page.goto(base);await loaded();
 if(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth))throw Error('Narrow layout overflow');
 await page.screenshot({path:path.join(__dirname,'narrow-review.png'),fullPage:true});
 if(errors.length)throw Error(errors.join('\n'));
 fs.writeFileSync(path.join(__dirname,'review-ui-check.json'),JSON.stringify({passed:true,checks:['9 equipment choices','144 rendered image links load','next and previous angles','wrap 337.5 to 0 degrees','play and pause','model and manifest links exist','nine contact sheets captured','700px layout no horizontal overflow'],pageErrors:errors},null,2));
 await browser.close();console.log('COLLECTION_REVIEW_UI_PASS');
})().catch(e=>{console.error(e);process.exit(1)});
