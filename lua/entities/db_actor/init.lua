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
    local owner=b.Reservations[name]
    if IsValid(owner) and owner~=self then self.WaitUntil=CurTime()+2 return false end
    local route=DB.FindRoute(b,self,name)
    -- Keep the occupied spot reserved if the next journey cannot start.
    if not route then self.WaitUntil=CurTime()+4 return false end
    b:Release(self) b:Reserve(name,self)
    self.Target=name self.Route=route self.RouteIndex=1 self.AfterMove=nextState
    self.BlockedSince=nil
    self:SetActivity("Walking") return true
end
function ENT:Think()
    local now=CurTime() local dt=math.Clamp(now-self.LastThink,0,0.1) self.LastThink=now
    local b=self.DBBuilding if not IsValid(b) then self:Remove() return end
    if self.Route then
        local target=self.Route[self.RouteIndex]
        if not target then
            self.Route=nil self.State=self.AfterMove self.WaitUntil=now+math.Rand(4,8) self:SetActivity(self.State)
            if self.State=="queuing" then self.WaitUntil=now+0.5 end
        else
            local delta=target-self:GetPos() local distance=delta:Length()
            if distance<2 then self.RouteIndex=self.RouteIndex+1
            else
                local step=self:GetPos()+delta:GetNormalized()*math.min(distance,self.Speed*dt)
                local hit=DB.TraceActor(b,self,self:GetPos(),step,false)
                if not hit.Hit and not hit.StartSolid then
                    self:SetPos(step) self.BlockedSince=nil
                    self:SetActivity("Walking")
                    self:SetAngles(Angle(0,math.ApproachAngle(self:GetAngles().y,delta:Angle().y,220*dt),0))
                    self:Animate({"walk_all","walk_all_Moderate"})
                else
                    self:Animate({"idle_subtle","Idle01"}) self:SetActivity("Waiting for room")
                    self.BlockedSince=self.BlockedSince or now
                    if now-self.BlockedSince>4 and now>(self.ReplanAt or 0) then
                        self.ReplanAt=now+3 local route=DB.FindRoute(b,self,self.Target,true)
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
            elseif self.State=="browsing" then
                DB.JoinQueue(b,self) self.State="queuing" self.WaitUntil=now+0.1
            elseif self.State=="queuing" then
                local rank=DB.QueuePosition(b,self)
                if not rank then DB.JoinQueue(b,self) else
                    local dest=rank==1 and "checkout" or ("queue"..math.min(rank-1,3))
                    if self.Target==dest then self.WaitUntil=now+0.5
                    else self:Go(dest,rank==1 and "paying" or "queuing") end
                end
            elseif self.State=="paying" then
                if not self.Paid then
                    self.Paid=true self:EmitSound("buttons/button14.wav",55,100,0.4)
                end
                if self:Go("outside","leaving") then DB.LeaveQueue(b,self) end
            elseif self.State=="leaving" then self:Remove() return
            elseif self.State=="working" then
                self.WaitUntil=now+math.Rand(3,7)
                self:SetPoseParameter("head_yaw",math.Rand(-25,25))
            end
        end
        local face
        if self.Role=="clerk" then face=DB.GasPoint(b,"checkout")
        elseif self.State=="paying" then face=DB.GasPoint(b,"clerk")
        elseif self.State=="browsing" then
            local toward={browse1=Vector(-360,260,40),browse2=Vector(-220,90,40),browse3=Vector(-195,-145,40)}
            if toward[self.Target] then face=b:LocalToWorld(DB.Gas.transform(toward[self.Target])) end
        end
        if face then self:SetAngles(Angle(0,math.ApproachAngle(self:GetAngles().y,(face-self:GetPos()):Angle().y,100*dt),0)) end
        if now>(self.GestureAt or 0) then
            self.GestureAt=now+math.Rand(6,14)
            local names={"hg_nod_yes","G_look_small","hg_turn_l"}
            local id=self:LookupSequence(names[math.random(1,#names)])
            if id and id>=0 then self:AddGestureSequence(id,true) end
        end
    end
    self:NextThink(now) return true
end
function ENT:Use(ply)
    if not IsValid(ply) or not ply:IsPlayer() or ply:GetPos():DistToSqr(self:GetPos())>160^2 or CurTime()<(self.GreetAt or 0) then return end
    self.GreetAt=CurTime()+5
    self:EmitSound("vo/npc/male01/hi0"..math.random(1,2)..".wav",65)
    self:SetNW2Float("DBTalkUntil",CurTime()+1.6)
    if self.Role=="clerk" then self.DBBuilding:CheckoutPlayer(ply) end
    local yaw=math.AngleDifference((ply:GetPos()-self:GetPos()):Angle().y,self:GetAngles().y)
    self:SetPoseParameter("head_yaw",math.Clamp(yaw,-60,60))
end
function ENT:OnRemove()
    if IsValid(self.DBBuilding) then
        self.DBBuilding:Release(self) DB.LeaveQueue(self.DBBuilding,self)
    end
    if IsValid(self.VisitCar) then self.VisitCar.CustomerDone=true end
end
