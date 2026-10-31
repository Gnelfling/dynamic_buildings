AddCSLuaFile("shared.lua") AddCSLuaFile("cl_init.lua") include("shared.lua")
local DB=DynamicBuildings
function ENT:Animate(names)
    for _,name in ipairs(names) do
        local id=self:LookupSequence(name)
        if id and id>=0 then
            if self.DBSequence~=id then self:ResetSequence(id) self:SetCycle(0) self.DBSequence=id end
            return
        end
    end
end
function ENT:Initialize()
    if not IsValid(self.DBBuilding) then self:Remove() return end
    self:SetModel("models/Humans/Group01/male_0"..math.random(1,9)..".mdl")
    self:SetSolid(SOLID_BBOX) self:SetCollisionBounds(Vector(-12,-12,0),Vector(12,12,70))
    self:SetMoveType(MOVETYPE_NONE) self:SetCollisionGroup(COLLISION_GROUP_NPC)
    self:SetUseType(SIMPLE_USE) self.Speed=math.Rand(39,49)
    self.State=self.Role=="clerk" and "working" or "enter"
    self:SetActivity(self.State) self.WaitUntil=CurTime()+math.Rand(1,3)
    self.LastThink=CurTime()
end
function ENT:Go(name,nextState)
    local b=self.DBBuilding
    if not b:Reserve(name,self) then self.WaitUntil=CurTime()+2 return false end
    local route=DB.FindRoute(b,self,name)
    if not route then b:Release(self) self.WaitUntil=CurTime()+4 return false end
    b:Release(self) b:Reserve(name,self)
    self.Target=name self.Route=route self.RouteIndex=1 self.AfterMove=nextState
    self:SetActivity("Walking") return true
end
function ENT:Think()
    local now=CurTime() local dt=math.Clamp(now-self.LastThink,0,0.1) self.LastThink=now
    local b=self.DBBuilding if not IsValid(b) then self:Remove() return end
    if self.Route then
        local target=self.Route[self.RouteIndex]
        if not target then
            self.Route=nil self.State=self.AfterMove self.WaitUntil=now+math.Rand(4,8) self:SetActivity(self.State)
        else
            local delta=target-self:GetPos() local distance=delta:Length()
            if distance<2 then self.RouteIndex=self.RouteIndex+1
            else
                local step=self:GetPos()+delta:GetNormalized()*math.min(distance,self.Speed*dt)
                local hit=DB.TraceActor(b,self,self:GetPos(),step,false)
                if not hit.Hit and not hit.StartSolid then
                    self:SetPos(step) self.BlockedSince=nil
                    self:SetAngles(Angle(0,math.ApproachAngle(self:GetAngles().y,delta:Angle().y,220*dt),0))
                    self:Animate({"walk_all","walk_all_Moderate"})
                else
                    self:Animate({"idle_subtle","Idle01"}) self:SetActivity("Waiting for room")
                    self.BlockedSince=self.BlockedSince or now
                    if now-self.BlockedSince>4 and now>(self.ReplanAt or 0) then
                        self.ReplanAt=now+3 local route=DB.FindRoute(b,self,self.Target)
                        if route then self.Route=route self.RouteIndex=1 end
                    end
                end
            end
        end
    else
        self:Animate({"idle_subtle","LineIdle01","Idle01"})
        if now>self.WaitUntil then
            if self.State=="enter" then self:Go("entry","choose")
            elseif self.State=="choose" then self:Go(DB.Gas.browsing[math.random(1,3)],"browsing")
            elseif self.State=="browsing" then self:Go("checkout","paying")
            elseif self.State=="paying" then
                self:EmitSound("buttons/button14.wav",55,100,0.4) self:Go("outside","leaving")
            elseif self.State=="leaving" then self:Remove() return
            elseif self.State=="working" then
                self.WaitUntil=now+math.Rand(3,7)
                self:SetPoseParameter("head_yaw",math.Rand(-25,25))
            end
        end
    end
    self:NextThink(now) return true
end
function ENT:Use(ply)
    if not IsValid(ply) or CurTime()<(self.GreetAt or 0) then return end
    self.GreetAt=CurTime()+5
    self:EmitSound("vo/npc/male01/hi0"..math.random(1,2)..".wav",65)
    local yaw=math.AngleDifference((ply:GetPos()-self:GetPos()):Angle().y,self:GetAngles().y)
    self:SetPoseParameter("head_yaw",math.Clamp(yaw,-60,60))
end
function ENT:OnRemove()
    if IsValid(self.DBBuilding) then self.DBBuilding:Release(self) end
    if IsValid(self.VisitCar) then self.VisitCar.CustomerDone=true end
end
