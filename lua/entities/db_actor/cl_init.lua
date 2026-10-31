include("shared.lua")
function ENT:Draw()
    local now=CurTime()
    self.BlinkAt=self.BlinkAt or (now+math.Rand(2,5))
    if self.BlinkID==nil then self.BlinkID=self:GetFlexIDByName("blink") or -1 end
    local blink=self.BlinkID
    if blink and blink>=0 then
        local t=now-self.BlinkAt
        self:SetFlexWeight(blink,t>=0 and t<0.16 and (1-math.abs(t/0.08-1)) or 0)
        if t>=0.16 then self.BlinkAt=now+math.Rand(2,6) end
    end
    if self.JawID==nil then self.JawID=self:GetFlexIDByName("jaw_drop") or -1 end
    local jaw=self.JawID
    if jaw and jaw>=0 then
        self:SetFlexWeight(jaw,self:GetNW2Float("DBTalkUntil",0)>now and math.abs(math.sin(now*13))*0.45 or 0)
    end
    self:DrawModel()
end
hook.Add("HUDPaint","DB.ActorDialogue",function()
    local ply=LocalPlayer() if not IsValid(ply) then return end
    local now=CurTime()
    for _,e in ipairs(ents.FindByClass("db_actor")) do
        if IsValid(e) and e:GetNW2Float("DBLineUntil",0)>now and e:GetPos():DistToSqr(ply:GetPos())<450^2 then
            local pos=e:GetPos()+Vector(0,0,82)
            local tr=util.TraceLine({start=ply:EyePos(),endpos=pos,filter={ply,e},mask=MASK_VISIBLE})
            local screen=pos:ToScreen()
            if screen.visible and not tr.Hit then
                draw.SimpleTextOutlined(e:GetNW2String("DBLine",""),"DermaDefaultBold",screen.x,screen.y,color_white,TEXT_ALIGN_CENTER,TEXT_ALIGN_BOTTOM,1,Color(0,0,0,220))
            end
        end
    end
end)
