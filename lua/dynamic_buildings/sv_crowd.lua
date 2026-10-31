local DB=DynamicBuildings
-- One moving actor yields, rather than both making the same retry forever.
function DB.ShouldYield(actor,other)
    return IsValid(other) and other.DBActor and (not other.Route or actor:EntIndex()>other:EntIndex())
end
function DB.CrowdDetour(b,actor,other,target)
    if not DB.ShouldYield(actor,other) then return end
    local pos=actor:GetPos() local delta=target-pos delta.z=0
    if delta:Length()<1 then return end
    local forward=delta:GetNormalized() local side=Vector(-forward.y,forward.x,0)
    for _,sign in ipairs({1,-1}) do
        local point=pos+side*(48*sign)+forward*24
        local tr=DB.TraceActor(b,actor,pos,point,false)
        if not tr.Hit and not tr.StartSolid then return point end
    end
end
function DB.Say(actor,line,now)
    actor:SetNW2String("DBLine",line) actor:SetNW2Float("DBLineUntil",now+3)
    actor:SetNW2Float("DBTalkUntil",now+2)
end
function DB.TryConversation(b,actor,now)
    if actor.Route or now<(actor.ChatAt or 0) or (actor.State~="browsing" and actor.State~="working" and actor.State~="choose") then return end
    actor.ChatAt=now+8
    for other in pairs(b.Children) do
        if other~=actor and IsValid(other) and other.DBActor and not other.Route and now>=(other.ChatAt or 0) and
            (other.State=="browsing" or other.State=="working" or other.State=="choose") and actor:GetPos():DistToSqr(other:GetPos())<150^2 then
            local tr=util.TraceLine({start=actor:GetPos()+Vector(0,0,50),endpos=other:GetPos()+Vector(0,0,50),filter={actor,other},mask=MASK_SOLID})
            if not tr.Hit then
                actor.ChatAt=now+45 other.ChatAt=now+45
                actor.ChatPartner=other other.ChatPartner=actor
                actor.ChatUntil=now+5 other.ChatUntil=now+5
                actor.WaitUntil=math.max(actor.WaitUntil or 0,now+5)
                other.WaitUntil=math.max(other.WaitUntil or 0,now+5)
                local lines=actor.Role=="clerk" and {"Finding everything you need?","Yes, thank you!"} or
                    (other.Role=="clerk" and {"Hello! Just picking up a few things.","Take your time."} or {"Busy day today?","Just stopping for a drink."})
                DB.Say(actor,lines[1],now)
                timer.Simple(2.2,function()
                    if IsValid(b) and IsValid(actor) and IsValid(other) and not actor.Route and not other.Route and actor:GetPos():DistToSqr(other:GetPos())<150^2 then DB.Say(other,lines[2],CurTime()) end
                end)
                return true
            end
        end
    end
end
function DB.WalkInCount(b)
    local count=0
    for e in pairs(b.Children) do if IsValid(e) and e.DBActor and e.Role~="clerk" and not IsValid(e.VisitCar) then count=count+1 end end
    return count
end
