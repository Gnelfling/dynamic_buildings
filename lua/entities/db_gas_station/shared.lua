ENT.Type="anim"
ENT.Base="base_anim"
ENT.PrintName="Gas Station"
ENT.Category="Dynamic Buildings"
ENT.Spawnable=true
ENT.AdminOnly=false
function ENT:SetupDataTables()
    self:NetworkVar("Bool",0,"Occupied")
end
