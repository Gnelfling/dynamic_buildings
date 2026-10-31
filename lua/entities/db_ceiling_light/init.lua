AddCSLuaFile("shared.lua") AddCSLuaFile("cl_init.lua") include("shared.lua")
function ENT:Initialize()
    self:SetModel("models/props_wasteland/prison_lamp001c.mdl")
    self:SetBuilding(self.DBBuilding) self:SetMoveType(MOVETYPE_NONE) self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(self:OBBMins(),self:OBBMaxs()) self:SetUseType(SIMPLE_USE) self:SetSkin(0)
end
function ENT:Use(ply)
    local b=self:GetBuilding()
    if not IsValid(b) or not IsValid(ply) or not ply:IsPlayer() or CurTime()<(self.UseAt or 0) then return end
    if self:GetPos():DistToSqr(ply:GetPos())>170^2 then return end
    self.UseAt=CurTime()+0.5 b:SetLightsOn(not b:GetLightsOn())
    for _,light in ipairs(b.Lights or {}) do if IsValid(light) then light:SetSkin(b:GetLightsOn() and 0 or 1) end end
    self:EmitSound("buttons/lightswitch2.wav",60)
end
