AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")
local DB=DynamicBuildings
function ENT:SpawnFunction(ply,tr,class)
    if not tr.Hit or tr.HitNormal.z<0.95 then return end
    if not util.IsValidModel(DB.Gas.model) then
        ply:ChatPrint("Dynamic Buildings: install the required buildings pack first (see README).") return
    end
    if not ply:CheckLimit("db_buildings") then return end
    local yaw=Angle(0,math.Round(ply:EyeAngles().y/90)*90,0)
    local offset=Vector(DB.Gas.center.x,DB.Gas.center.y,0) offset:Rotate(yaw)
    local origin=tr.HitPos-offset+Vector(0,0,1)
    -- Require support across the footprint before constructing the scene.
    for _,p in ipairs({Vector(-1700,-570,0),Vector(-50,-570,0),Vector(-50,570,0),Vector(-1700,570,0)}) do
        p:Rotate(yaw)
        local ground=util.TraceLine({start=origin+p+Vector(0,0,12),endpos=origin+p-Vector(0,0,20),filter=ply,mask=MASK_SOLID_BRUSHONLY})
        if not ground.Hit or math.abs(ground.HitPos.z-tr.HitPos.z)>6 then
            ply:ChatPrint("Dynamic Buildings: choose a large, level area for the complete lot.") return
        end
    end
    local e=ents.Create(class) if not IsValid(e) then return end
    e:SetPos(origin) e:SetAngles(yaw) e:SetCreator(ply) e:Spawn() e:Activate()
    ply:AddCount("db_buildings",e) ply:AddCleanup("db_buildings",e)
    return e -- Sandbox creates its standard undo entry for this entity.
end
CreateConVar("sbox_maxdb_buildings","3",FCVAR_ARCHIVE,"Dynamic Buildings limit per player",0,20)
cleanup.Register("db_buildings")
function ENT:Own(e)
    if not IsValid(e) then return end
    self.Children[e]=true e.DBBuilding=self self:DeleteOnRemove(e)
    return e
