ENT.Type="anim" ENT.Base="base_anim" ENT.PrintName="Shelf drink" ENT.Spawnable=false
ENT.DBProduct=true
function ENT:SetupDataTables()
    self:NetworkVar("Bool",0,"Purchased") self:NetworkVar("Bool",1,"TakenItem")
    self:NetworkVar("String",0,"ItemLabel")
    self:NetworkVar("Entity",0,"ItemBuyer")
end
