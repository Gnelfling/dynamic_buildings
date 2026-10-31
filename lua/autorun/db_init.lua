DynamicBuildings = DynamicBuildings or {}
local DB = DynamicBuildings
DB.Version = "0.1.0-alpha"
if SERVER then
    AddCSLuaFile("dynamic_buildings/sh_gas.lua")
    AddCSLuaFile("dynamic_buildings/cl_tools.lua")
end
include("dynamic_buildings/sh_gas.lua")
if CLIENT then include("dynamic_buildings/cl_tools.lua") end
if SERVER then
    CreateConVar("db_customers", "2", FCVAR_ARCHIVE, "Maximum pedestrian customers per building", 0, 4)
    CreateConVar("db_traffic", "0", FCVAR_ARCHIVE, "Experimental scripted car visits", 0, 1)
    include("dynamic_buildings/sv_routes.lua")
end