end
function ENT:Initialize()
    self.Children={} self.Reservations={} self.CheckoutQueue={} self.Carts={} self.Parking={}
    self.NextVisit=CurTime()+4 self.NextStock=CurTime()+1
    self:SetLightsOn(true)
    self:SetModel(DB.Gas.model) self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE) self:SetSolid(SOLID_VPHYSICS)
    local ph=self:GetPhysicsObject() if IsValid(ph) then ph:EnableMotion(false) end
    self:SetOccupied(true)
    self.Doors={}
    for _,d in ipairs(DB.Gas.doors) do
        local door=ents.Create("db_door")
        if IsValid(door) then
            door:SetPos(self:LocalToWorld(d.pos)) door:SetAngles(Angle(0,self:GetAngles().y+d.yaw,0))
            door:SetSwing(d.swing) door.DBManagedDoor=true
            self:Own(door)
            door:Spawn() door:Activate() self.Doors[#self.Doors+1]=door
        end
    end
    self.Clerk=self:SpawnPerson("clerk")
    self.Lights={}
    for _,p in ipairs(DB.Gas.ceilingLights) do
        local light=ents.Create("db_ceiling_light")
        if IsValid(light) then
            self:Own(light) light:SetPos(self:LocalToWorld(p)) light:SetAngles(self:GetAngles()) light:Spawn()
            self.Lights[#self.Lights+1]=light
        end
    end
end
function ENT:CustomerCount()
    local n=0
    for e in pairs(self.Children) do
        if IsValid(e) and e.DBActor and e.Role~="clerk" then n=n+1 end
    end
    return n
end
function ENT:PendingCarCount(except)
    local n=0
    for car in pairs(self.Children) do
        if car~=except and IsValid(car) and car:GetClass()=="db_visit_car" and not car.HadCustomer and not car.CustomerDone then n=n+1 end
    end
    return n
end
function ENT:SpawnPerson(role,car,spawnPos)
    if self.Removing then return end
    if role~="clerk" and self:CustomerCount()+self:PendingCarCount(car)>=GetConVar("db_customers"):GetInt() then return end
    local pos=spawnPos or DB.GasPoint(self,role=="clerk" and "clerk" or "outside")
    local space=util.TraceHull({start=pos,endpos=pos,mins=Vector(-16,-16,1),maxs=Vector(16,16,70),mask=MASK_PLAYERSOLID})
    if space.Hit or space.StartSolid then return end
    local e=ents.Create("db_actor") if not IsValid(e) then return end
    e.DBBuilding=self e.Role=role e.VisitCar=car
    e:SetPos(pos)
    self:Own(e) e:Spawn() e:Activate()
    return e
end
function ENT:Reserve(name,actor)
    local old=self.Reservations[name]
    if IsValid(old) and old~=actor then return false end
    self.Reservations[name]=actor return true
end
function ENT:Release(actor)
    for name,e in pairs(self.Reservations) do if e==actor then self.Reservations[name]=nil end end
end
function ENT:Think()
    local now=CurTime()
    for _,door in ipairs(self.Doors) do
        if IsValid(door) then
            DB.DoorDemand(self,door,now)
        end
    end
    if now>self.NextStock then
        self.NextStock=now+20 self:Restock()
        if not IsValid(self.Clerk) then self.Clerk=self:SpawnPerson("clerk") end
        for ply,cart in pairs(self.Carts) do
            if not IsValid(ply) then
                if type(cart)=="table" then for item in pairs(cart) do if IsValid(item) then item:Remove() end end end
                self.Carts[ply]=nil
            else DB.CartCount(self,ply) end
        end
    end
    if now>self.NextVisit then
        self.NextVisit=now+math.Rand(18,32)
        for e in pairs(self.Children) do
            if not IsValid(e) then self.Children[e]=nil end
        end
        local free
        for i=1,#DB.Gas.parking do if not IsValid(self.Parking[i]) then free=i break end end
        self.PreferCar=not self.PreferCar
        if self.PreferCar and GetConVar("db_traffic"):GetBool() and self:CustomerCount()+self:PendingCarCount()<GetConVar("db_customers"):GetInt() and free and not IsValid(self.LaneCar) then
            local car=ents.Create("db_visit_car")
            if IsValid(car) then self:Own(car) car.ParkingID=free self.Parking[free]=car car:Spawn() end
            if not IsValid(car) then self:SpawnPerson("customer") end
        else self:SpawnPerson("customer") end
    end
    self:NextThink(now+0.25) return true
end
function ENT:OnRemove()
    self.Removing=true
    for e in pairs(self.Children or {}) do if IsValid(e) then e:Remove() end end
end
function ENT:Restock()
    self.Stock=self.Stock or {}
    for rack=1,2 do for tier=1,3 do for slot=1,5 do
        local key=rack..":"..tier..":"..slot
        if not IsValid(self.Stock[key]) then
            local e=ents.Create("db_product")
            if IsValid(e) then
                self:Own(e)
                local height=({14,36,56.637})[tier]+14*4.079/34
                local pos=rack==1 and Vector(-1640+(slot-1)*60,-524,height+0.5) or Vector(-1500+(slot-1)*24,-354,height+0.5)
                e.StockKey=key
                if tier==1 and slot%2==0 then e.ItemModel="models/props_junk/garbage_milkcarton002a.mdl" e.Label="Milk carton" end
                e.SupportPos=self:LocalToWorld(pos)
                e:Spawn() self.Stock[key]=e
            end
        end
    end end end
end
function ENT:CheckoutPlayer(ply)
    local count=DB.CartCount(self,ply)
    if count<1 then ply:ChatPrint("Clerk: Pick something from the shelves, then come back to me.") return end
    for item in pairs(self.Carts[ply]) do
        if IsValid(item) then item:SetPurchased(true) item.ExpiresAt=CurTime()+180 end
    end
    self.Carts[ply]=nil
    ply:EmitSound("buttons/button14.wav",60)
    ply:ChatPrint("Clerk: "..count.." item(s). All paid! E on a purchased item to enjoy it.")
end
hook.Add("PhysgunPickup","DB.FixedScenes",function(_,e)
    if e:GetClass()=="db_gas_station" or IsValid(e.DBBuilding) then return false end
end)
