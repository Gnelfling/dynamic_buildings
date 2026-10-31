DynamicBuildings = DynamicBuildings or {}
local DB = DynamicBuildings
DB.Version = "0.5.0-alpha"
if SERVER then
    AddCSLuaFile("dynamic_buildings/sh_gas.lua")
    AddCSLuaFile("dynamic_buildings/cl_tools.lua")
    AddCSLuaFile("dynamic_buildings/cl_hints.lua")
    AddCSLuaFile("dynamic_buildings/cl_lighting.lua")
end
include("dynamic_buildings/sh_gas.lua")
if CLIENT then
    include("dynamic_buildings/cl_tools.lua") include("dynamic_buildings/cl_hints.lua")
    include("dynamic_buildings/cl_lighting.lua")
end
if SERVER then
    CreateConVar("db_customers", "2", bit.bor(FCVAR_ARCHIVE,FCVAR_REPLICATED), "Maximum walk-in customers per building; car passengers have separate capacity", 0, 4)
    CreateConVar("db_traffic", "0", bit.bor(FCVAR_ARCHIVE,FCVAR_REPLICATED), "Experimental scripted car visits", 0, 1)
    include("dynamic_buildings/sv_routes.lua")
    include("dynamic_buildings/sv_scene.lua")
    include("dynamic_buildings/sv_inventory.lua")
    include("dynamic_buildings/sv_crowd.lua")
    CreateConVar("db_cars","2",bit.bor(FCVAR_ARCHIVE,FCVAR_REPLICATED),"Maximum visiting cars per station (two measured bays)",0,2)
end
