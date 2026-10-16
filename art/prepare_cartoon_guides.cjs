const {chromium}=require('playwright');
const fs=require('node:fs'),path=require('node:path'),{pathToFileURL}=require('node:url');
const root=__dirname,out=path.join(root,'cartoon-style-v1');
const ids=['dtf','sticker','heat','art','finish','pack','storage','banner','cnc','dock'];
(async()=>{
 fs.mkdirSync(path.join(out,'guides'),{recursive:true});
 const browser=await chromium.launch({...(process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE ? {executablePath:process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE} : {}),headless:true});
 const page=await browser.newPage({viewport:{width:3072,height:3072},deviceScaleFactor:1});
 const records=[];
 for(const id of ids){
  const folder=id==='dtf'?path.join(root,'dtf-reference-v2','rotations-v2'):path.join(root,'equipment-review-v1',id,id==='heat'?'rotations-v4':'rotations-v3');
  const manifest=JSON.parse(fs.readFileSync(path.join(folder,'rotation-manifest.json'),'utf8').replace(/^\uFEFF/,''));
  const imgs=manifest.frames.map(f=>'<img src="'+path.relative(path.join(out,'guides'),path.join(folder,f.file)).split(path.sep).join('/')+'" alt="'+f.azimuth_degrees+' degrees">').join('');
  const html='<!doctype html><html><head><meta charset="utf-8"><style>*{box-sizing:border-box}html,body{margin:0;background:transparent;width:3072px;height:3072px}body{display:grid;grid-template-columns:repeat(4,768px);grid-template-rows:repeat(4,768px)}img{display:block;width:768px;height:768px;object-fit:contain}</style></head><body>'+imgs+'</body></html>';
  const htmlFile=path.join(out,'guides',id+'.html');fs.writeFileSync(htmlFile,html);
  await page.goto(pathToFileURL(htmlFile).href);await page.waitForFunction(()=>[...document.images].every(i=>i.complete&&i.naturalWidth>0));
  await page.screenshot({path:path.join(out,'guides',id+'.png'),omitBackground:true});
  records.push({id,guide:'guides/'+id+'.png',source_manifest:path.relative(out,path.join(folder,'rotation-manifest.json')).replaceAll('\\','/'),angles:manifest.frames.map(f=>f.azimuth_degrees),method:'Browser-rendered 4x4 layout of unchanged Blender frames; row-major, no labels'});
 }
 fs.writeFileSync(path.join(out,'guide-manifest.json'),JSON.stringify(records,null,2));
 await browser.close();console.log('GUIDES_READY',records.length);
})().catch(e=>{console.error(e);process.exit(1)});
