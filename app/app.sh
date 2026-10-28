#!/bin/bash

show_help() {
    cat <<'EOF'
Usage:
  ./app/app.sh system-info
  ./app/app.sh check-host <host>
  ./app/app.sh check-port <host> <port>
  ./app/app.sh help
EOF
}

system_info() {
    echo "=== System Information ==="
    echo "Hostname: $(hostname)"
    echo "Current user: $(whoami)"
    echo "Date and time: $(date)"
    echo "Operating system:"
    if [[ -r /etc/os-release ]]; then
        grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2- | tr -d '"'
    else
        uname -s
    fi
    echo "Kernel: $(uname -r)"
    echo "Uptime: $(uptime 2>/dev/null || echo 'Unavailable')"
    echo "Current directory: $(pwd)"
}

valid_host() {
    local host="$1"

    # Reject empty values and values containing whitespace or shell-sensitive separators.
    [[ -n "$host" && "$host" != -* && "$host" != *[[:space:]\;\&\|\(\)]* ]]
}

check_host() {
    local host="$ 1 "

    if ! valid_host "$host"; then
        echo "Error: provide a valid hostname or IP address." >&2
        return 2
    fi

    echo "Checking host: $host"
    if command -v getent >/dev/null 2>&1 && getent hosts "$host"; then
        echo "Host resolution: successful"
    else
        echo "Error: could not resolve host '$host'." >&2
        return 1
    fi

    if command -v ping >/dev/null 2>&1 && ping -c 1 -W 2 "$host" >/dev/null 2>&1; then
        echo "Connectivity: reachable"
        return 0
    else
        echo "Connectivity: ping failed or blocked"
        # DNS resolution worked, so report the host check as successful even if ICMP is blocked.
        return 0
    fi
}

check_port() {
    local host="$1"
    local port="$2"

    if ! valid_host "$host"; then
        echo "Error: provide a valid hostname or IP address." >&2
        return 2
    fi

    if [[ ! "$port" =~ ^[0-9]+$ ]] || (( 10#$port < 1 || 10#$port > 65535 )); then
        echo "Error: port must be an integer from 1 to 65535." >&2
        return 2
    fi

    echo "Checking TCP port $port on $host..."
    if timeout 3 bash -c ":</dev/tcp/$host/$port" 2>/dev/null; then
        echo "TCP port $port: reachable"
        return 0
    else
        echo "TCP port $port: not reachable"
        return 1
    fi
}

case "${1:-}" in
    system-info)
        [[ $# -eq 1 ]] || { echo "Error: system-info takes no arguments." >&2; exit 2; }
        system_info
        ;;
    check-host)
        [[ $# -eq 2 ]] || { echo "Error: check-host requires a host." >&2; show_help >&2; exit 2; }
        check_host "$2"
        exit $?
        ;;
    check-port)
        [[ $# -eq 3 ]] || { echo "Error: check-port requires a host and port." >&2; show_help >&2; exit 2; }
        check_port "$2" "$3"
        exit $?
        ;;
    help)
        [[ $# -eq 1 ]] || { echo "Error: help takes no arguments." >&2; exit 2; }
        show_help
        ;;
    *)
        echo "Error: invalid command '${1:-}'." >&2
        show_help >&2
        exit 2
        ;;
esac
