local DB=DynamicBuildings

-- Called on the building; tables never live on the shared definition.
function DB.JoinQueue(b,actor)
    b.CheckoutQueue=b.CheckoutQueue or {}
    for i,e in ipairs(b.CheckoutQueue) do if e==actor then return i end end
    b.CheckoutQueue[#b.CheckoutQueue+1]=actor
    return #b.CheckoutQueue
end
function DB.LeaveQueue(b,actor)
    for i=#(b.CheckoutQueue or {}),1,-1 do
        if b.CheckoutQueue[i]==actor or not IsValid(b.CheckoutQueue[i]) then table.remove(b.CheckoutQueue,i) end
    end
end
function DB.QueuePosition(b,actor)
    DB.LeaveQueue(b,nil)
    for i,e in ipairs(b.CheckoutQueue or {}) do if e==actor then return i end end
end
function DB.SetDoorState(door,open,activator)
    if not IsValid(door) or door.DBRequestedOpen==open then return end
    door.DBRequestedOpen=open
    if door.SetDesiredOpen then door:SetDesiredOpen(open) return end
    door:Fire(open and "Open" or "Close","",0,activator,activator)
end
function DB.DoorDemand(b,door,now)
    local passing,occupied=false,false
    for _,e in ipairs(ents.FindInSphere(door:WorldSpaceCenter(),100)) do
        if e:IsPlayer() and e:Alive() then occupied=true end
        if e.DBActor and e.Route then
            local target=e.Route[e.RouteIndex]
            if target and util.DistanceToLine(e:GetPos(),target,door:GetPos())<64 then passing=true end
        end
    end
    -- Legacy prop-door recovery; explicit hinge doors own their movement state.
    -- Source prop doors expose 0=closed, 1=opening, 2=open, 3=closing.
    if not door.SetDesiredOpen and now>(door.DBRetryAt or 0) and door.GetInternalVariable then
        local state=door:GetInternalVariable("m_eDoorState")
        if (door.DBRequestedOpen and (state==0 or state==3)) or
            (door.DBRequestedOpen==false and state==2) then door.DBRequestedOpen=nil end
        door.DBRetryAt=now+2
    end
    if not passing and now<(door.ManualUntil or 0) then return end
    if passing or occupied then
        door.DBCloseAt=now+3 DB.SetDoorState(door,true)
    elseif door.DBCloseAt and now>door.DBCloseAt then
        DB.SetDoorState(door,false) door.DBCloseAt=nil
    end
end

util.AddNetworkString("db_settings")
net.Receive("db_settings",function(_,ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    if CurTime()<(ply.DBSettingsAt or 0) then return end
    ply.DBSettingsAt=CurTime()+0.2
    local customers=math.Clamp(net.ReadUInt(3),0,4)
    local traffic=net.ReadBool()
    GetConVar("db_customers"):SetInt(customers)
    GetConVar("db_traffic"):SetBool(traffic)
end)

concommand.Add("db_inspect_cars",function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local function report(s) if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE,s) else print(s) end end
    for _,model in ipairs(DB.Gas.carModels) do
        if util.IsValidModel(model) then
            local e=ents.Create("prop_dynamic")
            if IsValid(e) then
                e:SetModel(model)
                report(model.." | native skins: "..e:SkinCount().." | bounds: "..tostring(e:OBBMins()).." / "..tostring(e:OBBMaxs()))
                e:Remove()
            end
        else report(model.." | NOT INSTALLED") end
    end
end)
