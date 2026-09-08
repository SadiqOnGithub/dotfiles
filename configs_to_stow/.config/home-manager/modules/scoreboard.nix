{ pkgs, lib, config, ... }:

let
  src = ./scoreboard/py;
  gcloud = pkgs.google-cloud-sdk;
  scoreboardPath = lib.makeBinPath [ gcloud ];
  scoreboard = pkgs.writeShellScriptBin "scoreboard" ''
    export PYTHONPATH=${src}
    export TZDIR=${pkgs.tzdata}/share/zoneinfo
    export PYTHONDONTWRITEBYTECODE=1
    export PATH=${scoreboardPath}:$PATH
    exec ${pkgs.python3}/bin/python3 -m scoreboard "$@"
  '';
  scoreboardBin = "${scoreboard}/bin/scoreboard";
  overlay = pkgs.writeShellScript "scoreboard-overlay" ''
    exec ${scoreboardBin} watch
  '';
  python = "${pkgs.python3}/bin/python3";
  windowExists = ./scoreboard/window-exists.py;
  toggle = pkgs.writeShellScriptBin "scoreboard-toggle" ''
    set -euo pipefail
    exists() {
      i3-msg -t get_tree | ${python} ${windowExists}
    }

    if exists; then
      i3-msg '[title="^scoreboard$"] scratchpad show' >/dev/null
      exit 0
    fi

    ghostty --class=scoreboard --x11-instance-name=scoreboard -e ${overlay} >/dev/null 2>&1 &

    i=0
    while [ "$i" -lt 100 ]; do
      if exists; then
        i3-msg '[title="^scoreboard$"] floating enable, resize set 900 560, move position center, move scratchpad, scratchpad show' >/dev/null
        exit 0
      fi
      i=$((i + 1))
      sleep 0.1
    done
    echo "scoreboard window did not appear" >&2
    exit 1
  '';
in
{
  home.packages = [ scoreboard toggle gcloud ];

  xdg.configFile."scoreboard/config.toml".text = ''
    # Managed by Home Manager. Overrides: ~/.config/scoreboard/local.toml
    # Google: scoreboard auth  (uses gcloud; Tasks API readonly)
    timezone = "Asia/Kolkata"
    commit_target_min = 5
    commit_target_max = 10
    commit_target_on = "local"
    github = true
    poll_seconds = 30
    git_author_emails = ["sadiqonemail@gmail.com"]
    git_roots = ["~/dotfiles", "~/Documents", "~/Arduino"]
    google_quota_project = "gen-lang-client-0236258077"
  '';

  systemd.user.services.scoreboard-snapshot = {
    Unit.Description = "Scoreboard snapshot (Tasks + git + GitHub)";
    Service = {
      Type = "oneshot";
      ExecStart = "${scoreboardBin} snapshot";
      Environment = "PATH=${scoreboardPath}:/usr/bin:/bin:${config.home.homeDirectory}/.nix-profile/bin";
    };
  };

  systemd.user.timers.scoreboard-snapshot = {
    Unit.Description = "Scoreboard snapshot every 10 minutes";
    Timer = {
      OnCalendar = "*-*-* *:00/10:00";
      Persistent = true;
      AccuracySec = "1min";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
