AddCSLuaFile("shared.lua") AddCSLuaFile("cl_init.lua") include("shared.lua")
local DB=DynamicBuildings
function ENT:Initialize()
    if not IsValid(self.DBBuilding) or not self.SupportPos then self:Remove() return end
    self:SetModel(self.ItemModel or "models/props_junk/PopCan01a.mdl")
    self:SetItemLabel(self.Label or "Soda can")
    self:SetPos(self.SupportPos-Vector(0,0,self:OBBMins().z))
    self:SetMoveType(MOVETYPE_NONE) self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(self:OBBMins(),self:OBBMaxs())
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON) self:SetUseType(SIMPLE_USE)
end
function ENT:Take(buyer)
    local b=self.DBBuilding
    if self.Taken or not IsValid(b) or not IsValid(buyer) then return false end
    if DB.LooseProducts(b)>=40 then return false,"busy" end
    if buyer:IsPlayer() then
        if not buyer:Alive() or not DB.AddCartItem(b,buyer,self) then return false end
    elseif buyer.DBActor then
        if IsValid(buyer.CarriedProduct) then return false end
    else return false end
    self.Taken=true self.Buyer=buyer self:SetItemBuyer(buyer) self:SetTakenItem(true)
    self.ExpiresAt=CurTime()+120
    if b.Stock and b.Stock[self.StockKey]==self then b.Stock[self.StockKey]=nil end
    self:EmitSound("buttons/lightswitch2.wav",50)
    if buyer:IsPlayer() then
        self:PhysicsInit(SOLID_VPHYSICS) self:SetMoveType(MOVETYPE_VPHYSICS) self:SetSolid(SOLID_VPHYSICS)
        local ph=self:GetPhysicsObject() if IsValid(ph) then ph:EnableMotion(true) ph:Wake() end
        buyer:PickupObject(self)
        buyer:ChatPrint(self:GetItemLabel().." picked up. Visit the clerk; Walk + E on the dropped item returns it.")
    else
        buyer.CarriedProduct=self buyer:DeleteOnRemove(self)
        self:SetSolid(SOLID_NONE) self:SetMoveType(MOVETYPE_NONE) self:DrawShadow(false)
        local hand=buyer:LookupAttachment("anim_attachment_RH")
        if hand and hand>0 then
            self:SetParent(buyer,hand) self:SetLocalPos(Vector(2,0,0)) self:SetLocalAngles(Angle(0,0,0))
        else
            local bone=buyer:LookupBone("ValveBiped.Bip01_R_Hand")
            if bone then self:FollowBone(buyer,bone) self:SetLocalPos(Vector(2,0,0)) self:SetLocalAngles(Angle(0,0,0))
            else self:SetParent(buyer) self:SetLocalPos(Vector(10,-8,48)) self:SetLocalAngles(Angle(0,0,0)) end
        end
    end
    self:NextThink(CurTime()+1) return true
end
function ENT:Use(ply)
    local b=self.DBBuilding
    if not IsValid(b) or not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end
    if ply:GetPos():DistToSqr(self:GetPos())>128^2 or CurTime()<(self.UseAt or 0) then return end
    self.UseAt=CurTime()+0.4
    if not self.Taken then
        local success,reason=self:Take(ply)
        if not success then ply:ChatPrint(reason=="busy" and "Too many loose items are already out. Return an item or try again shortly." or "Your basket is full. Visit the clerk to check out.") end
    elseif self.Buyer==ply then
        if self:GetPurchased() then
            local label=self:GetItemLabel()
            ply:EmitSound("npc/barnacle/barnacle_gulp1.wav",50) self:Remove()
            ply:ChatPrint("Enjoyed your "..label:lower()..".")
        elseif ply:KeyDown(IN_WALK) then
            DB.ForgetCartItem(b,ply,self) self:Remove()
            ply:ChatPrint("Item returned. It will be restocked shortly.")
        else ply:PickupObject(self) end
    end
end
function ENT:Think()
    if self.Taken and (not IsValid(self.Buyer) or CurTime()>(self.ExpiresAt or 0)) then self:Remove() return end
    self:NextThink(CurTime()+1) return true
end
function ENT:OnRemove()
    local b=self.DBBuilding
    if IsValid(b) then
        if self.Buyer then DB.ForgetCartItem(b,self.Buyer,self) end
        if b.Stock and b.Stock[self.StockKey]==self then b.Stock[self.StockKey]=nil end
    end
end
