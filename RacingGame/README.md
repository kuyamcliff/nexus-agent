# Nexus Racing

A playable 3-lap race against three AI opponents on a procedurally-built circuit.
Built with **Godot 4.5** (free, no licence or account needed) using **only CC0 assets**
already in this repo — Kenney's Car Kit and Racing Kit, and Poly Haven textures/HDRI.
None of the 50 real/licensed hero cars from `tools/asset-acquisition/final-50-cars.json`
are used, because none have actually been purchased.

Unity isn't used here: it has no activated licence in this environment, and its Linux
Editor ships no Android build support at all (see `docs/development-machine-audit.md`).

## Running it

```
godot --path RacingGame
```

Or open `RacingGame/` in the Godot editor (4.5+) and press Play.

**Controls** — Arrows or WASD: Up = throttle, Down = brake/reverse, Left/Right = steer.
Space = handbrake. Hold **R** to respawn on the racing line if you beach yourself.

You start **last on the grid**. Three laps. Beat NOVA.

## What's in it

- **A real circuit** (~865m): long main straight, fast right sweeper, two kinks, a
  bottom straight, a left hairpin, and a 90° final corner. Defined as a Catmull-Rom
  spline through hand-placed control points in `TrackGeometry.gd`.
- **Everything derives from that one spline** — the asphalt ribbon, painted edge lines,
  red/white kerbs on corners only, solid barrier walls with real collision, the AI
  racing line, lap progress, and the off-track test. One source of truth for "where the
  track is".
- **Three AI opponents** with distinct cars, cornering confidence, and preferred lines.
  They look ahead, judge the curvature of what's coming, and brake for it — so they
  actually race rather than understeering into the scenery.
- **A real race**: lights-out countdown, lap counting, live standings, best-lap timing,
  chequered flag, and an end-of-race results panel.
- **Off-track penalty**: leave the asphalt and you lose grip and power, and the HUD
  tells you. The grass is physically lower than the road, so you feel the drop.
- **Chase camera** whose FOV widens with speed, and a HUD with position, lap, live lap
  time, best lap, and speed.

## Architecture

| File | Role |
|---|---|
| `TrackGeometry.gd` | The circuit spline: sampling, curvature, progress, lateral offset, lookahead queries |
| `TrackBuilder.gd` | Turns the spline into meshes, collision, and Kenney-prop scenery |
| `RaceVehicle.gd` | Shared car: physics, wheels, off-track handling, lap counting |
| `PlayerCar.gd` / `AICar.gd` | The two drivers, both writing to the same control inputs |
| `RaceManager.gd` | Countdown → racing → finished, standings, timing |
| `Main.gd` | Assembles everything and registers the input map |

Wheel placement is **read from each model at load time** — every Kenney Car Kit vehicle
names its wheels `wheel-front-left` etc, so swapping in a different car needs no
hand-measured numbers. The visual wheel meshes are re-parented onto the physics wheels
so they steer and roll with the simulation.

## Tests

Both are real regression tests, run headlessly with no GPU:

```
godot --headless --path RacingGame scenes/HeadlessTest.tscn   # driving + AI + lap counting
godot --headless --path RacingGame scenes/FinishTest.tscn     # a full 3-lap race to the flag
```

They exit non-zero on failure. `HeadlessTest` drives the player **through the real
keyboard input path** (`AutoDriver.gd` presses the same actions a human would) rather
than poking the vehicle's internals, so the player control path is genuinely covered.

Visual checks render through Mesa's software rasteriser, so they work with no GPU:

```
xvfb-run -a godot --path RacingGame --rendering-driver opengl3 scenes/ScreenshotTest.tscn -- moving
```

## Bugs these tests actually caught

Every one of these was found by running the thing, not by reading the code:

1. **Chase camera was in front of the car.** These models face `+Z`, so `basis.z` is
   *forwards*; the camera was placed at `+forward` and looked back — the car had been
   driving away from the camera the whole time.
2. **The road had no collision.** It was built as a visual mesh only, so every car fell
   through the world to y ≈ -4900. The test now asserts a minimum height.
3. **Every road normal pointed down.** The quad winding was inverted for Godot's
   convention, so the entire track was backface-culled and you saw the grass through it.
   Confirmed by dumping the mesh normals: 0 of 2520 pointed up.
4. **Standings were backwards at the start.** Lap progress wraps 0.99 → 0.02 at the
   line, so an AI that had just crossed sorted *behind* a player who hadn't. Fixed with
   a continuous distance-travelled counter that can't wrap.
5. **Grass z-fought the road** and won, because it sat 2cm below it across a 900m plane.
6. **Suspension launched the car airborne** under sustained throttle (too little travel,
   under-damped).
7. **Engine force was ~7x too weak** — the car crept to 3.5 km/h in five seconds.

## Known limitations

- **No audio.** There's no sound device in this container to test against, and the
  Kenney kits ship no engine audio, so adding sound blind would be guessing.
- Rendering was only ever verified through llvmpipe (software). Shadows are on and look
  correct here, but check them on real hardware.
- Cars collide with barriers and each other, but there's no damage model, tyre wear,
  fuel, or pit stops.
- The AI follows a fixed line offset rather than a true optimised racing line, and won't
  actively defend a position.
- One circuit, one car class.

## Swapping in a real car

Once you've bought and imported one of the cars from `final-50-cars.json`:
1. Drop the `.glb` in `RacingGame/assets/models/`.
2. Point `model_path` at it (`Main.gd` for the player, `FIELD` for the AI).
3. If it doesn't use Kenney's `wheel-front-left` naming, rename its wheel nodes to match
   — `RaceVehicle.gd` finds them by name and will warn if they're missing.
4. Run `HeadlessTest.tscn` before trusting it.
