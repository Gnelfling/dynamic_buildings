# Changes

## 0.3.0 alpha

- Replace engine prop doors with explicit 48 x 108 jamb-hinged doors. Native door model geometry is fitted to the hinge coordinate system on the client; matching convex collision is built in both realms. Door leaves swing outward from measured jambs and pause on obstruction. Manual operation has a short automatic-close grace period.
- Use the requested `nuke_station_wagon02_low.mdl` and `nuke_sedan01_low.mdl` models when installed. Select valid native skins; support author-supplied PlayerColor proxies without tinting the entire car. Missing assets produce a one-time owner message. `db_inspect_cars` reports installed models, native skin counts and bounds to admins/server console.
- Derive vehicle ground offset and conservative turning clearance from model bounds; add acceleration, slower turns, lower parked update frequency, and retry customer creation. An unserved parked car leaves after 60 seconds rather than waiting forever.
- Cache actor sequence/flex lookups, match walk playback speed to travel speed, throttle routine decisions, cache static visibility edges for one second, and use distance-weighted route selection. Actual movement still sweeps for newly placed obstacles.
- Add nearby interaction hints (`db_hints 0` hides them). Extend regression tests with actual custom door movement and obstruction checks.
- Car wheel/door animations, curved parking arcs, seamless driver handoff and arbitrary-map road navigation remain out of scope for this alpha. In-game verification is still required.

## 0.2.0 alpha

- Set both doors to reverse swing using Source's `opendir=2`; activate them explicitly. Automatic input commands are no longer issued every quarter-second. Moving actors trigger doors; stationary actors do not continuously hold them open. Nearby living players keep the doorway clear, and inconsistent door state is retried at two-second intervals.
- Add separate FIFO checkout queues and waiting positions to each station. Invalid/removed customers leave the queue.
- Preserve an actor's occupied reservation when a new route fails; transfer it only when travel can begin. Unknown destinations return no route. Obstructed actors can replan around other occupants.
- Add shelf drinks with a five-item player basket, clerk checkout and timed restocking. No currency/persistent inventory is implemented.
- Add model-facing activity poses, idle gesture variation, blinking and approximate speech mouth movement.
- Enforce the population limit for car visitors, retry missing clerk spawning, prune disconnected-player baskets, and align the car model bottom to its ground route.
- Add admin-validated settings controls. Keep traffic disabled by default.
- Extend automated regressions for queues, reservations and door input state. Engine collision, swing clearance, UI and animation require in-game acceptance checks after updating and respawning the station.
