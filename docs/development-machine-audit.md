# Development Machine Audit

Generated: 2026-09-02 (Claude Code remote session)

## What kind of machine this is

This is a **Claude Code remote execution session container** — ephemeral, disk-limited,
headless, and not a persistent local workstation. Treat every finding below in that
light: it describes *this container right now*, not a machine you'll come back to.

## System

| Item | Value |
|---|---|
| OS | Ubuntu 24.04.4 LTS (noble) |
| Kernel | Linux 6.18.44-fc-v22, x86_64 |
| CPU | Intel Xeon @ 2.80GHz, 4 vCPU, 1 thread/core, KVM guest (virtualized, not dedicated hardware) |
| RAM | 15Gi total, ~9.7Gi free at audit time |
| Architecture | x86_64 |
| GPU | **None.** No `/dev/dri`, `lspci` isn't even installed (no PCI display device to find), no `nvidia-smi`. `vulkaninfo` confirms: `Found no drivers! Cannot create Vulkan instance.` This is software-rendering-only. |
| Display | **None.** `$DISPLAY` is unset, no X server, no `xrandr`. GUI apps (Krita, Unity Hub, any IDE) cannot run interactively — confirmed by Krita aborting with "could not connect to display." |
| Disk | 252G filesystem total, but only a **fixed session allowance** is actually writable — see Disk Usage below |
| Network | Outbound HTTPS via a policy-enforcing proxy. Confirmed reachable: unity.com (200), github.com (DNS resolves), download.unity3d.com, dl.google.com, github release assets. `api.github.com` is scope-gated to this session's attached repo. |
| Persistence | **None beyond this container's lifetime**, except what's committed to this git repository (`kuyamcliff/nexus-agent`) |

## Disk usage

| Point in session | Used | Available |
|---|---:|---:|
| Session start | 7.1G | 30G |
| Now | 23G | 15G |

Roughly **15-16G of the fixed allowance has been consumed** this session, split approximately:

| Item | Size |
|---|---:|
| Unity Editor 6000.0.82f1 | 7.9G |
| Android SDK (platform-tools, build-tools, platform 34, NDK 25.2.9519653, cmake) | 2.2G |
| Godot 4.5-stable + export templates | 130M |
| Blender 4.0.2 + deps (apt) | ~1G |
| GIMP + Audacity (apt) | ~0.5G |
| OpenJDK 17 (apt, alongside pre-existing 21) | ~0.3G |
| git-lfs, ffmpeg, imagemagick, vulkan-tools, mesa-utils, gh (apt) | ~0.3G |
| QGIS + Krita + their dependency trees (Qt, GDAL, GRASS providers, etc.) (apt) | ~2-3G |
| .NET SDK 8.0 + ASP.NET Core runtime (apt) | ~0.6G |

**~15G remains.** That is not enough headroom for a real Unity/Android/Docker-services
workflow (a single Android Gradle build cache, IL2CPP intermediates, or a Docker Postgres
image can each eat multiple GB), so no further large installs were made after your
stop instruction.

## Tool inventory

