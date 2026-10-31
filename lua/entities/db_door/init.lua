AddCSLuaFile("shared.lua") AddCSLuaFile("cl_init.lua") include("shared.lua")
function ENT:Initialize()
    self:SetModel("models/props_c17/door01_left.mdl") self:BuildDoorPhysics()
    self.ClosedYaw=self:GetAngles().y self.CurrentTurn=0 self.LastT=CurTime()
    self:SetUseType(SIMPLE_USE)
end
function ENT:Use(ply)
    if not IsValid(ply) or not ply:IsPlayer() or CurTime()<(self.UseAt or 0) then return end
    self.UseAt=CurTime()+0.5
    self:SetDesiredOpen(not self:GetDesiredOpen())
    self.DBRequestedOpen=self:GetDesiredOpen() self.ManualUntil=CurTime()+4
end
function ENT:Think()
    local now=CurTime() local dt=math.Clamp(now-self.LastT,0,0.1) self.LastT=now
    local target=self:GetDesiredOpen() and self:GetSwing() or 0
    local turn=math.Approach(self.CurrentTurn,target,100*dt)
    if turn~=self.CurrentTurn then
        local mn=Vector(math.huge,math.huge,2) local mx=Vector(-math.huge,-math.huge,108)
        for _,a in ipairs({self.CurrentTurn,turn}) do
            local yaw=Angle(0,self.ClosedYaw+a,0)
            for _,x in ipairs({0,48}) do for _,y in ipairs({-1.5,1.5}) do
                local p=Vector(x,y,0) p:Rotate(yaw)
                mn.x=math.min(mn.x,p.x) mn.y=math.min(mn.y,p.y)
                mx.x=math.max(mx.x,p.x) mx.y=math.max(mx.y,p.y)
            end end
        end
        local tr=util.TraceHull({start=self:GetPos(),endpos=self:GetPos(),mins=mn,maxs=mx,
            filter={self,self.DBBuilding},mask=MASK_PLAYERSOLID})
        if not tr.Hit and not tr.StartSolid then
            if not self.Moving then self:EmitSound("doors/door1_move.wav",60) end
            self.Moving=true self.CurrentTurn=turn self:SetAngles(Angle(0,self.ClosedYaw+turn,0))
        end
    elseif self.Moving then
        self.Moving=false
        if target==0 then self:EmitSound("doors/door_wood_close1.wav",65) end
    end
    self:NextThink(now+(turn==target and 0.1 or 0.02)) return true
end
