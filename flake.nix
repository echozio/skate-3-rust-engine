{
  description = "Skate 3 Rust Engine: development shell for macOS and Linux, sandboxed game package for Linux";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;
      # nixpkgs-unstable no longer supports x86_64-darwin (Intel Macs).
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      linuxSystems = builtins.filter (lib.hasSuffix "-linux") systems;
      forAllSystems = f: lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
      # requireFile marks the user's own disc image unfree; allow only that.
      forLinuxSystems =
        f:
        lib.genAttrs linuxSystems (
          system:
          f (
            import nixpkgs {
              inherit system;
              config.allowUnfreePredicate = pkg: lib.getName pkg == "skate3.iso";
            }
          )
        );

      # Libraries the game links (ALSA, udev) or dlopens at runtime (winit, wgpu
      # and SDL: Vulkan, Wayland/X11, xkbcommon).
      linuxLinkedLibs = pkgs: [
        pkgs.alsa-lib
        pkgs.udev
      ];
      linuxLoadedLibs = pkgs: [
        pkgs.vulkan-loader
        pkgs.libxkbcommon
        pkgs.wayland
        pkgs.libx11
        pkgs.libxcursor
        pkgs.libxi
        pkgs.libxrandr
      ];
      # SDL's CMake requires these X11 headers once it finds X11.
      sdlBuildLibs = pkgs: [
        pkgs.libxcb
        pkgs.libxext
        pkgs.libxfixes
        pkgs.libxscrnsaver
        pkgs.libxtst
      ];
      setupPython =
        pkgs: extra:
        pkgs.python313.withPackages (
          ps:
          [
            ps.numpy
            ps.pillow
          ]
          ++ extra ps
        );

      # bubblewrap with the Nix store read-only, GPU, display, audio and input,
      # and nothing else: no Nix daemon socket, no host home, no network unless
      # the caller passes --share-net. The caller binds whatever must be
      # writable; options after --home go to bwrap after these defaults.
      mkSandbox =
        pkgs:
        pkgs.writeShellApplication {
          name = "skate-sandbox";
          runtimeInputs = [ pkgs.bubblewrap ];
          text = ''
            if [[ ''${1:-} != --home || $# -lt 2 ]]; then
              echo "usage: skate-sandbox --home DIR [bwrap options...] -- COMMAND [ARGS...]" >&2
              exit 64
            fi
            home="$2"
            shift 2
            mkdir -p "$home"
            args=(
              --unshare-all
              --die-with-parent
              --clearenv
              --proc /proc
              --dev /dev
              --tmpfs /tmp
              --ro-bind /nix/store /nix/store
              --symlink ${pkgs.bashInteractive}/bin/sh /bin/sh
              --symlink ${pkgs.coreutils}/bin/env /usr/bin/env
              --ro-bind-try /etc/resolv.conf /etc/resolv.conf
              --ro-bind-try /etc/hosts /etc/hosts
              --ro-bind-data 3 /etc/passwd
              --ro-bind-data 4 /etc/group
              # sysfs and the udev database for GPU probing and gamepad enumeration;
              # hotplug events arrive over netlink, which needs --share-net.
              --ro-bind-try /sys /sys
              --ro-bind-try /run/udev /run/udev
              --dev-bind-try /dev/dri /dev/dri
              --dev-bind-try /dev/input /dev/input
              --dev-bind-try /dev/snd /dev/snd
              # NixOS: Vulkan ICDs.
              --ro-bind-try /run/opengl-driver /run/opengl-driver
              --ro-bind-try /run/opengl-driver-32 /run/opengl-driver-32
              --bind "$home" "$home"
              --setenv HOME "$home"
              --setenv USER "$(id -un)"
              --setenv PATH ${
                lib.makeBinPath [
                  pkgs.bashInteractive
                  pkgs.coreutils
                ]
              }
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

            # Other distros have no /run/opengl-driver, so assemble one. Mesa's
            # Vulkan drivers come from nixpkgs. NVIDIA's must match the host's
            # kernel module, so those are the host's libraries, which name each
            # other and their X11 and libdrm dependencies without an rpath.
            library_path=""
            driver=/run/opengl-driver
            if [[ ! -e $driver ]]; then
              for icd in ${pkgs.mesa}/share/vulkan/icd.d/*.json; do
                args+=(--ro-bind "$icd" "$driver/share/vulkan/icd.d/''${icd##*/}")
              done
              for dir in /usr/lib/${pkgs.stdenv.hostPlatform.parsed.cpu.name}-linux-gnu /usr/lib64 /usr/lib; do
                [[ -e $dir/libGLX_nvidia.so.0 ]] || continue
                # Every library of that driver version, under its soname links
                # too: device creation fails without libcuda, for one. Then the
                # helpers NVIDIA versions separately.
                version="$(realpath "$dir/libGLX_nvidia.so.0")"
                version="''${version##*.so.}"
                declare -A bound=()
                for lib in "$dir"/*.so."$version" "$dir"/libnvidia*.so.*; do
                  target="$(realpath "$lib")"
                  for name in "''${lib%"$version"}"*; do
                    name="''${name##*/}"
                    [[ -z ''${bound[$name]:-} ]] || continue
                    bound[$name]=1
                    args+=(--ro-bind "$target" "$driver/lib/$name")
                  done
                done
                for icd in /etc/vulkan/icd.d/nvidia_icd*.json /usr/share/vulkan/icd.d/nvidia_icd*.json; do
                  args+=(--ro-bind "$icd" "$driver/share/vulkan/icd.d/''${icd##*/}")
                done
                library_path="$driver/lib:${
                  lib.makeLibraryPath [
                    pkgs.libx11
                    pkgs.libxext
                    pkgs.libxcb
                    pkgs.libdrm
                  ]
                }"
                break
              done
            fi

            # NixOS routes alsa-lib to PipeWire in /etc/alsa, whose conf.d links
            # into /etc/static. Elsewhere /etc/alsa links to host files, and
            # alsa-lib drops its whole configuration over one dangling link, so
            # PipeWire's own ALSA config stands in. It names the plugin without
            # a path, and nixpkgs' alsa-lib has no plugin directory of its own.
            if [[ -e /etc/NIXOS ]]; then
              args+=(
                --ro-bind-try /etc/static /etc/static
                --ro-bind-try /etc/alsa /etc/alsa
                --ro-bind-try /etc/asound.conf /etc/asound.conf
              )
            elif [[ -S ''${XDG_RUNTIME_DIR:-}/pipewire-0 ]]; then
              for conf in ${pkgs.pipewire}/share/alsa/alsa.conf.d/*.conf; do
                args+=(--ro-bind "$conf" "/etc/alsa/conf.d/''${conf##*/}")
              done
              args+=(--setenv ALSA_PLUGIN_DIR ${pkgs.pipewire}/lib/alsa-lib)
            fi

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

            # The driver libraries go ahead of the caller's search path rather
            # than being replaced by it.
            while [[ $# -gt 0 && $1 != -- ]]; do
              if [[ $1 == --setenv && ''${2:-} == LD_LIBRARY_PATH && $# -ge 3 ]]; then
                library_path="''${library_path:+$library_path:}$3"
                shift 3
                continue
              fi
              args+=("$1")
              shift
            done
            [[ -z $library_path ]] || args+=(--setenv LD_LIBRARY_PATH "$library_path")
            if [[ $# -lt 2 ]]; then
              echo "skate-sandbox: missing -- COMMAND" >&2
              exit 64
            fi
            shift
            exec bwrap "''${args[@]}" -- "$@" \
              3< <(printf '%s:x:%s:%s::%s:/bin/sh\n' "$(id -un)" "$(id -u)" "$(id -g)" "$home") \
              4< <(printf '%s:x:%s:\n' "$(id -gn)" "$(id -g)")
          '';
        };
    in
    {
      devShells = forAllSystems (
        pkgs:
        let
          inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
          # Runtime-loaded libraries, then dyld's default fallback on macOS.
          runtimeLibraryPath =
            if isDarwin then
              "${lib.makeLibraryPath [ pkgs.vulkan-loader ]}:/usr/local/lib:/usr/lib"
            else
              lib.makeLibraryPath (linuxLinkedLibs pkgs ++ linuxLoadedLibs pkgs);
          libraryPathVariable = if isDarwin then "DYLD_FALLBACK_LIBRARY_PATH" else "LD_LIBRARY_PATH";
          # Impure on macOS: no Nix C toolchain or SDK, so cc, xcrun, the SDK and
          # any installed Xcode tools (Instruments, Metal tools) come from the system.
          mkShell = if isDarwin then pkgs.mkShellNoCC else pkgs.mkShell;
          # `sandbox` runs in the calling shell before the command is sandboxed,
          # and may extend `args` with bwrap options or rewrite "$@".
          commands = {
            skate-build.script = ''
              cd "$SKATE_ROOT"
              exec cargo build --locked -p skate-game --bin skate3rust "$@"
            '';
            skate-assets.script = ''
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
            skate-run.script = ''
              cd "$SKATE_ROOT"
              assets="$(skate-assets)"
              exec cargo run --locked -p skate-game --bin skate3rust -- --assets "$assets" "$@"
            '';
            # Setup extracts ISOs with the skate-xiso binary from target/.
            skate-setup = {
              # Only the selected game source is visible, read-only: the ISO
              # itself, or the extracted folder around default.xex.
              sandbox = ''
                if [[ $# -eq 1 ]]; then
                  source="$(realpath -e "$1")"
                  case $source in
                    *.[xX][eE][xX]) args+=(--ro-bind "''${source%/*}" "''${source%/*}") ;;
                    *) args+=(--ro-bind "$source" "$source") ;;
                  esac
                  set -- "$source"
                fi
              '';
              script = ''
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
          }
          // lib.optionalAttrs isLinux {
            skate-shell.script = ''
              exec ${pkgs.bashInteractive}/bin/bash "$@"
            '';
          };
          mkCommand =
            name: script:
            pkgs.writeShellScriptBin name ''
              set -euo pipefail
              : "''${SKATE_ROOT:?Run this command inside nix develop}"
              ${script}
            '';
          innerCommands = pkgs.symlinkJoin {
            name = "skate-dev-commands";
            paths = lib.mapAttrsToList (name: command: mkCommand name command.script) commands;
          };
          sandbox = mkSandbox pkgs;
          # The checkout is the only writable path and its .local/home is $HOME.
          # Only the build environment crosses into the sandbox: compiler,
          # pkg-config, CMake and Cargo settings, never Nix daemon settings or
          # credentials. Nested skate-* calls resolve to the unwrapped commands.
          sandboxedCommand =
            name: command:
            mkCommand name ''
              args=(
                --home "$SKATE_ROOT/.local/home"
                --share-net
                --bind "$SKATE_ROOT" "$SKATE_ROOT"
              )
              case $PWD/ in
                "$SKATE_ROOT"/*) args+=(--chdir "$PWD") ;;
                *) args+=(--chdir "$SKATE_ROOT") ;;
              esac
              while IFS= read -r -d "" entry; do
                var="''${entry%%=*}"
                case $var in
                  *TOKEN* | *SECRET* | *PASSWORD* | NIX_CONFIG | NIX_REMOTE | NIX_PATH | NIX_USER_CONF_FILES | NIX_SSHOPTS) ;;
                  PATH | NIX_* | PKG_CONFIG* | CMAKE_* | CARGO_* | RUST* | *_FOR_BUILD | *_FOR_TARGET | \
                    LD_LIBRARY_PATH | SKATE_* | SKATE3_* | SOURCE_DATE_EPOCH | COLORTERM | \
                    CC | CXX | AR | AS | LD | NM | OBJCOPY | OBJDUMP | RANLIB | READELF | SIZE | STRINGS | STRIP)
                    args+=(--setenv "$var" "''${!var}")
                    ;;
                esac
              done < <(env -0)
              ${command.sandbox or ""}
              exec ${lib.getExe sandbox} "''${args[@]}" --setenv PATH "${innerCommands}/bin:$PATH" \
                -- ${name} "$@"
            '';
          commandPackages =
            if isLinux then lib.mapAttrsToList sandboxedCommand commands else [ innerCommands ];
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
              (setupPython pkgs (ps: [ ps.tkinter ]))
              # ISO extraction and audio decoding; on Windows setup downloads
              # pinned Win64 builds of these instead.
              pkgs.extract-xiso
              pkgs.vgmstream
            ]
            ++ commandPackages;

            buildInputs = lib.optionals isLinux (
              linuxLinkedLibs pkgs ++ linuxLoadedLibs pkgs ++ sdlBuildLibs pkgs
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
                echo "Skate dev shell: skate-build | skate-setup <iso|default.xex> | skate-run [args] | skate-assets${lib.optionalString isLinux " | skate-shell"}"
              fi
            '';
          };
        }
      );

      packages = forLinuxSystems (
        pkgs:
        let
          # Release build without dev-dynamic (Bevy as a dylib) or Steam (the
          # relay helper and its SDK are not packaged).
          engine = pkgs.rustPlatform.buildRustPackage {
            pname = "skate3-engine";
            version = "0.1.0";
            src = lib.fileset.toSource {
              root = ./.;
              fileset = lib.fileset.unions [
                ./Cargo.toml
                ./Cargo.lock
                ./crates
                ./vendor
                ./maps/format-demo.skate
              ];
            };
            cargoLock.lockFile = ./Cargo.lock;
            buildNoDefaultFeatures = true;
            cargoBuildFlags = [
              "-p"
              "skate-game"
              "--bin"
              "skate3rust"
              "-p"
              "skate-xiso"
              "--bin"
              "skate-xiso"
            ];
            # The tests read the private assets that setup extracts from the disc.
            doCheck = false;
            nativeBuildInputs = [
              pkgs.pkg-config
              pkgs.cmake
            ];
            # cmake is for the sdl3-sys build script, not this derivation.
            dontUseCmakeConfigure = true;
            buildInputs = linuxLinkedLibs pkgs ++ linuxLoadedLibs pkgs ++ sdlBuildLibs pkgs;
            postFixup = ''
              patchelf --add-rpath ${lib.makeLibraryPath (linuxLoadedLibs pkgs)} $out/bin/skate3rust
            '';
            meta.mainProgram = "skate3rust";
          };

          # tools/setup.py imports tools.* relative to the directory above it.
          setupTools = pkgs.runCommand "skate3-setup-tools" { } ''
            mkdir -p $out/share/skate3
            cp -r ${
              lib.fileset.toSource {
                root = ./.;
                fileset = ./tools;
              }
            }/tools $out/share/skate3/tools
          '';

          # Setup's conversion of a retail disc: assets, maps and the initial
          # settings. Nothing in the output may refer back to the disc.
          mkAssets =
            iso:
            pkgs.runCommand "skate3-assets"
              {
                nativeBuildInputs = [
                  (setupPython pkgs (_: [ ]))
                  pkgs.vgmstream
                  pkgs.jq
                ];
                SKATE_XISO = "${engine}/bin/skate-xiso";
                PYTHONDONTWRITEBYTECODE = 1;
                disallowedReferences = [ iso ];
              }
              ''
                export HOME="$TMPDIR"
                python ${setupTools}/share/skate3/tools/setup.py --base data \
                  --game-exe ${lib.getExe engine} --source ${iso}
                mkdir "$out"
                mv "data/$(jq -r .directory data/installation.json)"/* "$out"
              '';

          # The game root is assembled inside the sandbox: the store assets
          # read-only, and settings, mods and logs from $SKATE3_HOME (default:
          # $XDG_DATA_HOME/skate3), the only path the game can write.
          mkSkate3 = lib.makeOverridable (
            { iso }:
            let
              assets = mkAssets iso;
            in
            pkgs.writeShellApplication {
              name = "skate3";
              runtimeInputs = [
                (mkSandbox pkgs)
                pkgs.coreutils
              ];
              passthru = { inherit assets iso; };
              text = ''
                state="''${SKATE3_HOME:-''${XDG_DATA_HOME:-$HOME/.local/share}/skate3}"
                mkdir -p "$state"/{settings,mods,logs,home}
                for file in ${assets}/settings/*; do
                  [[ -e $state/settings/''${file##*/} ]] || install -m 644 "$file" "$state/settings/"
                done
                exec skate-sandbox --home "$state/home" --share-net \
                  --ro-bind ${assets}/assets /skate3/assets \
                  --ro-bind ${assets}/maps /skate3/maps \
                  --ro-bind ${assets}/maps.json /skate3/maps.json \
                  --bind "$state/settings" /skate3/settings \
                  --bind "$state/mods" /skate3/mods \
                  --bind "$state/logs" /skate3/logs \
                  --chdir /skate3 \
                  --setenv SKATE3_MODS /skate3/mods \
                  -- ${lib.getExe engine} --assets /skate3/assets "$@"
              '';
            }
          );

          skate3 = mkSkate3 {
            iso = pkgs.requireFile {
              name = "skate3.iso";
              sha256 = "28d91643cb205766c4b93a158821d7b00c897955e85b4378b81cb422169908af";
              message = ''
                The game assets are converted from your own Skate 3 Xbox 360 ISO.
                Add it to the Nix store once (the file must be named skate3.iso):

                  nix-prefetch-url --type sha256 file:///path/to/skate3.iso

                A different dump of the disc has a different hash; build with
                `skate3.override { iso = requireFile { ...; sha256 = "<hash>"; }; }`.
              '';
            };
          };
        in
        {
          inherit engine skate3;
          inherit (skate3) assets iso;
          default = skate3;
        }
      );

      ci = _: {
        caches = {
          skate3.path = self.packages.x86_64-linux.skate3;
          engine.path = self.packages.x86_64-linux.engine;
          assets.path = self.packages.x86_64-linux.skate3.assets;
          iso.path = self.packages.x86_64-linux.skate3.iso;
        };
      };

      formatter = forAllSystems (pkgs: pkgs.nixfmt);
    };
}
