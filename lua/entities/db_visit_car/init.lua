AddCSLuaFile("shared.lua") AddCSLuaFile("cl_init.lua") include("shared.lua")
local DB=DynamicBuildings
function ENT:Initialize()
    self.DBReady=false self.LastThink=CurTime()
    local b=self.DBBuilding if not IsValid(b) then self:Remove() return end
    local model=DB.ChooseCarModel()
    if not model then
        if not b.CarMissingReported then
            b.CarMissingReported=true local owner=b:GetCreator()
            if IsValid(owner) then owner:ChatPrint("Dynamic Buildings: install the nuke sedan/station wagon model pack for car visits.") end
        end
        self:Remove() return
    end
    self:SetModel(model) self:SetSkin(DB.ChooseCarSkin(self:SkinCount())) self:SetColor(Color(255,255,255))
    local paints={Vector(0.65,0.12,0.10),Vector(0.12,0.24,0.48),Vector(0.15,0.30,0.19),Vector(0.65,0.65,0.60),Vector(0.16,0.17,0.19)}
    self:SetNW2Vector("DBPaint",self:SkinCount()>1 and Vector(1,1,1) or paints[math.random(1,#paints)])
    self.ModelMin,self.ModelMax=self:GetModelBounds()
    local mn,mx=self.ModelMin,self.ModelMax
    self.NativeYaw=(mx.y-mn.y)>(mx.x-mn.x) and -90 or 0
    self:SetNW2Float("DBForwardYaw",self.NativeYaw)
    self:SetSolid(SOLID_OBB) self:SetCollisionBounds(mn,mx) self:SetMoveType(MOVETYPE_NONE) self:SetUseType(SIMPLE_USE)
    self.GroundOffset=-mn.z self.ParkingID=self.ParkingID or 1
    if not DB.TakeTrafficLane(b,self) then self:Remove() return end
    self.Path={}
    for _,p in ipairs(DB.BuildCarPath(DB.Gas.parking[self.ParkingID])) do self.Path[#self.Path+1]=b:LocalToWorld(p)+Vector(0,0,self.GroundOffset) end
    self.Index=2 self.Direction=1 self.Speed=0 self.Cruise=math.Rand(80,110)
    self:SetPos(self.Path[1]) self:SetAngles(Angle(0,(self.Path[2]-self.Path[1]):Angle().y+self.NativeYaw,0))
    if self:DBIsPathBlocked(self:GetPos(),self:GetAngles().y) then self:Remove() return end
    self.LastThink=CurTime() self:SetVisitState("Arriving")
    self.Engine=CreateSound(self,"vehicles/v8/v8_idle_loop1.wav")
    self.DBReady=true
end
function ENT:DBIsPathBlocked(step,yaw)
    local lo,hi=DB.CarTraceBounds(self.ModelMin,self.ModelMax,yaw)
    local oldLo,oldHi=DB.CarTraceBounds(self.ModelMin,self.ModelMax,self:GetAngles().y)
    lo.x=math.min(lo.x,oldLo.x)-1 lo.y=math.min(lo.y,oldLo.y)-1
    hi.x=math.max(hi.x,oldHi.x)+1 hi.y=math.max(hi.y,oldHi.y)+1
    local tr=util.TraceHull({start=self:GetPos(),endpos=step,mins=lo,maxs=hi,filter=self,mask=MASK_SOLID})
    return tr.Hit or tr.StartSolid
end
function ENT:FindPassengerPoint()
    local mn,mx=self.ModelMin,self.ModelMax
    for _,side in ipairs({-1,1}) do
        local p
        if self.NativeYaw==0 then p=Vector((mn.x+mx.x)/2,side<0 and mn.y-26 or mx.y+26,mn.z)
        else p=Vector(side<0 and mn.x-26 or mx.x+26,(mn.y+mx.y)/2,mn.z) end
        p=self:LocalToWorld(p)
        local tr=util.TraceHull({start=p,endpos=p,mins=Vector(-16,-16,1),maxs=Vector(16,16,70),mask=MASK_PLAYERSOLID})
        if not tr.Hit and not tr.StartSolid then return p end
    end
end
function ENT:Use(ply)
    if not IsValid(ply) or not ply:IsPlayer() or ply:GetPos():DistToSqr(self:GetPos())>180^2 then return end
    self:Honk()
end
function ENT:Honk()
    if CurTime()<(self.HornAt or 0) then return end
    self.HornAt=CurTime()+15 self:EmitSound("buttons/blip1.wav",65,100,0.5)
end
function ENT:Think()
    -- Discard incomplete setup, including old failed cars after a Lua refresh.
    if not self.DBReady then self:Remove() return end
    local b=self.DBBuilding if not IsValid(b) then self:Remove() return end
    local now=CurTime() local dt=math.Clamp(now-self.LastThink,0,0.1) self.LastThink=now
    if self.Parked then
        if not self.HadCustomer and now-self.ParkedAt>60 then self.CustomerDone=true end
        if not IsValid(self.Customer) and not self.CustomerDone and now>(self.CustomerRetry or 0) then
            self.CustomerRetry=now+3
            local point=self:FindPassengerPoint()
            if point then
                self.PassengerPoint=point self.Customer=b:SpawnPerson("customer",self,point)
                if IsValid(self.Customer) then self.HadCustomer=true end
            end
        end
        if self.CustomerDone or (self.HadCustomer and not IsValid(self.Customer)) then
            self.DepartAt=self.DepartAt or (now+math.Rand(2,5))
            if now>=self.DepartAt and DB.TakeTrafficLane(b,self) then
                self.Parked=false self.Direction=-1 self.Index=#self.Path-1 self:SetVisitState("Reversing")
            end
        end
    else
        local target=self.Path[self.Index]
        if not target then self:Remove() return end
        local delta=target-self:GetPos()
        if delta:Length()<3 then
            if self.Direction==1 and self.Index==#self.Path then
                self.Speed=0 self.Parked=true self.ParkedAt=now self:SetVisitState("Parked") self.CustomerRetry=now+math.Rand(2,4)
                DB.ReleaseTrafficLane(b,self)
            else self.Index=self.Index+self.Direction end
        else
            local reversing=self.Direction<0 and self.Index>=#self.Path-8
            local heading=delta:Angle().y+self.NativeYaw+(reversing and 180 or 0)
            local yaw=math.ApproachAngle(self:GetAngles().y,heading,80*dt)
            local aligned=math.abs(math.AngleDifference(yaw,heading))<25
            local road=b:WorldToLocal(self:GetPos()).x>-500
            local speed=road and self.Cruise or (reversing and 28 or 50)
            -- Brake before the next movement step reaches an occupant or prop.
            local ahead=self:GetPos()+delta:GetNormalized()*math.min(delta:Length(),30+self.Speed*0.6)
            local trafficBlocked=self:DBIsPathBlocked(ahead,yaw)
            if trafficBlocked then speed=0 end
            if self.Index==#self.Path or self.Index==1 then speed=math.min(speed,delta:Length()+8) end
            self.Speed=math.Approach(self.Speed,aligned and speed or 0,45*dt)
            local step=self:GetPos()+delta:GetNormalized()*math.min(delta:Length(),self.Speed*dt)
            if not trafficBlocked and not self:DBIsPathBlocked(step,yaw) then
                self:SetPos(step) self:SetAngles(Angle(0,yaw,0)) self.BlockedAt=nil
                self:SetVisitState(reversing and "Reversing" or (self.Direction==1 and "Arriving" or "Leaving"))
            else
                self.Speed=0 self.BlockedAt=self.BlockedAt or now self:SetVisitState("Waiting for clearance")
                if now-self.BlockedAt>10 then self:Honk() end
            end
        end
    end
    if self.Engine and now>(self.SoundAt or 0) then
        self.SoundAt=now+0.25
        if self.Parked then
            if self.EngineOn then self.Engine:Stop() self.EngineOn=false end
        else
            if not self.EngineOn then self.Engine:PlayEx(0.18,80) self.EngineOn=true end
            self.Engine:ChangePitch(75+self.Speed*0.35,0.25)
        end
    end
    self:NextThink(now+(self.Parked and 0.25 or 0.03)) return true
end
function ENT:OnRemove()
    if self.Engine then self.Engine:Stop() end
    local b=self.DBBuilding
    if IsValid(b) then DB.ReleaseTrafficLane(b,self) end
    if IsValid(b) and b.Parking and b.Parking[self.ParkingID]==self then b.Parking[self.ParkingID]=nil end
    if IsValid(self.Customer) then self.Customer:Remove() end
end
