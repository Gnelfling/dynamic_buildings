-- Refresh a bounded set near the viewer; never allocate a light per shelf prop.
local fixtures,cars,nextScan,nextLight={},{},0,0
local enabled=CreateClientConVar("db_lighting","1",true,false,"Enable Dynamic Buildings lights")
hook.Add("Think","DB.CeilingLighting",function()
    local now=CurTime()
    if now<nextLight then return end nextLight=now+0.1
    if not enabled:GetBool() then return end
    if now>=nextScan then fixtures=ents.FindByClass("db_ceiling_light") cars=ents.FindByClass("db_visit_car") nextScan=now+0.5 end
    local eye=EyePos() local candidates={}
    for _,e in ipairs(fixtures) do
        if IsValid(e) then
            local b=e:GetBuilding() local d=e:GetPos():DistToSqr(eye)
            if IsValid(b) and b:GetLightsOn() and d<900^2 then candidates[#candidates+1]={e=e,d=d} end
        end
    end
    table.sort(candidates,function(a,b) return a.d<b.d end)
    for i=1,math.min(8,#candidates) do
        local e=candidates[i].e local l=DynamicLight(e:EntIndex())
        if l then
            l.pos=e:GetPos()-Vector(0,0,12) l.r=255 l.g=236 l.b=205
            l.brightness=1.6 l.size=250 l.decay=0 l.dietime=now+0.22
        end
    end
    local vehicles={}
    for _,e in ipairs(cars) do
        if IsValid(e) and e:GetVisitState()~="Parked" then
            local d=e:GetPos():DistToSqr(eye)
            if d<1200^2 then vehicles[#vehicles+1]={e=e,d=d} end
        end
    end
    table.sort(vehicles,function(a,b) return a.d<b.d end)
    for i=1,math.min(2,#vehicles) do
        local e=vehicles[i].e local l=DynamicLight(e:EntIndex())
        if l then
            local mn,mx=e:GetModelBounds()
            local z=mn.z+(mx.z-mn.z)*0.4
            local p=e:GetNW2Float("DBForwardYaw",0)==0 and Vector(mx.x+30,(mn.y+mx.y)/2,z) or Vector((mn.x+mx.x)/2,mx.y+30,z)
            l.pos=e:LocalToWorld(p) l.r=255 l.g=246 l.b=218
            l.brightness=1.5 l.size=210 l.decay=0 l.dietime=now+0.22
        end
    end
end)
