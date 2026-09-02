# Tool Installation Status &amp; Categorization

Generated: 2026-09-02. Companion to `docs/development-machine-audit.md`. Every tool from
the original 28-phase request, categorized. No further installs were made after being
told to stop — this is a status/categorization pass only.

## Already installed (this session or pre-existing)

| Tool | Version | Source |
|---|---|---|
| Git | 2.43.0 | pre-existing |
| Git LFS | 3.4.1 | apt |
| GitHub CLI (`gh`) | 2.45.0 | apt |
| Python 3 | 3.11.15 | pre-existing |
| Node.js / npm / pnpm | v22.22.2 / 10.9.7 / 10.33.0 | pre-existing |
| .NET SDK | 8.0.130 | apt |
| Docker CLI + Compose plugin | 29.3.1 / v5.1.1 | pre-existing (daemon not running) |
| CMake | 3.28.3 | pre-existing |
| OpenJDK | 17.0.20 and 21.0.10 | apt (17) + pre-existing (21) |
| Unity Editor | 6000.0.82f1 | direct CDN download |
| Android SDK/NDK/build-tools/platform-tools | build-tools 34, NDK 25.2.9519653 | Google `sdkmanager` |
| Blender | 4.0.2 | apt |
| GIMP | 2.10.36 | apt |
| Audacity | 3.4.2 | apt |
| Krita | 5.2.2 | apt |
| QGIS | 3.34.4 | apt |
| FFmpeg | 6.1.1 | apt |
| ImageMagick | 6.9.12 | apt |
| Vulkan tools / mesa-utils | — | apt (confirm no GPU present) |
| Godot | 4.5-stable + Android export templates | official GitHub release |

## Safe/lightweight — could be added here later if you want, but not done yet

These are small, free, and would work in this container; I stopped before doing them
per your instruction, not because they're risky:

- `git lfs install` (repo-level hook setup — one command)
- A clean Python venv with the remaining requested packages: pandas, jupyter notebook, ipykernel, scikit-learn, rich, psutil (numpy/scipy/matplotlib/pillow/pyyaml/requests/sympy already present as system deps, but not in an isolated project venv)
- `gh auth login` (needs your GitHub credentials — can't be done for you)
- Docs/project folder scaffolding (`docs/architecture/`, `tools/vehicle-dynamics/`, etc.)
- A `check-environment` diagnostic script

## Too large / not sensible for this ephemeral, disk-limited, no-GPU container

| Tool | Why |
|---|---|
| Android Studio | ~1GB GUI IDE; no display to run it; fully redundant with the SDK/NDK already installed here |
| VS Code, JetBrains Rider | GUI IDEs; no display to run them at all |
| RenderDoc | Not in Ubuntu's default apt sources; would need a manual download, and there's no GPU for it to capture from anyway |
| NVIDIA Nsight / AMD RGP / Intel GPA | No GPU vendor present — nothing for them to profile |
| Meshroom (AliceVision) | GPU-dependent photogrammetry reconstruction; multi-GB download that would be non-functional here |
| DaVinci Resolve | Multi-GB GUI app, GPU-accelerated, license/account gated for the full version |
| Docker-based Postgres/Redis dev services | Docker daemon isn't running/reachable in this container (see audit) — nothing to run them on |
| A real Unity project + full package set (Input System, Cinemachine, Addressables, URP/HDRP, etc.) | These are per-project Package Manager dependencies; instantiating them means creating an actual Unity project, which you explicitly said not to do yet |

## Commercial/proprietary — install manually on your real machine, not here

| Software | Why it can't be done here |
|---|---|
| Substance 3D Painter / Designer | Paid, requires Adobe/Adobe-Substance account + license |
| Photoshop, Premiere Pro, After Effects | Paid, account-gated, Windows/Mac-first |
| Affinity Photo | Paid |
| Houdini | Paid (or free-indie with account), proprietary license flow |
| SpeedTree | Paid, licensed per-seat |
| ZBrush | Paid |
| RealityCapture / RealityScan | Paid/account-gated |
| REAPER | Paid after trial (technically installable, but licensing is yours to manage) |
| FMOD Studio | Free to use but requires account + manual download; preferred here per your original brief over Wwise |
| Audiokinetic Wwise | Same — account/license gated; not installed since FMOD is the stated preference |
| Unity license activation (Personal/Pro) | Requires your Unity account credentials — I won't ask for or handle these in chat |

## Optional / not needed yet

- Unity Hub — the Editor works without it here, and Hub's GUI can't run in this container anyway
- A backend framework choice (Node/TS vs Go vs pure C#) — deferred; Node/TS is already present and is the natural default if/when you build backend services, but nothing was scaffolded since you said not to build the game yet
- CI/CD (GitHub Actions) — no real Unity project exists yet to build, so a workflow would either be fake or empty; deferred until there's something real to run
- Asset license register, vehicle-dynamics tooling, docs/ subfolder structure — genuinely useful scaffolding, but held per "finish the audit only"
