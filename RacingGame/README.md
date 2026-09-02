# Nexus Racing (playable prototype)

A real, running driving prototype built with **Godot 4.5** — not Unity. Unity was ruled
out for this because (a) it has no activated license in this environment and (b) its
Linux Editor has no Android Build Support at all (see `docs/development-machine-audit.md`
at the repo root). Godot needs neither a license nor an account and runs natively here.

This uses **only CC0 assets already in the repo** (Kenney Car Kit + Racing Kit, Poly
Haven textures/HDRI) — none of the 50 real/licensed hero cars from
`tools/asset-acquisition/final-50-cars.json` are used, since none of those have actually
been purchased. Swapping in a real car once you've bought and imported one is
straightforward (see "Using a real hero car" below).

## Running it

On a real machine with Unity... no, wait - **Godot**, with a display:

```
godot --path RacingGame
```

Or open `RacingGame/` as a project in the Godot editor (4.5+) and press Play.

**Controls:** Arrow keys / WASD-equivalent default Godot UI actions - Up = throttle,
Down = brake/reverse, Left/Right = steer.

## What's actually in it

- A drivable car (`Car.gd`, `VehicleBody3D` + 4 `VehicleWheel3D`) using Kenney's
  `race.glb` kart model. Wheel attachment points were measured directly from the source
  mesh (Blender bounding-box inspection), not guessed.
- A large asphalt ground plane (the real driving surface) using a Poly Haven asphalt
  texture, plus a decorative track-boundary loop built from Kenney Racing Kit tiles
  (visual only - doesn't affect physics, so tile-seam imperfections don't matter).
- A sky/lighting setup using a Poly Haven HDRI as the environment panorama.
- A chase camera (`CameraRig.gd`) and a speed HUD (`HUD.gd`).
- Everything is built procedurally in `Main.gd` at runtime - there's no hand-authored
  `.tscn` level, so the whole world is defined in readable GDScript.

## How this was verified (not just "should work")

Three real bugs were found and fixed by actually running the project, not by code
review alone:

1. **Engine force was 7x too weak** - caught by a headless physics test
   (`scripts/HeadlessTest.gd`) that drives the car for simulated seconds and checks it
   actually covers distance and reaches a real speed.
2. **Suspension was under-damped and launched the car airborne** under sustained
   throttle - caught by comparing a numeric max-height check against an actual rendered
   screenshot that showed the car flying.
3. **The decorative track boundary was too close to the drivable area** - the chase
   camera clipped through it once the car had driven far enough, which looked like the
   car had flown into the sky. Root-caused by comparing car position (grounded, per the
   physics test) against camera position (also fine) against the rendered image (broken)
   - the actual bug was geometry placement, not physics or camera code.

Verification tooling (kept in the repo as real regression tests, not one-off scratch
files):
- `scripts/HeadlessTest.gd` / `scenes/HeadlessTest.tscn` - runs headless
  (`godot --headless --path RacingGame scenes/HeadlessTest.tscn`), simulates throttle
  then steering, and asserts the car moved, stayed upright, stayed numerically finite,
  and never left the ground unexpectedly. Prints `RESULT=PASS` or `RESULT=FAIL`.
- `scripts/ScreenshotTest.gd` / `scripts/ScreenshotTestMoving.gd` - render the real
  scene via software OpenGL (works with no GPU, via Mesa llvmpipe:
  `xvfb-run -a godot --path RacingGame --rendering-driver opengl3 scenes/ScreenshotTest.tscn`)
  and save an actual PNG, so visual regressions can be caught the same way the three bugs
  above were.

## Known limitations (honest, not glossed over)

- Visual wheel spin follows the physics simulation (wheel meshes are reparented onto the
  `VehicleWheel3D` nodes), but there's no wheel rotation animation independent of that -
  it's correct, just minimal.
- No collision detection between the car and the decorative track tiles (they're
  render-only) - you can currently drive through the track boundary visually.
- Rendered/screenshotted only through Mesa's software rasterizer (llvmpipe) in this
  no-GPU container - it will very likely look better (proper shadows re-enabled,
  antialiasing, etc.) on a real GPU. Shadows are currently force-disabled
  (`shadow_enabled = false` in `Main.gd`) because they were untested on real hardware -
  worth re-enabling and checking once you're on a real machine.
- This is a driving sandbox, not a race - no lap timing, opponents, or win condition.

## Using a real hero car

Once you've purchased and imported one of the 50 cars from `final-50-cars.json`:
1. Export/convert it to `.glb` or `.fbx` and drop it in `RacingGame/assets/models/`.
2. In `Car.gd`, change `CAR_SCENE_PATH` to point at the new file.
3. Re-measure wheel attachment points for the new mesh (see the Blender bounding-box
   technique used for `race.glb` - `blender --background --python <script>` querying
   each wheel object's `matrix_world.translation`) and update the `wheel_defs` dictionary
   in `Car.gd` accordingly - every car's wheelbase/track width is different.
4. Re-run `scripts/HeadlessTest.gd` to confirm the new car is stable before trusting it.
