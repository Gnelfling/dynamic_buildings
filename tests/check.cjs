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
concommand={Add=function() end}
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
visitor.VisitCar={}
local second={DBBuilding=owner,VisitCar={},SetActivity=function() end}
assert(ENT.Go(visitor,'vehicle','boarding') and ENT.Go(second,'vehicle','boarding'),'different car passengers must be able to return independently')
assert(owner.Reservations[visitor.VisitCar]==visitor and owner.Reservations[second.VisitCar]==second,'boarding reserves each vehicle separately')
`, 'scene regression tests')();
const doorSource=fs.readFileSync('lua/entities/db_door/init.lua','utf8');
fengari.load(`
ENT={} DynamicBuildings={}
function AddCSLuaFile() end function include() end
function IsValid(e) return type(e)=='table' end
local now=0 function CurTime() return now end
function math.Clamp(x,a,b) return math.max(a,math.min(b,x)) end
function math.Approach(x,t,s) if x<t then return math.min(t,x+s) else return math.max(t,x-s) end end
function Angle(p,y,r) return {p=p,y=y,r=r} end
function Vector(x,y,z)
 local v={x=x,y=y,z=z}
 function v:Rotate(a) local c,s=math.cos(math.rad(a.y)),math.sin(math.rad(a.y)); local x=self.x;self.x=x*c-self.y*s;self.y=x*s+self.y*c end
 return v
end
MASK_PLAYERSOLID=1
local blocked=false
util={TraceHull=function() return {Hit=blocked,StartSolid=false} end}
${doorSource}
local door=setmetatable({LastT=0,CurrentTurn=0,ClosedYaw=-90,desired=true},{__index=ENT})
function door:GetDesiredOpen() return self.desired end
function door:GetSwing() return -90 end
function door:GetPos() return Vector(0,0,0) end
function door:SetAngles(a) self.angle=a end
function door:EmitSound() end function door:NextThink() end
for i=1,12 do now=now+0.1;door:Think() end
assert(door.CurrentTurn==-90 and door.angle.y==-180,'east door must use the reversed inward swing')
door.desired=false blocked=true now=now+0.1 door:Think()
assert(door.CurrentTurn==-90,'blocked door must not move through an occupant')
blocked=false
for i=1,12 do now=now+0.1;door:Think() end
assert(door.CurrentTurn==0 and door.angle.y==-90,'door must close to its original jamb orientation')
`, 'hinged door movement tests')();
const gasSource=fs.readFileSync('lua/dynamic_buildings/sh_gas.lua','utf8');
fengari.load(`
DynamicBuildings={}
function Vector(x,y,z) return {x=x,y=y,z=z} end
local installed=false
util={IsValidModel=function(model) return installed and model:find('nuke_sedan01_low',1,true)~=nil end}
${gasSource}
assert(DynamicBuildings.ChooseCarModel()==nil,'no installed cars must fail cleanly')
installed=true
assert(DynamicBuildings.ChooseCarModel():find('nuke_sedan01_low',1,true),'only choose installed models')
for i=1,100 do
 local skin=DynamicBuildings.ChooseCarSkin(4)
 assert(skin>=0 and skin<4,'skin must stay within native model range')
 assert(DynamicBuildings.ChooseCarSkin(1)==0,'one-skin model must use skin zero')
end
assert(DynamicBuildings.Gas.doors[1].swing==-90 and DynamicBuildings.Gas.doors[2].swing==-90,'both actual door definitions must be reversed')
local function close(a,b) return math.abs(a-b)<0.001 end
local frontDoor=DynamicBuildings.Gas.doors[1]
for _,name in ipairs({'entry','outside'}) do
 local point=DynamicBuildings.Gas.transform(DynamicBuildings.Gas.points[name])
 assert(math.abs(DynamicBuildings.DoorSide(point,frontDoor.pos,frontDoor.yaw))>110,'waiting points must leave room for the opposite actor to fully clear the door')
