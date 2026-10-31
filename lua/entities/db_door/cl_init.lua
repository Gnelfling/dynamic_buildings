include("shared.lua")
function ENT:Initialize()
    self:BuildDoorPhysics()
    self:SetRenderBounds(Vector(-60,-60,-5),Vector(60,60,115))
    local model=ClientsideModel("models/props_c17/door01_left.mdl",RENDERGROUP_OPAQUE)
    if not IsValid(model) then return end
    model:SetNoDraw(true) self.Leaf=model
    local mn,mx=model:GetModelBounds() local size=mx-mn
    local alongX=size.x>size.y
    self.NativeYaw=alongX and 0 or -90
    local scale=Vector(alongX and 48/size.x or 3/size.x,alongX and 3/size.y or 48/size.y,108/size.z)
    local matrix=Matrix() matrix:Scale(scale) model:EnableMatrix("RenderMultiply",matrix)
    local pivot=alongX and Vector(mn.x,(mn.y+mx.y)/2,mn.z) or Vector((mn.x+mx.x)/2,mn.y,mn.z)
    pivot=Vector(pivot.x*scale.x,pivot.y*scale.y,pivot.z*scale.z)
    pivot:Rotate(Angle(0,self.NativeYaw,0)) self.Offset=-pivot
end
function ENT:Draw()
    if not IsValid(self.Leaf) then return end
    self.Leaf:SetPos(self:LocalToWorld(self.Offset))
    self.Leaf:SetAngles(self:LocalToWorldAngles(Angle(0,self.NativeYaw,0))) self.Leaf:DrawModel()
end
function ENT:OnRemove() if IsValid(self.Leaf) then self.Leaf:Remove() end end
