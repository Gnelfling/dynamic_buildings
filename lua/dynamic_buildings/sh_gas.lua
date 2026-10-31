local DB = DynamicBuildings
DB.Gas = {
    model = "models/buildingspack/stores/4_1gas_station_b.mdl",
    center = Vector(-876, 0, 0),
    -- Survey coordinates from station A, mirrored and translated into full-lot B.
    transform = function(p) return Vector(p.x - 1232, -p.y - 264, p.z) end,
    points = {
        outside = Vector(-8,-28,2), entry = Vector(-92,-28,2),
        south = Vector(-312,-252,2), west = Vector(-316,116,2),
        east = Vector(-100,116,2), north = Vector(-220,184,2),
        browse1 = Vector(-360,216,2), browse2 = Vector(-220,48,2),
        browse3 = Vector(-244,-88,2), checkout = Vector(-310,-40,2),
        clerk = Vector(-412,-40,2), clerkexit = Vector(-412,-124,2),
        corner = Vector(-300,-132,2),
        queue1 = Vector(-260,-40,2), queue2 = Vector(-210,-40,2),
        queue3 = Vector(-160,-40,2)
    },
    browsing = {"browse1", "browse2", "browse3"},
    doors = {
        {pos=Vector(-1284,-212,55), yaw=0, openDirection=2},
        {pos=Vector(-1568,24,55), yaw=90, openDirection=2}
    },
    -- A single provisional parking visit, not a map-wide driving AI.
    carRoute = {Vector(-368,-580,2),Vector(-368,-100,2),Vector(-740,-100,2),Vector(-1148,-112,2)}
}
function DB.GasPoint(building, name)
    return building:LocalToWorld(DB.Gas.transform(DB.Gas.points[name]))
end
