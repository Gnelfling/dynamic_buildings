AddCSLuaFile("shared.lua") AddCSLuaFile("cl_init.lua") include("shared.lua")
local DB=DynamicBuildings
function ENT:Initialize()
    local b=self.DBBuilding if not IsValid(b) then self:Remove() return end
    self:SetModel("models/props_vehicles/car004a_physics.mdl")
    self:SetSolid(SOLID_OBB) self:SetMoveType(MOVETYPE_NONE)
    self.Index=2 self.Direction=1 self:SetPos(b:LocalToWorld(DB.Gas.carRoute[1]))
    self.LastThink=CurTime()
end
function ENT:Think()
    local b=self.DBBuilding if not IsValid(b) then self:Remove() return end
    local now=CurTime() local dt=math.Clamp(now-self.LastThink,0,0.1) self.LastThink=now
    if self.Parked then
        if self.CustomerDone then self.Parked=false self.Direction=-1 self.Index=#DB.Gas.carRoute-1 end
    else
        local p=DB.Gas.carRoute[self.Index]
        if not p then self:Remove() return end
        local target=b:LocalToWorld(p) local delta=target-self:GetPos()
        if delta:Length()<3 then
            if self.Direction==1 and self.Index==#DB.Gas.carRoute then
                self.Parked=true self.Customer=b:SpawnPerson("customer",self)
                if not IsValid(self.Customer) then self.CustomerDone=true end
            else self.Index=self.Index+self.Direction end
        else
            local step=self:GetPos()+delta:GetNormalized()*math.min(delta:Length(),70*dt)
            -- Conservative enclosing hull; wait instead of pushing a player.
            local tr=util.TraceHull({start=self:GetPos(),endpos=step,mins=Vector(-100,-100,8),maxs=Vector(100,100,70),filter=self,mask=MASK_SOLID})
            if not tr.Hit and not tr.StartSolid then
                self:SetPos(step) self:SetAngles(Angle(0,delta:Angle().y,0))
            end
        end
    end
    self:NextThink(now) return true
end
function ENT:OnRemove() if IsValid(self.Customer) then self.Customer:Remove() end end
