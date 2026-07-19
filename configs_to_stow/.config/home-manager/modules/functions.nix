{ ... }:

{
  home.file.".config/shell/functions.sh".text = ''
    # ===========================
    # history grep
    # ===========================
    hg() {
      history | grep "$1"
    }

    # ===========================
    # list grep
    # ===========================
    lg() {
      ll | grep "$1"
    }

    # ===========================
    # find dir
    # ===========================
    fd() {
      find . -type d -name "*$1*"
    }

    # ===========================
    # find file
    # ===========================
    ff() {
      find . -type f -name "*$1*"
    }

    # ===========================
    # PORT forwarding
    # ===========================
    pf() {
      ssh -N -L "$1":localhost:"$1" "$2"
    }

    psf() {
      local remote_host="$1"
      shift
      for local_port in "$@"; do
        ssh -N -L "$local_port":localhost:"$local_port" "$remote_host" &
      done
    }

    list_forwarded_ports() {
      lsof -i -n -P | grep 'LISTEN'
    }

    stop_pf() {
      local port=$1
      if [[ -z "$port" ]]; then
        echo "Usage: stop_pf PORT"
        return 1
      fi
      local pid=$(lsof -ti tcp:"$port" -sTCP:LISTEN)
      if [[ -n "$pid" ]]; then
        kill "$pid"
        echo "Port forwarding on port $port stopped."
      else
        echo "No active port forwarding found on port $port."
      fi
    }
  '';
}
