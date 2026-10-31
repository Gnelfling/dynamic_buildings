include("shared.lua")
function ENT:Draw() self:DrawModel() end
function ENT:GetPlayerColor() return self:GetNW2Vector("DBPaint",Vector(1,1,1)) end
