local DB = DynamicBuildings
DB.Gas = {
    model = "models/buildingspack/stores/4_1gas_station_b.mdl",
    center = Vector(-876, 0, 0),
    -- Survey coordinates from station A, mirrored and translated into full-lot B.
    transform = function(p) return Vector(p.x - 1232, -p.y - 264, p.z) end,
    points = {
        outside = Vector(64,-28,2), entry = Vector(-172,-28,2),
        south = Vector(-312,-252,2), west = Vector(-316,116,2),
        east = Vector(-100,116,2), north = Vector(-220,184,2),
        browse1 = Vector(-360,216,2), browse2 = Vector(-220,48,2),
        browse3 = Vector(-244,-88,2), checkout = Vector(-310,-40,2),
        clerk = Vector(-412,-40,2), clerkexit = Vector(-412,-124,2),
        corner = Vector(-300,-132,2),
        aisle_south = Vector(-220,-192,2), aisle_east = Vector(-112,-120,2),
        aisle_north = Vector(-124,192,2), aisle_west = Vector(-300,48,2),
        forecourt_north = Vector(96,96,2), forecourt_south = Vector(96,-180,2),
        queue1 = Vector(-260,-40,2), queue2 = Vector(-210,-40,2),
        queue3 = Vector(-160,-40,2)
    },
    browsing = {"browse1", "browse2", "browse3"},
    doors = {
        -- Reverse the previous swing: the leaves now open into the shop.
        {pos=Vector(-1284,-212,1), yaw=-90, swing=-90},
        {pos=Vector(-1568,24,1), yaw=0, swing=-90}
    },
    ceilingLights = {Vector(-1540,-460,126),Vector(-1400,-460,126),
        Vector(-1540,-265,126),Vector(-1400,-265,126),Vector(-1540,-70,126),Vector(-1400,-70,126)},
    carModels = {"models/props/generic_propcars/nuke_station_wagon02_low.mdl",
        "models/props/generic_propcars/nuke_sedan01_low.mdl"}
}
DB.Gas.parking={
    {Vector(-368,-580,2),Vector(-368,-100,2),Vector(-760,-100,2),Vector(-940,-112,2),Vector(-1148,-112,2)},
    {Vector(-368,-580,2),Vector(-368,-100,2),Vector(-780,-100,2),Vector(-920,-430,2),Vector(-1148,-432,2)}
}
function DB.BuildCarPath(controls)
    local out={controls[1]}
    for i=1,#controls-1 do
        local a,b=controls[math.max(1,i-1)],controls[i]
        local c,d=controls[i+1],controls[math.min(#controls,i+2)]
        local length=math.sqrt((c.x-b.x)^2+(c.y-b.y)^2+(c.z-b.z)^2)
        local samples=math.max(4,math.ceil(length/24))
        for n=1,samples do
            local t=n/samples
            local function v(k) return 0.5*((2*b[k])+(-a[k]+c[k])*t+(2*a[k]-5*b[k]+4*c[k]-d[k])*t*t+(-a[k]+3*b[k]-3*c[k]+d[k])*t*t*t) end
            out[#out+1]=Vector(v("x"),v("y"),v("z"))
        end
    end
    return out
end
function DB.CarTraceBounds(mn,mx,yaw)
    local c,s=math.cos(math.rad(yaw)),math.sin(math.rad(yaw))
    local lo,hi=Vector(math.huge,math.huge,mn.z+6),Vector(-math.huge,-math.huge,mx.z)
    for _,x in ipairs({mn.x,mx.x}) do for _,y in ipairs({mn.y,mx.y}) do
        local xx,yy=x*c-y*s,x*s+y*c
        lo.x=math.min(lo.x,xx) lo.y=math.min(lo.y,yy) hi.x=math.max(hi.x,xx) hi.y=math.max(hi.y,yy)
    end end
    return lo,hi
end
-- A closed leaf runs along +X in its own frame; distance is to its plane.
-- Pure geometry: used before movement so actors wait outside the swing envelope.
function DB.DoorCrossing(a,b,hinge,yaw)
    local c,s=math.cos(math.rad(yaw)),math.sin(math.rad(yaw))
    local function project(p)
        local x,y=p.x-hinge.x,p.y-hinge.y
        return x*c+y*s,-x*s+y*c
    end
    local ax,ay=project(a) local bx,by=project(b)
    if ay*by>0 or math.abs(ay-by)<0.001 then return false end
    local t=ay/(ay-by) local along=ax+(bx-ax)*t
    return along>=-18 and along<=66 and math.abs(a.z-hinge.z)<110,math.abs(ay)
end
function DB.DoorSide(p,hinge,yaw)
    local angle=math.rad(yaw)
    return -(p.x-hinge.x)*math.sin(angle)+(p.y-hinge.y)*math.cos(angle)
end
function DB.GasPoint(building, name)
    return building:LocalToWorld(DB.Gas.transform(DB.Gas.points[name]))
end
function DB.ChooseCarModel()
    local available={}
    for _,model in ipairs(DB.Gas.carModels) do if util.IsValidModel(model) then available[#available+1]=model end end
    if #available==0 then return nil end
    return available[math.random(1,#available)]
end
function DB.ChooseCarSkin(count)
    return math.random(0,math.max(0,count-1))
end
