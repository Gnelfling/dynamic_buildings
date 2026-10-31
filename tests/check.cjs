const fs=require('node:fs'),path=require('node:path');
global.window={};
const parser=require(process.env.DB_LUAPARSE||'luaparse');
const fengari=require(process.env.DB_FENGARI||'fengari-web');
let count=0;
function scan(dir){for(const e of fs.readdirSync(dir,{withFileTypes:true})){
 const p=path.join(dir,e.name);
 if(e.isDirectory())scan(p);
 else if(p.endsWith('.lua')){parser.parse(fs.readFileSync(p,'utf8'),{luaVersion:'5.1'});count++;}
}}
scan('lua');
const source=fs.readFileSync('lua/dynamic_buildings/sv_routes.lua','utf8');
fengari.load(`
DynamicBuildings={Gas={points={bridge={x=0,y=100,z=0}}}}
local blocked=false
local mode='open'
MASK_PLAYERSOLID=1
function Vector(x,y,z) return {x=x,y=y,z=z} end
util={TraceHull=function(t)
 local hit=mode=='closed' or (mode=='detour' and t.start.y==0 and t.endpos.y==0 and t.start.x*t.endpos.x<0)
 return {Hit=hit,StartSolid=false}
end}
function DynamicBuildings.Gas.transform(p) return p end
function DynamicBuildings.GasPoint() return Vector(100,0,0) end
local building={LocalToWorld=function(_,p) return p end}
local actor={GetPos=function() return Vector(-100,0,0) end}
${source}
local r=DynamicBuildings.FindRoute(building,actor,'goal')
assert(#r==1 and r[1].x==100,'direct route')
mode='detour'
r=DynamicBuildings.FindRoute(building,actor,'goal')
assert(#r==2 and r[1].y==100,'route must go around obstruction')
mode='closed'
assert(DynamicBuildings.FindRoute(building,actor,'goal')==nil,'failed route must not cross walls')
`, 'route tests')();
console.log('PASS: '+count+' Lua files parse as Lua 5.1; direct, detour and unreachable route tests.');
