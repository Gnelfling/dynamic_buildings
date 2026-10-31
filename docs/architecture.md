# First milestone

`db_gas_station` is the spawnmenu parent and owns all child entities. It cannot be moved with a physics gun because its layout is fixed after placement. Child actors and doors are removed with their parent. The original reference addon's code and custom binary model renderer are not included.

`sh_gas.lua` defines measured model-local coordinates. Station A survey coordinates are mirrored in Y and shifted by (-1232,-264,0) for full-lot B. This transformation is essential; the no-lot and full-lot model origins differ.

`sv_routes.lua` builds a small visibility graph from measured activity/passage points. Server hull traces choose edges, excluding occupants and managed doors while planning. Movement performs a separate trace including those obstacles, so doors must actually open and occupants must yield space. There is no direct-route fallback on failure. This is bounded indoor scene navigation, not a map-wide navmesh.

Each building holds its own reservation table, FIFO checkout queue and player baskets; each actor holds its own state, route, timing and destination. Customer phases are entry, choosing, browsing, queuing, checkout and departure. Queue positions use measured points; removed customers are pruned. Failed travel preserves the occupied destination reservation.

Traffic is opt-in prototype work. One visit car per building follows measured local waypoints and waits on hull obstruction. It creates an entrance customer when parked and departs when that customer completes its visit. It is not yet a seamless vehicle exit/entry animation and is disabled by default.

## Verification

`npm install` then `npm test` checks Lua 5.1 syntax and runs the actual route planner in a Lua VM with mock trace results: direct visibility, an obstruction requiring a detour, and an unreachable destination. These checks cannot replace engine collision, animation or networking tests. Follow the README in-game checklist before treating this alpha as release-ready.

## Immediate next pass

Version 0.2 adds reverse-swing door configuration, state-based door inputs, shelf drinks, player basket checkout, queue positions, gestures, facial presentation and admin settings. Verify these changes against engine collision and the measured shelves. Placement preview, overlap validation, deeper conversations and car/driver handoff remain later work.