| Tool | Status | Version | Notes |
|---|---|---|---|
| Git | ✅ present | 2.43.0 | pre-existing |
| Git LFS | ✅ installed | 3.4.1 | binary present; `git lfs install` (repo hook setup) not yet run — one-line, your call |
| GitHub CLI (`gh`) | ✅ installed | 2.45.0 | not authenticated |
| Python 3 | ✅ present | 3.11.15 | pip 24.0 |
| Python packages | ⚠️ partial | numpy 1.26.4, scipy 1.11.4, matplotlib 3.6.3, pillow 10.2.0, PyYAML 6.0.1, requests 2.33.1, sympy 1.12 present (pulled in as **system** deps of QGIS/Blender, not a clean project venv) | pandas, jupyter notebook/ipykernel, scikit-learn, rich, psutil **not installed** |
| Node.js | ✅ present | v22.22.2 | pre-existing |
| npm | ✅ present | 10.9.7 | pre-existing |
| pnpm | ✅ present | 10.33.0 | pre-existing |
| .NET SDK | ✅ installed | 8.0.130 | no workloads installed |
| Docker (client) | ✅ present | 29.3.1, compose v5.1.1 | pre-existing binary |
| Docker (daemon) | ❌ unavailable | — | `docker info` fails: `dial unix /var/run/docker.sock: connect: no such file or directory`. No daemon running/reachable in this container. Containers cannot actually be run here. |
| CMake | ✅ present | 3.28.3 | pre-existing |
| Java | ✅ installed | OpenJDK 17.0.20 and 21.0.10 both present | system default `java` is 21; Android tooling should point at 17 explicitly |
| Unity Editor | ✅ installed, ⚠️ unlicensed | 6000.0.82f1 (Linux, Unity 6 LTS) | Installed via direct CDN download (Hub's Electron GUI can't complete TLS handshakes through this session's proxy and also can't run with no display). Batch-mode launch runs the full startup sequence correctly and stops cleanly at "No valid Unity Editor license found" — needs your Unity account to activate, which I don't have and won't request in chat. |
| Unity Hub | ❌ not usable | 3.21.0 installed but non-functional | Crashes immediately with no `$DISPLAY`; its background release-service calls fail TLS through the proxy even under `xvfb-run`. Not needed — the Editor itself works fine without it. |
| Unity Android Build Support | ❌ does not exist for Linux | — | Confirmed from Unity's own official per-version manifest (`unity-linux-x86_64.json`): the Linux Editor's `"android"` module entry points at a **macOS** installer package. Android was never shipped as a Linux Editor module — this is a real Unity platform limitation, not a config issue. |
| Android SDK/NDK/Platform-tools | ✅ installed | build-tools 34.0.0, platform android-34, NDK 25.2.9519653, cmake 3.22.1, platform-tools (adb 1.0.41 / v37.0.1) | via Google's official `sdkmanager`, independent of Unity |
| Android Studio | ❌ not installed | — | GUI-only IDE, cannot run with no display here; redundant with the SDK/NDK already installed |
| VS Code / JetBrains Rider | ❌ not installed | — | GUI-only IDEs, cannot run with no display here |
| Blender | ✅ installed | 4.0.2 | via apt; confirmed launches (`blender --version`) |
| FFmpeg | ✅ installed | 6.1.1 | |
| ImageMagick | ✅ installed | 6.9.12 (`convert`/`identify`; no `magick` alias — that's ImageMagick 7 naming, this is v6) | |
| GIMP | ✅ installed | 2.10.36 | |
| Audacity | ✅ installed | 3.4.2 | GUI, unverifiable interactively (no display) |
| Krita | ✅ installed | 5.2.2 | GUI, unverifiable interactively (no display) |
| QGIS | ✅ installed | 3.34.4 | CLI version check works; GUI unverifiable |
| Godot | ✅ installed | 4.5-stable + Android export templates | Installed as the actual Android-capable engine, since Unity cannot fill that role on Linux |
| Vulkan tools | ✅ installed, confirms no GPU | `vulkaninfo` reports "Found no drivers" (expected/correct given no GPU) | |
| RenderDoc | ❌ not installed | — | Not in Ubuntu 24.04's default apt sources; would need a direct download, and is non-functional with no GPU regardless |
| NVIDIA/AMD/Intel GPU profiling tools | ❌ not applicable | — | No GPU vendor detected at all |

## Key findings carried forward

1. Unity Hub's GUI cannot function in this container (no display + broken TLS trust in its Electron/Chromium network stack). The Editor itself was obtained by downloading the official tarball directly from Unity's CDN and verifying its MD5 against the CDN's own ETag.
2. Unity requires your account to activate a license — cannot be completed without your credentials, which I have not requested.
3. Unity cannot build Android from Linux, period — confirmed from Unity's own release manifest, not a workaround-able limitation. Godot 4.5 was installed as the real mobile/Android-capable engine.
4. Docker's daemon is not running/reachable here — the CLI is present but inert.
5. No GPU exists in this container at all — anything GPU-dependent (RenderDoc captures, Vulkan/OpenGL rendering, Unity/Blender viewport, vendor profilers) can only ever be install-checked here, never functionally exercised.
