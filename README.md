# Dynamic Buildings

An independent Garry's Mod addon for inhabited buildings. Version 0.3 alpha: a full-lot gas station with jamb-hinged doors, queued customers, shelf drinks, player checkout and optional sedan/station-wagon visits. **The new door and vehicle implementations need in-game testing.**

## Install

1. Place this repository in `garrysmod/addons/dynamic_buildings`.
2. Install your building pack separately. Its addon root must contain `models/buildingspack/stores/4_1gas_station_b.mdl` and the matching materials/mesh/physics files. For the supplied local `house models` folder, use that folder as a separate local addon (the `models` and `materials` directories must be immediately inside it).
3. Start/restart a Sandbox map with a large flat area. Q menu → Entities → Dynamic Buildings → Gas Station.
4. E on a shelf drink adds it to your basket (maximum five). E on the clerk checks out that station's basket. This is a free roleplay interaction, not a money system or persistent inventory. Shelves replenish every 20 seconds.
5. E greets other occupants. Undo/removing the parent station removes its children.

The repository does not redistribute third-party building models or textures. This is not a Workshop dependency declaration: servers must distribute their chosen asset pack separately. Verify its author's reuse terms before publishing bundled assets.

## Current behavior

- Full-lot B model, placed using measured coordinates and footprint support probes.
- One clerk; customers enter, reserve browsing destinations, join a FIFO checkout queue and leave.
- Visibility-graph navigation and server hull sweeps. Failed routes retry; occupants never deliberately teleport through walls.
- Doors use explicit measured jamb pivots, fitted native door visuals and matching custom convex collision. They swing outward, pause when blocked, open for passing actors/nearby players, and close after the area clears.
- Ownership-based cleanup, separate state per station, clerk respawn if removed.
- Idle gestures, browsing/clerk facing, greetings, blinking and approximate talking mouth movement.
- Fifteen shelf drinks, replenishment, per-player per-building baskets and clerk checkout.
- Population limits include customers spawned by car visits. Traffic remains experimental/off by default.
- Optional `db_traffic 1` prototype: one scripted car at a time, parked visit and return route. Requires `models/props/generic_propcars/nuke_station_wagon02_low.mdl` or `models/props/generic_propcars/nuke_sedan01_low.mdl`. Uses installed native skins and supports model-authored PlayerColor paint proxies. Run admin/server command `db_inspect_cars` to report availability/skin counts. Defaults off pending clearance tests. No wheel/door animation or driving simulation yet. Driver currently starts at the shop entrance, not at the car door.

Admin settings: Utilities → User → Dynamic Buildings. The server validates admin access and clamps incoming values. Server console also supports `db_customers 0..4` (default 2), `db_traffic 0/1` (default 0), `sbox_maxdb_buildings` (default 3). Settings apply to subsequent visits; reducing population does not delete current customers.

## In-game acceptance checks

- Missing model: clear message and no station spawned.
- Spawn on level ground; verify full-lot collisions and both door pivots/swing. Door placement is provisional.
- Watch a customer enter, browse, pay and leave; block a route and verify they stop.
- Watch multiple customers queue in order, then remove the first customer and verify the next advances. Take five drinks; a sixth should be refused until checkout. Confirm two players/two stations have separate baskets.
- Restart the map and respawn the station: old instances retain their old door type. Verify the new doors align with both jambs, open outward, stop for a person/prop, and close fully. Test at station rotations 0, 90, 180 and 270 degrees and with two clients.
- Spawn two stations and verify reservations stay independent.
- Undo/remover/cleanup with customers and a parked visit; no children should remain.
- Enable traffic only after verifying model orientation, tire elevation, parking footprint and swept hull clearance. Cars currently follow straight segments and may wait indefinitely when blocked.

## Next milestones

Placement ghost/overlap validation; queue obstruction recovery; richer stock and purchase animations; conversations; car door/occupant handoff, turning arcs and traffic visibility handling; the small house. No destruction, electrical grid or custom lighting.

Implementation is original; the prior addon was studied as a behavioral reference, not copied. Native Source model rendering is used.
