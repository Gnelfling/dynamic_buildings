DynamicBuildings = DynamicBuildings or {}
local DB = DynamicBuildings
DB.Version = "0.2.0-alpha"
if SERVER then
    AddCSLuaFile("dynamic_buildings/sh_gas.lua")
    AddCSLuaFile("dynamic_buildings/cl_tools.lua")
end
include("dynamic_buildings/sh_gas.lua")
if CLIENT then include("dynamic_buildings/cl_tools.lua") end
if SERVER then
    CreateConVar("db_customers", "2", bit.bor(FCVAR_ARCHIVE,FCVAR_REPLICATED), "Maximum customers per building, including car visitors", 0, 4)
    CreateConVar("db_traffic", "0", bit.bor(FCVAR_ARCHIVE,FCVAR_REPLICATED), "Experimental scripted car visits", 0, 1)
    include("dynamic_buildings/sv_routes.lua")
    include("dynamic_buildings/sv_scene.lua")
end
