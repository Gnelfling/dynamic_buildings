AddCSLuaFile("shared.lua") AddCSLuaFile("cl_init.lua") include("shared.lua")
local DB=DynamicBuildings
function ENT:Initialize()
    local b=self.DBBuilding if not IsValid(b) then self:Remove() return end
    local model=DB.ChooseCarModel()
    if not model then
        if not b.CarMissingReported then
            b.CarMissingReported=true local owner=b:GetCreator()
            if IsValid(owner) then owner:ChatPrint("Dynamic Buildings: install the nuke sedan/station wagon model pack for car visits.") end
        end
        self:Remove() return
    end
    self:SetModel(model)
    -- Native skins preserve glass, tires, trim and the author's paint masks.
    self:SetSkin(DB.ChooseCarSkin(self:SkinCount())) self:SetColor(Color(255,255,255))
    -- PlayerColor proxies, when supplied by the model, tint only authored paint.
    local paints={Vector(0.65,0.12,0.10),Vector(0.12,0.24,0.48),Vector(0.15,0.30,0.19),Vector(0.65,0.65,0.60),Vector(0.16,0.17,0.19)}
    self:SetNW2Vector("DBPaint",self:SkinCount()>1 and Vector(1,1,1) or paints[math.random(1,#paints)])
    self:SetSolid(SOLID_OBB) self:SetMoveType(MOVETYPE_NONE)
    local mn,mx=self:OBBMins(),self:OBBMaxs()
    self.GroundOffset=-mn.z
    local radius=math.sqrt(math.max(math.abs(mn.x),math.abs(mx.x))^2+math.max(math.abs(mn.y),math.abs(mx.y))^2)
    self.TraceMin=Vector(-radius,-radius,6-self.GroundOffset) self.TraceMax=Vector(radius,radius,mx.z)
    self.Index=2 self.Direction=1 self.Speed=0
    self:SetPos(self:RoutePoint(1)) self:SetAngles(Angle(0,(self:RoutePoint(2)-self:RoutePoint(1)):Angle().y,0))
    local space=util.TraceHull({start=self:GetPos(),endpos=self:GetPos(),mins=self.TraceMin,maxs=self.TraceMax,filter=self,mask=MASK_SOLID})
    if space.Hit or space.StartSolid then self:Remove() return end
    self.LastThink=CurTime() self:SetVisitState("Arriving")
end
function ENT:RoutePoint(i)
    return self.DBBuilding:LocalToWorld(DB.Gas.carRoute[i])+Vector(0,0,self.GroundOffset)
end
function ENT:Think()
    local b=self.DBBuilding if not IsValid(b) then self:Remove() return end
    local now=CurTime() local dt=math.Clamp(now-self.LastThink,0,0.1) self.LastThink=now
    if self.Parked then
        if not self.HadCustomer and now-(self.ParkedAt or now)>60 then self.CustomerDone=true end
        if not IsValid(self.Customer) and not self.CustomerDone and now>(self.CustomerRetry or 0) then
            self.CustomerRetry=now+3 self.Customer=b:SpawnPerson("customer",self)
            if IsValid(self.Customer) then self.HadCustomer=true end
        end
        if self.CustomerDone or (self.HadCustomer and not IsValid(self.Customer)) then
            self.Parked=false self.Direction=-1 self.Index=#DB.Gas.carRoute-1 self:SetVisitState("Leaving")
        end
    else
        if not DB.Gas.carRoute[self.Index] then self:Remove() return end
        local target=self:RoutePoint(self.Index) local delta=target-self:GetPos()
        if delta:Length()<3 then
            self.Speed=0
            if self.Direction==1 and self.Index==#DB.Gas.carRoute then
                self.Parked=true self.ParkedAt=now self:SetVisitState("Parked") self.CustomerRetry=now
            else self.Index=self.Index+self.Direction end
        else
            local yaw=math.ApproachAngle(self:GetAngles().y,delta:Angle().y,75*dt)
            local aligned=math.abs(math.AngleDifference(yaw,delta:Angle().y))<12
            self.Speed=math.Approach(self.Speed,aligned and math.min(65,delta:Length()) or 0,45*dt)
            local step=self:GetPos()+delta:GetNormalized()*math.min(delta:Length(),self.Speed*dt)
            local tr=util.TraceHull({start=self:GetPos(),endpos=step,mins=self.TraceMin,maxs=self.TraceMax,filter=self,mask=MASK_SOLID})
            if not tr.Hit and not tr.StartSolid then
                self:SetPos(step) self:SetAngles(Angle(0,yaw,0)) self.BlockedAt=nil
                self:SetVisitState(self.Direction==1 and "Arriving" or "Leaving")
            else
                self.Speed=0 self.BlockedAt=self.BlockedAt or now self:SetVisitState("Waiting for clearance")
            end
        end
    end
    self:NextThink(now+(self.Parked and 0.25 or 0.03)) return true
end
function ENT:OnRemove() if IsValid(self.Customer) then self.Customer:Remove() end end
