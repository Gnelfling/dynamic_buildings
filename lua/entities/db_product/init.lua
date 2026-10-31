AddCSLuaFile("shared.lua") AddCSLuaFile("cl_init.lua") include("shared.lua")
function ENT:Initialize()
    if not IsValid(self.DBBuilding) or not self.SupportPos then self:Remove() return end
    self:SetModel("models/props_junk/PopCan01a.mdl")
    self:SetPos(self.SupportPos-Vector(0,0,self:OBBMins().z))
    self:SetMoveType(MOVETYPE_NONE) self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(self:OBBMins(),self:OBBMaxs())
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON) self:SetUseType(SIMPLE_USE)
end
function ENT:Use(ply)
    local b=self.DBBuilding
    if self.Taken or not IsValid(b) or not IsValid(ply) or not ply:IsPlayer() then return end
    if ply:GetPos():DistToSqr(self:GetPos())>128^2 then return end
    local count=b.Carts[ply] or 0
    if count>=5 then ply:ChatPrint("Your basket is full. Visit the clerk to check out.") return end
    self.Taken=true b.Carts[ply]=count+1
    self:EmitSound("buttons/lightswitch2.wav",50)
    ply:ChatPrint("Picked up a drink ("..(count+1).."/5). E on the clerk to check out.")
    self:Remove()
end
