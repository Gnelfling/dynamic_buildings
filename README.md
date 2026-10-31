# Dynamic Buildings

An independent Garry's Mod addon for inhabited buildings. Version 0.4 alpha adds inward-opening doors with single-file actor passage, physical shelf shopping, customer-car handoff, and ceiling fixtures with switchable lights. **These new changes still need in-game acceptance testing.**

## Install

1. Place this repository in `garrysmod/addons/dynamic_buildings`.
2. Install your building pack separately. Its addon root must contain `models/buildingspack/stores/4_1gas_station_b.mdl` and the matching materials/mesh/physics files. For the supplied local `house models` folder, use that folder as a separate local addon (the `models` and `materials` directories must be immediately inside it).
3. Start/restart a Sandbox map with a large flat area. Q menu → Entities → Dynamic Buildings → Gas Station.
4. E on shelf stock physically picks up the item (maximum five unpaid items). Drop it using normal GMod carry controls; E picks it up again. Walk + E on your dropped unpaid item returns it. E on the clerk pays for that station's basket; E on your purchased item consumes it. This is a free roleplay interaction, not a money system or persistent inventory.
5. E greets other occupants. Undo/removing the parent station removes its children.
6. Look up at a ceiling fixture and press E to toggle that station's lights. `db_lighting 0` disables the extra lighting locally for performance.

The repository does not redistribute third-party building models or textures. This is not a Workshop dependency declaration: servers must distribute their chosen asset pack separately. Verify its author's reuse terms before publishing bundled assets.

## Current behavior

- Full-lot B model, placed using measured coordinates and footprint support probes.
- One clerk; customers enter, reserve browsing destinations, join a FIFO checkout queue and leave.
- Visibility-graph navigation and server hull sweeps. Failed routes retry; occupants never deliberately teleport through walls.
- Doors swing inward (opposite v0.3), pause when blocked, and open early for approaching actors. Citizens wait outside the swept leaf and use a single-file passage reservation to reduce head-on jams. Entry/exit waiting points are moved beyond the sweep.
- Ownership-based cleanup, separate state per station, clerk respawn if removed.
- Idle gestures, browsing/clerk facing, greetings, blinking and approximate talking mouth movement.
- Thirty stock props on two racks, including cans and lower-tier cartons; 20-second restocking, per-player per-building baskets, return/consume actions and clerk checkout. Citizens take nearby stock and carry a visible item to checkout. Empty-handed visitors try another shelf or leave.
- Taken stock expires after two minutes; paid player items after three. There is a 40-loose-item budget per station. All items remain owned by the station for cleanup, including paid items.
- Six ceiling fixture props with native lit/unlit skins. Nearest-viewer lighting is refreshed at 10 Hz with a client-wide cap of eight ceiling lights plus two moving-vehicle light pools. These are shadowless dynamic light pools, not projected headlight beams.
- Population limits include incoming-car reservations and customers spawned by car visits. Walking and car arrivals alternate when space allows. Traffic remains experimental/off by default.
- Optional `db_traffic 1`: up to two reserved parking destinations, smooth sampled approach paths, varied speeds, reversing, engine sound and a rate-limited warning beep (E on a car also signals). A shared-drive reservation keeps incoming and outgoing cars from meeting head-on. Passengers spawn at a clear side of the parked car, walk to the shop and return before departure. Requires `models/props/generic_propcars/nuke_station_wagon02_low.mdl` or `models/props/generic_propcars/nuke_sedan01_low.mdl`. Uses native skins and authored PlayerColor paint proxies. Admin command `db_inspect_cars` reports availability/skins. Model-derived rotated bounds replace the old circular trace. Traffic is still experimental and off by default; there is no wheel/door animation or arbitrary-map driving AI.

Admin settings: Utilities → User → Dynamic Buildings. The server validates admin access and clamps incoming values. Server console also supports `db_customers 0..4` (default 2), `db_traffic 0/1` (default 0), `sbox_maxdb_buildings` (default 3). Settings apply to subsequent visits; reducing population does not delete current customers.

## In-game acceptance checks

- Missing model: clear message and no station spawned.
- Spawn on level ground; verify full-lot collisions and both door pivots/swing. Door placement is provisional.
- Watch a customer enter, browse, pay and leave; block a route and verify they stop.
- Watch opposing citizens use the same doorway and check they wait for the open leaf and for each other. Remove a passage owner and verify the reservation clears.
- Watch multiple customers queue in order, then remove the first customer and verify the next advances. Take five items; a sixth should be refused. Return one item, check out the rest, and consume a paid item. Confirm two players/two stations have separate baskets and NPCs carry actual stock.
- Restart the map and respawn the station. Verify the doors align with both jambs, open inward, stop for a person/prop, and close fully. Test station rotations 0, 90, 180 and 270 and two clients.
- Toggle ceiling fixtures and verify their skins and lights agree on both clients. Check the lamp positions under the roof and stock on both racks.
- Spawn two stations and verify reservations stay independent.
- Undo/remover/cleanup with customers and a parked visit; no children should remain.
- Enable traffic after verifying model orientation, tire elevation, parking footprint and curved path clearance. Follow a passenger from the car to checkout and back. With two cars, verify departures wait while an arrival owns the drive. Test with a one-customer limit. Block the drive, remove a car, and undo a station while a passenger is shopping. Cars wait rather than push obstacles; unusual map geometry can still prevent a visit.

## Next milestones

Placement ghost/overlap validation; better crowd avoidance; richer stock and reach animations; conversations; vehicle wheel/door animations and traffic visibility handling; the small house. No destruction or electrical-grid simulation.

Implementation is original; the prior addon was studied as a behavioral reference, not copied. Native Source model rendering is used.
