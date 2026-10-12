{
  description = "Skate 3 Rust Engine development shell for macOS and Linux";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      # nixpkgs-unstable no longer supports x86_64-darwin (Intel Macs).
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (
        pkgs:
        let
          inherit (pkgs) lib;
          inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
          # Linux libraries the game links (ALSA, udev) or dlopens at runtime
          # (winit, wgpu and SDL: Vulkan, Wayland/X11, xkbcommon).
          linuxRuntimeLibs = with pkgs; [
            alsa-lib
            udev
            vulkan-loader
            libxkbcommon
            wayland
            libx11
            libxcursor
            libxi
            libxrandr
          ];
          # Runtime-loaded libraries, then dyld's default fallback on macOS.
          runtimeLibraryPath =
            if isDarwin then
              "${lib.makeLibraryPath [ pkgs.vulkan-loader ]}:/usr/local/lib:/usr/lib"
            else
              lib.makeLibraryPath linuxRuntimeLibs;
          libraryPathVariable = if isDarwin then "DYLD_FALLBACK_LIBRARY_PATH" else "LD_LIBRARY_PATH";
          # Impure on macOS: no Nix C toolchain or SDK, so cc, xcrun, the SDK and
          # any installed Xcode tools (Instruments, Metal tools) come from the system.
          mkShell = if isDarwin then pkgs.mkShellNoCC else pkgs.mkShell;
          commands = {
            skate-build = ''
              cd "$SKATE_ROOT"
              exec cargo build --locked -p skate-game --bin skate3rust "$@"
            '';
            skate-assets = ''
              cd "$SKATE_ROOT"
              python - <<'PY'
              import json
              import os
              from pathlib import Path

              assets = Path(os.environ.get("SKATE3_ASSETS", "assets"))
              if "SKATE3_ASSETS" not in os.environ and not (assets / "private/game.json").is_file():
                  marker = Path("data/installation.json")
                  if not marker.is_file():
                      raise SystemExit("No installation; run skate-setup <iso|default.xex> first")
                  assets = Path("data") / json.loads(marker.read_text())["directory"] / "assets"
              if not (assets / "private/game.json").is_file():
                  raise SystemExit(f"Prepared assets not found at: {assets}")
              print(assets.resolve())
              PY
            '';
            skate-run = ''
              cd "$SKATE_ROOT"
              assets="$(skate-assets)"
              exec cargo run --locked -p skate-game --bin skate3rust -- --assets "$assets" "$@"
            '';
            # Setup extracts ISOs with the skate-xiso binary from target/.
            skate-setup = ''
              if [ "$#" -ne 1 ]; then
                echo "usage: skate-setup <Skate 3 Xbox 360 ISO | default.xex>" >&2
                exit 64
              fi
              source="$(realpath "$1")"
              cd "$SKATE_ROOT"
              skate-build
              cargo build --locked -p skate-xiso
              exec python tools/setup.py --base data --game-exe target/debug/skate3rust \
                --source "$source" --refresh
            '';
          };
          commandPackages = lib.mapAttrsToList (
            name: script:
            pkgs.writeShellScriptBin name ''
              set -euo pipefail
              : "''${SKATE_ROOT:?Run this command inside nix develop}"
              ${script}
            ''
          ) commands;
        in
        {
          default = mkShell {
            packages = [
              pkgs.rustc
              pkgs.cargo
              pkgs.clippy
              pkgs.rustfmt
              pkgs.rust-analyzer
              pkgs.pkg-config
              # sdl3-sys builds SDL from source.
              pkgs.cmake
              pkgs.git
              # Asset setup (tools/setup.py); see tools/requirements-setup.txt.
              (pkgs.python313.withPackages (ps: [
                ps.numpy
                ps.pillow
                ps.tkinter
              ]))
              # ISO extraction and audio decoding; on Windows setup downloads
              # pinned Win64 builds of these instead.
              pkgs.extract-xiso
              pkgs.vgmstream
            ]
            ++ commandPackages;

            buildInputs = lib.optionals isLinux (
              linuxRuntimeLibs
              # SDL's CMake requires these X11 extension headers once it finds X11.
              ++ (with pkgs; [
                libxext
                libxfixes
                libxscrnsaver
                libxtst
              ])
            );

            env = {
              RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
            }
            // lib.optionalAttrs isDarwin {
              # The renderer is Vulkan-only; on macOS wgpu reaches Metal through
              # the Vulkan loader and the MoltenVK driver, both dlopened at runtime.
              VK_DRIVER_FILES = "${pkgs.moltenvk}/share/vulkan/icd.d/MoltenVK_icd.json";
              # MoltenVK's default fast-math lets Metal compile the depth-prepass and
              # main-pass vertex shaders to slightly different positions; skinned,
              # morphed customiser skaters then fail the main-pass depth test.
              MVK_CONFIG_FAST_MATH_ENABLED = "0";
            };

            # dev-dynamic builds link libstd and Bevy's dylib without an rpath.
            # `cargo run` exports their directories; the shell does too, so
            # tools/setup.py can launch target/debug/skate3rust directly. Any
            # existing search path is kept after these.
            shellHook = ''
              export SKATE_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
              export ${libraryPathVariable}="$(rustc --print target-libdir):$SKATE_ROOT/target/debug/deps:${runtimeLibraryPath}''${${libraryPathVariable}:+:''$${libraryPathVariable}}"
              if [[ $- == *i* ]]; then
                echo "Skate dev shell: skate-build | skate-setup <iso|default.xex> | skate-run [args] | skate-assets"
              fi
            '';
          };
        }
      );

      # `nix run` from the checkout: `nix develop` under bubblewrap with only
      # the checkout writable, the Nix store read-only, the Nix daemon socket,
      # GPU, display, audio and input. Arguments are passed to `nix develop`.
      packages = nixpkgs.lib.genAttrs (builtins.filter (nixpkgs.lib.hasSuffix "-linux") systems) (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          path = pkgs.lib.makeBinPath [
            pkgs.nix
            pkgs.git
            pkgs.bashInteractive
            pkgs.coreutils
          ];
        in
        {
          default = pkgs.writeShellApplication {
            name = "skate3-sandbox";
            runtimeInputs = [
              pkgs.bubblewrap
              pkgs.git
            ];
            text = ''
              repo="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
              args=(
                --unshare-all
                --share-net
                --die-with-parent
                --clearenv
                --proc /proc
                --dev /dev
                --tmpfs /tmp
                --ro-bind /nix/store /nix/store
                --ro-bind /nix/var/nix/daemon-socket /nix/var/nix/daemon-socket
                --bind "$repo" "$repo"
                --chdir "$repo"
                --symlink ${pkgs.bashInteractive}/bin/sh /bin/sh
                --symlink ${pkgs.coreutils}/bin/env /usr/bin/env
                --ro-bind-try /etc/resolv.conf /etc/resolv.conf
                --ro-bind-try /etc/hosts /etc/hosts
                --ro-bind-data 3 /etc/passwd
                --ro-bind-data 4 /etc/group
                # sysfs and the udev database for GPU probing and gamepad enumeration;
                # hotplug events arrive over netlink, which the shared network allows.
                --ro-bind-try /sys /sys
                --ro-bind-try /run/udev /run/udev
                --dev-bind-try /dev/dri /dev/dri
                --dev-bind-try /dev/input /dev/input
                --dev-bind-try /dev/snd /dev/snd
                # NixOS: Vulkan ICDs, and the ALSA config routing alsa-lib to PipeWire.
                # The files in /etc/alsa/conf.d are symlinks into /etc/static.
                --ro-bind-try /run/opengl-driver /run/opengl-driver
                --ro-bind-try /run/opengl-driver-32 /run/opengl-driver-32
                --ro-bind-try /etc/static /etc/static
                --ro-bind-try /etc/alsa /etc/alsa
                --ro-bind-try /etc/asound.conf /etc/asound.conf
                --setenv HOME "$repo/.local/home"
                --setenv USER "$(id -un)"
                --setenv PATH ${path}
                --setenv NIX_REMOTE daemon
                --setenv NIX_CONFIG "experimental-features = nix-command flakes"
                --setenv NIX_SSL_CERT_FILE ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
                --setenv SSL_CERT_FILE ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
                --setenv TERMINFO_DIRS ${pkgs.ncurses}/share/terminfo
                --setenv TERM "''${TERM:-xterm-256color}"
                --setenv LANG C.UTF-8
              )
              shopt -s nullglob
              # SDL reads controllers through hidraw for its HIDAPI drivers.
              for dev in /dev/nvidia* /dev/hidraw*; do
                args+=(--dev-bind "$dev" "$dev")
              done

              if [[ -n ''${XDG_RUNTIME_DIR:-} ]]; then
                args+=(--tmpfs "$XDG_RUNTIME_DIR" --setenv XDG_RUNTIME_DIR "$XDG_RUNTIME_DIR")
                if [[ -n ''${WAYLAND_DISPLAY:-} ]]; then
                  socket="$WAYLAND_DISPLAY"
                  [[ $socket == /* ]] || socket="$XDG_RUNTIME_DIR/$socket"
                  args+=(--ro-bind-try "$socket" "$socket" --setenv WAYLAND_DISPLAY "$WAYLAND_DISPLAY")
                fi
                args+=(
                  --ro-bind-try "$XDG_RUNTIME_DIR/pipewire-0" "$XDG_RUNTIME_DIR/pipewire-0"
                  --ro-bind-try "$XDG_RUNTIME_DIR/pulse/native" "$XDG_RUNTIME_DIR/pulse/native"
                )
              fi

              if [[ ''${DISPLAY:-} =~ ^[^:]*:([0-9]+) ]]; then
                args+=(
                  --ro-bind-try "/tmp/.X11-unix/X''${BASH_REMATCH[1]}" "/tmp/.X11-unix/X''${BASH_REMATCH[1]}"
                  --setenv DISPLAY "$DISPLAY"
                )
                xauth="''${XAUTHORITY:-$HOME/.Xauthority}"
                if [[ -f $xauth ]]; then
                  args+=(--ro-bind "$xauth" /tmp/.Xauthority --setenv XAUTHORITY /tmp/.Xauthority)
                fi
              fi

              mkdir -p "$repo/.local/home"
              exec bwrap "''${args[@]}" -- nix develop "$@" \
                3< <(printf '%s:x:%s:%s::%s:/bin/sh\n' "$(id -un)" "$(id -u)" "$(id -g)" "$repo/.local/home") \
                4< <(printf '%s:x:%s:\n' "$(id -gn)" "$(id -g)")
            '';
          };
        }
      );

      formatter = forAllSystems (pkgs: pkgs.nixfmt);
    };
}
