local DB = DynamicBuildings
local mins, maxs = Vector(-16,-16,1), Vector(16,16,70)
function DB.TraceActor(building, actor, a, b, planning)
    return util.TraceHull({start=a,endpos=b,mins=mins,maxs=maxs,mask=MASK_PLAYERSOLID,
        filter=function(e)
            if e==actor then return false end
            if planning and (e.DBActor or e.DBManagedDoor) then return false end
            return true
        end})
end
function DB.FindRoute(building, actor, destination)
    local goal = DB.GasPoint(building,destination)
    local start = actor:GetPos()
    local function clear(a,b)
        local tr=DB.TraceActor(building,actor,a,b,true)
        return not tr.Hit and not tr.StartSolid
    end
    if clear(start,goal) then return {goal} end
    local nodes={start,goal}
    for _,p in pairs(DB.Gas.points) do nodes[#nodes+1]=building:LocalToWorld(DB.Gas.transform(p)) end
    local queue, parent, head={1},{[1]=0},1
    while head<=#queue do
        local i=queue[head] head=head+1
        for j=2,#nodes do
            if parent[j]==nil and clear(nodes[i],nodes[j]) then
                parent[j]=i queue[#queue+1]=j
                if j==2 then
                    local route, k={},2
                    while k~=1 do table.insert(route,1,nodes[k]) k=parent[k] end
                    return route
                end
            end
        end
    end
    return nil -- Never walk directly through a failed route.
end
