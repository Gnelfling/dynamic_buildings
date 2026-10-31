# Changes

## 0.2.0 alpha

- Set both doors to reverse swing using Source's `opendir=2`; activate them explicitly. Automatic input commands are no longer issued every quarter-second. Moving actors trigger doors; stationary actors do not continuously hold them open. Nearby living players keep the doorway clear, and inconsistent door state is retried at two-second intervals.
- Add separate FIFO checkout queues and waiting positions to each station. Invalid/removed customers leave the queue.
- Preserve an actor's occupied reservation when a new route fails; transfer it only when travel can begin. Unknown destinations return no route. Obstructed actors can replan around other occupants.
- Add shelf drinks with a five-item player basket, clerk checkout and timed restocking. No currency/persistent inventory is implemented.
- Add model-facing activity poses, idle gesture variation, blinking and approximate speech mouth movement.
- Enforce the population limit for car visitors, retry missing clerk spawning, prune disconnected-player baskets, and align the car model bottom to its ground route.
- Add admin-validated settings controls. Keep traffic disabled by default.
- Extend automated regressions for queues, reservations and door input state. Engine collision, swing clearance, UI and animation require in-game acceptance checks after updating and respawning the station.