end
for _,yaw in ipairs({0,90,180,270}) do
 local c,s=math.cos(math.rad(yaw)),math.sin(math.rad(yaw))
 local function point(x,y) return Vector(x*c-y*s,x*s+y*c,2) end
 local crossed,distance=DynamicBuildings.DoorCrossing(point(24,-100),point(24,100),Vector(0,0,2),yaw)
 assert(crossed and close(distance,100),'door crossing must work at all station rotations')
 assert(not DynamicBuildings.DoorCrossing(point(24,20),point(24,100),Vector(0,0,2),yaw),'same-side route must not wait for a door')
end
local lo,hi=DynamicBuildings.CarTraceBounds(Vector(-100,-40,-20),Vector(100,40,50),90)
assert(close(lo.x,-40) and close(hi.x,40) and close(lo.y,-100) and close(hi.y,100),'car trace must rotate rectangular bounds rather than use a circle')
for _,controls in ipairs(DynamicBuildings.Gas.parking) do
 local route=DynamicBuildings.BuildCarPath(controls)
 assert(#route>#controls and close(route[1].x,controls[1].x) and close(route[#route].y,controls[#controls].y),'curved route must preserve parking endpoints')
 for _,p in ipairs(route) do assert(p.x==p.x and p.y==p.y,'route must contain finite coordinates') end
end
`, 'vehicle variant tests')();
const inventory=fs.readFileSync('lua/dynamic_buildings/sv_inventory.lua','utf8');
const product=fs.readFileSync('lua/entities/db_product/init.lua','utf8');
const station=fs.readFileSync('lua/entities/db_gas_station/init.lua','utf8');
fengari.load(`
DynamicBuildings={}
function IsValid(e) return type(e)=='table' and not e.invalid end
function Vector(x,y,z) return {x=x,y=y,z=z} end
function Angle() return {} end
function CurTime() return 100 end
function AddCSLuaFile() end function include() end
${inventory}
local DB=DynamicBuildings
local b={Carts={},Stock={}}
local buyer={IsPlayer=function() return true end,Alive=function() return true end,PickupObject=function() end,ChatPrint=function() end,EmitSound=function() end}
local other={}
local function item()
 return {Buyer=buyer,GetPurchased=function(e) return e.paid or false end,SetPurchased=function(e,v) e.paid=v end}
end
local items={}
for i=1,5 do items[i]=item();assert(DB.AddCartItem(b,buyer,items[i])) end
local sixth=item()
assert(not DB.AddCartItem(b,buyer,sixth),'basket capacity must be enforced')
assert(DB.CartCount(b,other)==0 and DB.CartCount(b,buyer)==5,'player baskets must be independent')
items[1].invalid=true
assert(DB.CartCount(b,buyer)==4 and DB.AddCartItem(b,buyer,sixth),'removed products must not keep basket slots')
CreateConVar=function() end cleanup={Register=function() end} hook={Add=function() end}
ENT={}
${station}
ENT.CheckoutPlayer(b,buyer)
assert(b.Carts[buyer]==nil and items[2].paid and sixth.paid,'checkout must mark actual props paid and clear the basket')
local arriving={GetClass=function() return 'db_visit_car' end}
local parked={GetClass=function() return 'db_visit_car' end,HadCustomer=true}
local otherShopCar={GetClass=function() return 'db_visit_car' end,CustomerDone=true}
local population={Children={[arriving]=true,[parked]=true,[otherShopCar]=true}}
assert(ENT.PendingCarCount(population)==1,'incoming drivers must reserve population capacity')
assert(ENT.PendingCarCount(population,arriving)==0,'a driver must be able to use its own reserved slot')
ENT={}
${product}
local p=setmetatable({DBBuilding=b,StockKey='test'},{__index=ENT})
function p:GetPurchased() return false end
for _,name in ipairs({'SetTakenItem','SetItemBuyer','EmitSound','PhysicsInit','SetMoveType','SetSolid','NextThink'}) do p[name]=function() end end
function p:GetPhysicsObject() return nil end function p:GetItemLabel() return 'Soda can' end
b.Stock.test=p
assert(p:Take(buyer),'player must be able to take a stock prop')
assert(not p:Take(buyer),'taking a prop twice must not duplicate a purchase')
assert(b.Stock.test==nil and DB.CartCount(b,buyer)==1,'taken item leaves its shelf slot and enters its owner basket')
b.Children={}
for i=1,40 do b.Children[{DBProduct=true,Taken=true}]=true end
assert(DB.LooseProducts(b)==40,'loose item budget must count actual live props')
local extra=setmetatable({DBBuilding=b},{__index=ENT})
local ok,reason=extra:Take(buyer)
assert(not ok and reason=='busy' and DB.CartCount(b,buyer)==1,'loose prop limit must reject before touching a basket')
`, 'inventory and checkout tests')();
fengari.load(`
DynamicBuildings={} function Vector(x,y,z) return {x=x,y=y,z=z} end
util={IsValidModel=function() return true end,AddNetworkString=function() end}
net={Receive=function() end} concommand={Add=function() end}
${gasSource}
${scene}
local DB=DynamicBuildings
function IsValid(e) return type(e)=='table' end
function CurTime() return 1 end
local door={ClosedYaw=0,CurrentTurn=0}
function door:GetPos() return Vector(0,0,2) end
function door:SetDesiredOpen(value) self.open=value end
local pos=Vector(24,-100,2)
local actor={GetPos=function() return pos end,Route={}}
local b={Doors={door}}
assert(not DB.WaitForDoor(b,actor,Vector(24,100,2)) and door.open,'request the door early, before the actor reaches the sweep')
pos=Vector(24,-75,2)
assert(DB.WaitForDoor(b,actor,Vector(24,100,2)),'actor must wait for the closed leaf')
door.CurrentTurn=-90
assert(not DB.WaitForDoor(b,actor,Vector(24,100,2)),'fully open leaf releases waiting actor')
local other={GetPos=function() return Vector(24,90,2) end,Route={}}
assert(DB.WaitForDoor(b,other,Vector(24,-100,2)),'opposing actor must wait for the passage owner')
pos=Vector(24,75,2)
DB.ClearDoorPass(door,2)
assert(door.PassOwner==nil,'passage ownership releases after the actor clears the opposite side')
assert(not DB.WaitForDoor(b,other,Vector(24,-100,2)),'next actor may cross once the passage clears')
`, 'door passage gating tests')();
const lighting=fs.readFileSync('lua/dynamic_buildings/cl_lighting.lua','utf8');
fengari.load(`
local now,on,allocations=0,true,0
function CurTime() return now end
local mt={}
function Vector(x,y,z) return setmetatable({x=x,y=y,z=z},mt) end
mt.__index={DistToSqr=function(a,b) return (a.x-b.x)^2+(a.y-b.y)^2+(a.z-b.z)^2 end}
mt.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
function EyePos() return Vector(0,0,0) end
function IsValid(e) return type(e)=='table' end
function CreateClientConVar() return {GetBool=function() return on end} end
local fixtures,cars={},{}
local shop={GetLightsOn=function() return true end}
local function entity(id)
 return {EntIndex=function() return id end,GetPos=function() return Vector(id,0,126) end,
 GetBuilding=function() return shop end,GetVisitState=function() return 'Arriving' end,
 GetModelBounds=function() return Vector(-90,-40,-10),Vector(90,40,40) end,
 GetNW2Float=function() return 0 end,LocalToWorld=function(_,p) return p end}
end
for i=1,12 do fixtures[i]=entity(i) end
for i=1,4 do cars[i]=entity(100+i) end
ents={FindByClass=function(c) return c=='db_ceiling_light' and fixtures or cars end}
local tick
hook={Add=function(_,_,f) tick=f end}
function DynamicLight() allocations=allocations+1 return {} end
${lighting}
tick()
assert(allocations==10,'client lighting must cap at eight ceiling lights plus two vehicles')
now=0.05 tick() assert(allocations==10,'lighting updates must be throttled')
on=false now=0.2 tick() assert(allocations==10,'lighting toggle must stop further allocations')
`, 'bounded client lighting tests')();
const carSource=fs.readFileSync('lua/entities/db_visit_car/init.lua','utf8');
fengari.load(`
DynamicBuildings={} ENT={}
function AddCSLuaFile() end function include() end
function IsValid(e) return type(e)=='table' end
util={AddNetworkString=function() end} net={Receive=function() end} concommand={Add=function() end}
${scene}
${carSource}
local stopped=0 local b={Parking={}}
local car=setmetatable({DBBuilding=b,ParkingID=1,Engine={Stop=function() stopped=stopped+1 end}},{__index=ENT})
local other={}
assert(DynamicBuildings.TakeTrafficLane(b,car) and not DynamicBuildings.TakeTrafficLane(b,other),'opposing cars cannot own the drive together')
assert(DynamicBuildings.TakeTrafficLane({},other),'traffic lanes must be station-local')
b.Parking[1]=car car:OnRemove()
assert(b.Parking[1]==nil and b.LaneCar==nil and stopped==1,'removing a car releases parking/lane reservations and stops its engine')
assert(DynamicBuildings.TakeTrafficLane(b,other),'removing a lane owner releases waiting traffic')
b.Parking[1]=other car:OnRemove()
assert(b.Parking[1]==other and b.LaneCar==other,'removal must not clear another car reservation')
-- Reproduce engine-method precedence; a plain ENT-only table missed this collision.
local vm={}
function Vector(x,y,z) return setmetatable({x=x,y=y,z=z},vm) end
vm.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
vm.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
vm.__index={Angle=function() return {y=0} end}
function Angle(p,y,r) return {p=p,y=y,r=r} end
function Color() return {} end function CurTime() return 10 end
function math.Rand(a) return a end
function CreateSound() return {Stop=function() end} end
local DB=DynamicBuildings
DB.Gas={parking={{Vector(0,0,2),Vector(100,0,2)}}}
DB.BuildCarPath=function(p) return p end
DB.ChooseCarModel=function() return 'test.mdl' end DB.ChooseCarSkin=function() return 0 end
DB.CarTraceBounds=function(mn,mx) return Vector(mn.x,mn.y,mn.z),Vector(mx.x,mx.y,mx.z) end
local collision=false
util.TraceHull=function() return {Hit=collision,StartSolid=false} end
local shop={LocalToWorld=function(_,p) return p end}
local function fresh()
 local e=setmetatable({DBBuilding=shop},{__index=function(_,key)
  if key=='Blocked' then return function() error('native Blocked expects an Entity, not a Vector') end end
  return ENT[key]
 end})
 for _,name in ipairs({'SetModel','SetSkin','SetColor','SetNW2Vector','SetNW2Float','SetSolid','SetCollisionBounds','SetMoveType','SetUseType','SetVisitState'}) do e[name]=function() end end
 function e:SkinCount() return 1 end
 function e:GetModelBounds() return Vector(-90,-40,-10),Vector(90,40,50) end
 function e:SetPos(p) self.pos=p end function e:GetPos() return self.pos end
 function e:SetAngles(a) self.ang=a end function e:GetAngles() return self.ang end
 function e:Remove() self.removed=true self:OnRemove() end
 return e
end
local ready=fresh() ready:Initialize()
assert(ready.DBReady and ready.LastThink==10 and not ready.removed,'car setup must bypass native Blocked and initialize movement state')
ready:OnRemove()
local partial=fresh() shop.LaneCar=partial shop.Parking={[1]=partial} partial.ParkingID=1
partial:Think()
assert(partial.removed and shop.LaneCar==nil and shop.Parking[1]==nil,'incomplete cars must clean up without arithmetic on a nil clock')
collision=true
local obstructed=fresh() obstructed:Initialize()
assert(obstructed.removed and not obstructed.DBReady and shop.LaneCar==nil,'a blocked spawn must release its lane without becoming ready')
`, 'vehicle cleanup tests')();
console.log('PASS: '+count+' Lua files parse; routes, queues, reversed-door passage, curved traffic/bounds, vehicle cleanup, inventory/checkout and bounded lighting tests.');
