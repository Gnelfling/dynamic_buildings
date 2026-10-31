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
DynamicBuildings={Gas={points={bridge={x=0,y=100,z=0},goal={x=100,y=0,z=0}}}}
local blocked=false
local mode='open'
local lastTrace
MASK_PLAYERSOLID=1
function Vector(x,y,z) return {x=x,y=y,z=z} end
util={TraceHull=function(t)
 lastTrace=t
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
assert(DynamicBuildings.FindRoute(building,actor,'unknown')==nil,'unknown destination must fail safely')
DynamicBuildings.TraceActor(building,actor,{}, {},true)
assert(lastTrace.filter(actor)==false and lastTrace.filter({DBActor=true})==false)
assert(lastTrace.filter({DBManagedDoor=true})==false and lastTrace.filter({})==true,'planning must preserve building/world collision')
DynamicBuildings.TraceActor(building,actor,{}, {},'dynamic')
assert(lastTrace.filter({DBActor=true})==true,'dynamic replanning must include occupants')
DynamicBuildings.TraceActor(building,actor,{}, {},false)
assert(lastTrace.filter({DBManagedDoor=true})==true,'movement must not ignore actual door collision')
`, 'route tests')();
const scene=fs.readFileSync('lua/dynamic_buildings/sv_scene.lua','utf8');
const actorSource=fs.readFileSync('lua/entities/db_actor/init.lua','utf8');
fengari.load(`
DynamicBuildings={}
function IsValid(e) return type(e)=='table' and not e.invalid end
util={AddNetworkString=function() end}
net={Receive=function() end}
${scene}
local DB=DynamicBuildings
local a,b,c={},{},{}
local shop1,shop2={},{}
assert(DB.JoinQueue(shop1,a)==1)
assert(DB.JoinQueue(shop1,b)==2)
assert(DB.JoinQueue(shop1,a)==1,'joining twice must not duplicate')
assert(DB.JoinQueue(shop2,c)==1,'queues must be independent')
a.invalid=true
assert(DB.QueuePosition(shop1,b)==1,'deleted actors must not hold queue positions')
DB.LeaveQueue(shop1,b)
assert(#shop1.CheckoutQueue==0 and #shop2.CheckoutQueue==1)
local door={calls={}}
function door:Fire(input) self.calls[#self.calls+1]=input end
DB.SetDoorState(door,true)
DB.SetDoorState(door,true)
DB.SetDoorState(door,false)
assert(#door.calls==2 and door.calls[1]=='Open' and door.calls[2]=='Close','door commands must be edge-triggered')
function AddCSLuaFile() end function include() end function CurTime() return 0 end
ENT={}
${actorSource}
local owner={}
local visitor={DBBuilding=owner}
owner.Reservations={old=visitor}
function owner:Release(e) for k,v in pairs(self.Reservations) do if v==e then self.Reservations[k]=nil end end end
function owner:Reserve(k,e) self.Reservations[k]=e return true end
function visitor:SetActivity() end
DB.FindRoute=function() return nil end
assert(ENT.Go(visitor,'next','arrived')==false)
assert(owner.Reservations.old==visitor,'failed travel must retain occupied reservation')
DB.FindRoute=function() return {{}} end
assert(ENT.Go(visitor,'next','arrived')==true)
assert(owner.Reservations.old==nil and owner.Reservations.next==visitor,'successful travel transfers reservation')
`, 'scene regression tests')();
console.log('PASS: '+count+' Lua files parse; route, invalid destination, queue isolation/removal, door command and reservation regression tests.');
