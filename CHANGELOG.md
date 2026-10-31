# Changes

## 0.4.0 alpha

- Reverse both doors to open inward. Move the inside/outside waiting points beyond their sweep, request opening before citizens approach, wait until the leaf clears, and serialize opposing passage. Passage claims release on crossing, actor removal or lease expiry.
- Stock two racks with 30 actual props. Players physically carry products, return unpaid items, check out and consume purchases. NPCs take stock and carry a visible hand prop; empty-handed visitors retry or leave. Basket references track actual items and prune invalid ones; cap loose products at 40 per station and expire temporary stock.
- Add six ceiling fixtures using verified stock `prison_lamp001c` lit/unlit skins and switchable station-local lighting. Light refreshes are distance-limited/throttled, capped at eight ceiling lights plus two vehicle light pools per viewer; `db_lighting 0` opts out locally.
- Support two reserved vehicle destinations, curved approach samples, reversing, varied cruise speed, engine audio, warning signals, clearer spawn checks and model-axis-aware rectangular clearance sweeps. Passengers spawn beside their vehicle and return to it before departure.
- Fix the circular vehicle trace that could reject a road lane despite its rectangular body fitting. Serialize arrivals/departures on the shared drive to prevent head-on deadlocks; reserve population capacity for incoming passengers. Stop engine sounds and release only the removed car's own parking/lane reservations. Alternate walking/car visits so traffic also works with a one-customer limit. Keep traffic off by default pending in-game path/asset checks.
- Extend regressions for reverse swing, rotated door crossings, early opening/single-file passage, physical-item basket transactions, curved path endpoints, rotated car bounds, parking/audio cleanup and lighting budgets.

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
