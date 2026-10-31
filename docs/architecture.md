# Scene architecture — 0.5 alpha

`db_gas_station` is the spawnmenu parent and owns all child entities. It cannot be moved with a physics gun because its layout is fixed after placement. Child actors and doors are removed with their parent. The original reference addon's code and custom binary model renderer are not included.

`sh_gas.lua` defines measured model-local coordinates. Station A survey coordinates are mirrored in Y and shifted by (-1232,-264,0) for full-lot B. This transformation is essential; the no-lot and full-lot model origins differ.

`sv_routes.lua` builds a small visibility graph from measured activity/passage points. Server hull traces choose edges, excluding occupants and managed doors while planning. Movement performs a separate trace including those obstacles, so doors must actually open and occupants must yield space. There is no direct-route fallback on failure. This is bounded indoor scene navigation, not a map-wide navmesh.

Each building holds its own reservation table, FIFO checkout queue and player baskets; each actor holds its own state, route, timing and destination. Customer phases are entry, choosing, browsing, queuing, checkout and departure. Queue positions use measured points; removed customers are pruned. Failed travel preserves the occupied destination reservation.

Traffic is opt-in and off by default. Two parking destinations have cached sampled curves. Cars use native skins and model-derived axis/orientation, ground offset and rotated clearance bounds. Arrivals and departures take turns using the shared driveway; a moving car owns that lane until parked or removed. The independent car timer no longer competes with walk-in population capacity: two car bays allow two passengers in addition to the configured walk-in limit. Departures have priority over new arrivals. Cars check ahead for obstacles before their movement trace. A passenger spawns beside a clear vehicle side, walks through the shop, and returns to that point before departure. There is no seamless vehicle entry animation, wheel animation or arbitrary-map driving AI. A blocked car waits and signals; removal releases only its own lane/bay and stops its engine loop.

`sv_crowd.lua` resolves moving-actor priority by entity index and checks both possible sidesteps with the authoritative movement trace. Stationary actors retain their destinations. A transient sidestep point preserves the original route and reservation; a dynamic replan replaces it if blocked. Six added graph points provide aisle/forecourt alternatives, but every candidate edge still needs a clear trace. The movement hull now matches the physical actor hull (12-unit half-width). This does not turn off collisions or teleport actors.

The same module coordinates short nearby conversations with line of sight, a five-second pause and a 45-second pair cooldown. Replicated captions and mouth timers expire naturally; delayed replies validate both participants and their movement/proximity before speaking. Client captions are distance/visibility gated. These are original text exchanges, not recorded dialogue audio.

`sv_inventory.lua` tracks actual product entities, never a detached numerical basket. Players can own five unpaid products per building; each station allows at most 40 taken products. Shelf props become physical carryable entities for players or hand-attached visual props for actors. Unpaid items expire after 120 seconds; checkout marks player props paid and extends their expiry to 180 seconds. Return, consumption, removal and disconnection cleanup prune basket references. Restocking fills empty slots every 20 seconds. This has no currency or persistent inventory.

Six `db_ceiling_light` entities provide stock fixture props with lit/unlit skins. Using a fixture toggles its building's lamps. `cl_lighting.lua` refreshes shadowless light pools at 10 Hz: nearest eight active ceiling lights within 900 units and nearest two moving-car lights within 1200. Short lifetimes clear abandoned lights. `db_lighting 0` opts out locally. These are original, bounded lighting effects, with no electrical-grid simulation.

## Verification

`npm install` then `npm test` checks Lua 5.1 syntax and runs real addon functions in a Lua VM with mocked engine services. Coverage includes routing failures/detours, independent queues and reservations, door obstruction and rotated passage, inventory transactions/checkout, curved parking endpoints, rotated car bounds, traffic ownership/cleanup, population reservations and lighting budgets. These checks cannot replace engine collision, physics pickup, model orientation, lighting, animation or two-client networking tests. Follow the README in-game checklist after restarting the map and respawning the station.

## Doors and efficiency

`db_door` has an explicit jamb origin and a 48 x 108 collision leaf. The client fits the stock model to this geometry. Door angles include building rotation. Both doors now swing inward, opposite v0.3. A conservative swept box pauses movement on obstruction. Approaching actors request opening early and wait until the leaf is nearly open; a per-door passage owner separates opposing traffic until the actor clears the opposite side. Entry/exit points sit over 110 units from the main door plane. Manual operation has a short grace period. This reduces common door jams but still requires engine testing under crowding.

Reference-inspired efficiency work caches sequence and flex IDs, reduces behavior-decision frequency while retaining movement updates, and caches static navigation visibility edges for one second per building. Routes use distance-weighted graph search. Dynamic replans bypass the edge cache and include actors; movement always traces. No benchmark has yet been run inside GMod.

Vehicles use only the two configured nuke models, choose native skins within the installed model's actual range, and expose `PlayerColor` only for authored paint proxies. A blocked spawn is cancelled, moving cars wait on obstacles, and parked cars retry customer spawning. Browsing now takes an actual nearby product with a clear line of sight; an empty-handed customer retries another rack or leaves.

Placement preview, overlap validation, richer crowd avoidance, conversations, reach/vehicle animations and the small house remain later work. See `reference-study.md` for inspected source patterns and the limits of the asset research.
