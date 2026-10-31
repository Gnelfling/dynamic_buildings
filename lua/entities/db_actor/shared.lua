ENT.Type="anim"
ENT.Base="base_anim"
ENT.PrintName="Building occupant"
ENT.Spawnable=false
ENT.AutomaticFrameAdvance=true
ENT.DBActor=true
function ENT:SetupDataTables() self:NetworkVar("String",0,"Activity") end
