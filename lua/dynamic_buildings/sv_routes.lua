local DB = DynamicBuildings
local mins, maxs = Vector(-12,-12,1), Vector(12,12,70)
function DB.TraceActor(building, actor, a, b, planning)
    return util.TraceHull({start=a,endpos=b,mins=mins,maxs=maxs,mask=MASK_PLAYERSOLID,
        filter=function(e)
            if e==actor then return false end
            if planning and e.DBManagedDoor then return false end
            if planning==true and e.DBActor then return false end
            return true
        end})
end
function DB.FindRoute(building, actor, destination, avoidActors)
    local goal
    if destination=="vehicle" and actor.VisitCar and actor.VisitCar.PassengerPoint then goal=actor.VisitCar.PassengerPoint
    elseif DB.Gas.points[destination] then goal=DB.GasPoint(building,destination) end
    if not goal then return nil end
    local start = actor:GetPos()
    local function clear(a,b)
        local tr=DB.TraceActor(building,actor,a,b,avoidActors and "dynamic" or true)
        return not tr.Hit and not tr.StartSolid
    end
    if clear(start,goal) then return {goal} end
    local nodes={start,goal}
    local names={} for name in pairs(DB.Gas.points) do names[#names+1]=name end table.sort(names)
    for _,name in ipairs(names) do nodes[#nodes+1]=building:LocalToWorld(DB.Gas.transform(DB.Gas.points[name])) end
    local now=CurTime and CurTime() or 0
    if not building.DBRouteCache or now>=building.DBRouteCache.expires then
        building.DBRouteCache={expires=now+1,edges={}}
    end
    local function edge(i,j)
        if avoidActors or i<3 or j<3 then return clear(nodes[i],nodes[j]) end
        local key=math.min(i,j)..":"..math.max(i,j)
        local edges=building.DBRouteCache.edges
        if edges[key]==nil then edges[key]=clear(nodes[i],nodes[j]) end
        return edges[key]
    end
    local distances,parent,visited={[1]=0},{[1]=0},{}
    while true do
        local i,best
        for k,d in pairs(distances) do if not visited[k] and (not best or d<best) then i,best=k,d end end
        if not i then break end
        if i==2 then
            local route,k={},2
            while k~=1 do table.insert(route,1,nodes[k]) k=parent[k] end
            return route
        end
        visited[i]=true
        for j=2,#nodes do
            if not visited[j] and edge(i,j) then
                local a,b=nodes[i],nodes[j]
                local cost=best+math.sqrt((a.x-b.x)^2+(a.y-b.y)^2+(a.z-b.z)^2)
                if not distances[j] or cost<distances[j] then distances[j]=cost parent[j]=i end
            end
        end
    end
    return nil -- Never walk directly through a failed route.
end
