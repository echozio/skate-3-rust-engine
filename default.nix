# Sandboxed dev shell: `nix run -f .`, or `$(nix-build)/bin/skate3-sandbox ARGS`
# Runs `nix develop` under bubblewrap with only the repo writable, the Nix
# store read-only, the Nix daemon socket, GPU devices and the display sockets.
let
  locked = (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.nixpkgs.locked;
  nixpkgs = fetchTarball {
    url = "https://github.com/${locked.owner}/${locked.repo}/archive/${locked.rev}.tar.gz";
    sha256 = locked.narHash;
  };
in
{
  pkgs ? import nixpkgs { },
}:
let
  repo = toString ./.;
  path = pkgs.lib.makeBinPath [
    pkgs.nix
    pkgs.git
    pkgs.bashInteractive
    pkgs.coreutils
  ];
in
pkgs.writeShellApplication {
  name = "skate3-sandbox";
  runtimeInputs = [ pkgs.bubblewrap ];
  text = ''
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
      --bind ${pkgs.lib.escapeShellArg repo} ${pkgs.lib.escapeShellArg repo}
      --chdir ${pkgs.lib.escapeShellArg repo}
      --symlink ${pkgs.bashInteractive}/bin/sh /bin/sh
      --symlink ${pkgs.coreutils}/bin/env /usr/bin/env
      --ro-bind-try /etc/resolv.conf /etc/resolv.conf
      --ro-bind-try /etc/hosts /etc/hosts
      --ro-bind-data 3 /etc/passwd
      --ro-bind-data 4 /etc/group
      # GPU: DRM render nodes, NVIDIA devices, sysfs for driver probing and
      # the NixOS driver tree the Vulkan loader finds ICDs in.
      --dev-bind-try /dev/dri /dev/dri
      --ro-bind-try /sys/dev/char /sys/dev/char
      --ro-bind-try /sys/devices /sys/devices
      --ro-bind-try /run/opengl-driver /run/opengl-driver
      --ro-bind-try /run/opengl-driver-32 /run/opengl-driver-32
      --setenv HOME ${pkgs.lib.escapeShellArg repo}/.local/home
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
    for dev in /dev/nvidia*; do
      [[ -e $dev ]] && args+=(--dev-bind "$dev" "$dev")
    done

    if [[ -n ''${XDG_RUNTIME_DIR:-} ]]; then
      args+=(--tmpfs "$XDG_RUNTIME_DIR" --setenv XDG_RUNTIME_DIR "$XDG_RUNTIME_DIR")
      if [[ -n ''${WAYLAND_DISPLAY:-} ]]; then
        socket="$WAYLAND_DISPLAY"
        [[ $socket == /* ]] || socket="$XDG_RUNTIME_DIR/$socket"
        args+=(--ro-bind-try "$socket" "$socket" --setenv WAYLAND_DISPLAY "$WAYLAND_DISPLAY")
      fi
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

    mkdir -p ${pkgs.lib.escapeShellArg repo}/.local/home
    exec bwrap "''${args[@]}" -- nix develop "$@" \
      3< <(printf '%s:x:%s:%s::%s:/bin/sh\n' "$(id -un)" "$(id -u)" "$(id -g)" ${pkgs.lib.escapeShellArg repo}/.local/home) \
      4< <(printf '%s:x:%s:\n' "$(id -gn)" "$(id -g)")
  '';
}
