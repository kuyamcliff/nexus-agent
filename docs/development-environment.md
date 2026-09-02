# Development Environment Report

Generated: 2026-09-02, Claude Code remote session container.

## Installed (this session)

| Tool | Version | Verified with |
|---|---|---|
| Unity Editor | 6000.0.82f1 | `unity-editor -version` → `6000.0.82f1`; full batchmode startup traced in logs |
| Android SDK/NDK/build-tools/platform-tools | build-tools 34.0.0, NDK 25.2.9519653, platform android-34 | `adb --version` → 1.0.41 (37.0.1) |
| Blender | 4.0.2 | `blender --version` → `Blender 4.0.2` |
| Godot | 4.5-stable + Android export templates | `Godot --version` → `4.5.stable.official.876b29033` |
| OpenJDK 17 | 17.0.20 | present at `/usr/lib/jvm/java-17-openjdk-amd64` |
| GIMP | 2.10.36 | `gimp --version` |
| Audacity | 3.4.2 | package installed (GUI unverifiable, no display) |
| Krita | 5.2.2 | package installed (GUI unverifiable, no display) |
| QGIS | 3.34.4 | `qgis --version` → `QGIS 3.34.4-Prizren` |
| Git LFS | 3.4.1 | `git lfs version` |
| GitHub CLI | 2.45.0 | `gh --version` |
| FFmpeg | 6.1.1 | `ffmpeg -version` |
| ImageMagick | 6.9.12 (v6) | `convert --version` / `identify` present |
| .NET SDK | 8.0.130 | `dotnet --info` |
| Vulkan tools / mesa-utils | — | `vulkaninfo` runs, correctly reports no GPU driver |

## Already installed (pre-existing in the container)

Git 2.43.0, Python 3.11.15, Node.js v22.22.2, npm 10.9.7, pnpm 10.33.0, Docker CLI 29.3.1 + Compose v5.1.1, CMake 3.28.3, OpenJDK 21.0.10.

## Manual installation required (proprietary/account-gated — do this on your own machine)

Unity license activation, Unity Hub (optional — not needed here), Substance Painter/Designer, Photoshop, Premiere Pro, After Effects, Affinity Photo, Houdini, SpeedTree, ZBrush, RealityCapture/RealityScan, REAPER, FMOD Studio, Wwise, Android Studio, VS Code, JetBrains Rider. See `docs/tool-installation-status.md` for the full breakdown and reasoning per item.

## Failed / not applicable

| Item | Reason |
|---|---|
| Unity Hub GUI functionality | Not a network outage — its Electron/Chromium network stack fails TLS handshakes through this session's proxy (confirmed independent of `NODE_EXTRA_CA_CERTS`), and it also has no `$DISPLAY` to run interactively. Worked around by installing the Editor directly from Unity's CDN instead. |
| Unity Android Build Support | Not a failed download — confirmed via Unity's own official release manifest that this module was never shipped for the Linux Editor at all. Not fixable from this machine; Godot covers Android instead. |
| RenderDoc | Not present in Ubuntu 24.04's default apt sources; not pursued further since there's no GPU for it to use anyway. |
| Docker daemon | Docker socket absent (`/var/run/docker.sock` does not exist) — no daemon running/reachable in this container. Not something installable from inside a non-privileged session; would need the environment itself configured differently. |
| GPU vendor tools (NVIDIA/AMD/Intel) | No GPU present in this container at all — nothing to detect or install for. |

## Disk usage

- Session start: 7.1G used / 30G available (fixed session allowance)
- Now: 23G used / 15G available
- Net consumed this session: ~15-16G, dominated by Unity (7.9G), QGIS+Krita+dependency trees (~2-3G), Android SDK (2.2G), .NET SDK (~0.6G), Blender (~1G)

## Environment / paths configured

| Variable / path | Value |
|---|---|
| `unity-editor` | symlink → `/opt/unity-editor/Editor/Editor/Unity` |
| `godot` | symlink → `/opt/godot/Godot` |
| Android SDK root | `/opt/android-sdk` (not exported as `$ANDROID_SDK_ROOT` in the shell profile — set it per-command or add it yourself if you keep working in this container) |
| JDK 17 for Android tooling | `/usr/lib/jvm/java-17-openjdk-amd64` (system default `java` remains 21) |

## Verification summary

Every "Installed" row above was verified by actually invoking the tool's version/info
command and reading real output (not just checking that a package manager reported
success) — see the audit doc for full command transcripts where relevant. GUI-only tools
(Audacity, Krita full UI, Unity Hub, any IDE) cannot be verified beyond "the binary
exists and the package installed cleanly," because this container has no display —
that limitation is stated explicitly wherever it applies, not glossed over.

## GO / PARTIAL / STOP

**PARTIAL.** See the chat response for the full reasoning and a recommended real
workstation spec — this environment is fine for scripting, docs, Python tooling, and
asset-format conversion, but is not a substitute for real Unity/Blender/Android
development, which needs a GPU and persistent disk this container doesn't have.
