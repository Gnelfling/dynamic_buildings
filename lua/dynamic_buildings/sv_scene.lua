local DB=DynamicBuildings

-- Arrivals and departures share a narrow drive. Reserve it until parked or gone.
function DB.TakeTrafficLane(building,car)
    if IsValid(building.LaneCar) and building.LaneCar~=car then return false end
    building.LaneCar=car return true
end
function DB.ReleaseTrafficLane(building,car)
    if building.LaneCar==car then building.LaneCar=nil end
end

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
    DB.ClearDoorPass(door,now)
    local passing,occupied=false,false
    for _,e in ipairs(ents.FindInSphere(door:WorldSpaceCenter(),180)) do
        if e:IsPlayer() and e:Alive() and e:GetPos():DistToSqr(door:GetPos())<100^2 then occupied=true end
        if e.DBActor and e.Route then
            local target=e.Route[e.RouteIndex]
            if target and DB.DoorCrossing(e:GetPos(),target,door:GetPos(),door.ClosedYaw or door:GetAngles().y) then passing=true end
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
function DB.ClearDoorPass(door,now)
    local owner=door.PassOwner
    if not owner then return end
    local clear=not IsValid(owner) or now>(door.PassUntil or 0)
    if not clear then
        local side=DB.DoorSide(owner:GetPos(),door:GetPos(),door.ClosedYaw or door:GetAngles().y)
        clear=math.abs(side)>65 and (side*(door.PassSide or 0)<0 or not owner.Route)
    end
    if clear then door.PassOwner=nil end
end
function DB.WaitForDoor(building,actor,target)
    for _,door in ipairs(building.Doors or {}) do
        if IsValid(door) then
            local crossing,distance=DB.DoorCrossing(actor:GetPos(),target,door:GetPos(),door.ClosedYaw or door:GetAngles().y)
            if crossing and distance<180 then
                door.DBCloseAt=CurTime()+3 DB.SetDoorState(door,true)
                DB.ClearDoorPass(door,CurTime())
                if not door.PassOwner then
                    door.PassOwner=actor
                    door.PassSide=DB.DoorSide(actor:GetPos(),door:GetPos(),door.ClosedYaw or door:GetAngles().y)
                end
                if door.PassOwner==actor then door.PassUntil=CurTime()+12
                elseif distance<110 then return true end
                -- Hold before entering the 48-unit swept leaf, but don't freeze an actor already past the plane.
                if distance>3 and distance<85 and math.abs(door.CurrentTurn or 0)<80 then return true end
            end
        end
    end
    return false
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
