include("shared.lua")
function ENT:Draw()
    local now=CurTime()
    self.BlinkAt=self.BlinkAt or (now+math.Rand(2,5))
    local blink=self:GetFlexIDByName("blink")
    if blink and blink>=0 then
        local t=now-self.BlinkAt
        self:SetFlexWeight(blink,t>=0 and t<0.16 and (1-math.abs(t/0.08-1)) or 0)
        if t>=0.16 then self.BlinkAt=now+math.Rand(2,6) end
    end
    local jaw=self:GetFlexIDByName("jaw_drop")
    if jaw and jaw>=0 then
        self:SetFlexWeight(jaw,self:GetNW2Float("DBTalkUntil",0)>now and math.abs(math.sin(now*13))*0.45 or 0)
    end
    self:DrawModel()
end
