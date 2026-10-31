ENT.Type="anim" ENT.Base="base_anim" ENT.PrintName="Station door" ENT.Spawnable=false
ENT.DBManagedDoor=true
function ENT:SetupDataTables()
    self:NetworkVar("Float",0,"Swing")
    self:NetworkVar("Bool",0,"DesiredOpen")
end
function ENT:BuildDoorPhysics()
    local v={}
    for _,x in ipairs({0,48}) do for _,y in ipairs({-1.5,1.5}) do for _,z in ipairs({0,108}) do
        v[#v+1]=Vector(x,y,z)
    end end end
    self:PhysicsInitConvex(v) self:EnableCustomCollisions(true)
    self:SetSolid(SOLID_VPHYSICS) self:SetMoveType(MOVETYPE_NONE)
    local ph=self:GetPhysicsObject() if IsValid(ph) then ph:EnableMotion(false) end
end
