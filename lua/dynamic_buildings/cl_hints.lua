local hint=CreateClientConVar("db_hints","1",true,false,"Show nearby building interaction hints")
hook.Add("HUDPaint","DB.InteractionHints",function()
    if not hint:GetBool() or not IsValid(LocalPlayer()) then return end
    local tr=LocalPlayer():GetEyeTrace() local e=tr.Entity
    if not IsValid(e) or tr.HitPos:DistToSqr(LocalPlayer():EyePos())>180^2 then return end
    local label,action
    if e:GetClass()=="db_product" then label="Shelf drink" action="E  •  Add to basket"
    elseif e:GetClass()=="db_actor" then
        label=e:GetActivity()=="working" and "Clerk" or "Customer"
        action=label=="Clerk" and "E  •  Checkout / talk" or "E  •  Say hello"
    elseif e:GetClass()=="db_door" then label="Door" action="E  •  Open / close"
    elseif e:GetClass()=="db_visit_car" then label="Customer vehicle" action=e:GetVisitState() end
    if not label then return end
    draw.RoundedBox(6,ScrW()/2-160,ScrH()*0.73,320,62,Color(15,20,26,220))
    draw.SimpleText(label,"DermaDefaultBold",ScrW()/2,ScrH()*0.73+12,color_white,TEXT_ALIGN_CENTER)
    draw.SimpleText(action,"DermaDefault",ScrW()/2,ScrH()*0.73+35,Color(190,215,225),TEXT_ALIGN_CENTER)
end)
