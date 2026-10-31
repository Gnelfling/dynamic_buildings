local DB=DynamicBuildings
function DB.LooseProducts(building)
    local n=0
    for e in pairs(building.Children or {}) do if IsValid(e) and e.DBProduct and e.Taken then n=n+1 end end
    return n
end
function DB.CartCount(building,buyer)
    local cart=building.Carts[buyer]
    if type(cart)~="table" then building.Carts[buyer]=nil return 0 end
    local n=0
    for item in pairs(cart) do
        if IsValid(item) and item.Buyer==buyer and not item:GetPurchased() then n=n+1
        else cart[item]=nil end
    end
    if n==0 then building.Carts[buyer]=nil end
    return n
end
function DB.AddCartItem(building,buyer,item)
    if DB.CartCount(building,buyer)>=5 then return false end
    building.Carts[buyer]=building.Carts[buyer] or {}
    building.Carts[buyer][item]=true return true
end
function DB.ForgetCartItem(building,buyer,item)
    local cart=building.Carts[buyer]
    if type(cart)=="table" then cart[item]=nil end
end
function DB.PickStock(building,actor)
    local best,dist
    for _,item in pairs(building.Stock or {}) do
        if IsValid(item) and not item.Taken then
            local d=item:GetPos():DistToSqr(actor:GetPos())
            if d<112^2 and (not dist or d<dist) then
                local tr=util.TraceLine({start=actor:GetPos()+Vector(0,0,48),endpos=item:WorldSpaceCenter(),filter=actor,mask=MASK_SOLID})
                if not tr.Hit or tr.Entity==item then best,dist=item,d end
            end
        end
    end
    return best
end
