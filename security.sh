#!/bin/sh
set -e
RESOLV_CONF="/etc/resolv.conf"
HBLOCK_VERSION="3.5.1"
HBLOCK_SHA256="d010cb9e0f3c644e9df3bfb387f42f7dbbffbbd481fb50c32683bbe71f994451"
DNS_SERVERS="nameserver 1.1.1.3
nameserver 1.0.0.3
nameserver 2606:4700:4700::1113
nameserver 2606:4700:4700::1003"

if [ "$(id -u)" -ne 0 ]; then
    printf "Error: Must run as root\n" >&2
    exit 1
fi

detect_resolver() {
    if [ -L "${RESOLV_CONF}" ]; then
        RESOLV_TARGET="$(readlink -f "${RESOLV_CONF}")"
        case "${RESOLV_TARGET}" in
            */run/systemd/resolve/*)
                return 1
                ;;
            */run/NetworkManager/*)
                return 2
                ;;
        esac
    fi
    
    if pidof systemd-resolved >/dev/null 2>&1; then
        return 1
    elif pidof NetworkManager >/dev/null 2>&1 || command -v nmcli >/dev/null 2>&1; then
        return 2
    elif command -v resolvconf >/dev/null 2>&1; then
        return 3
    fi
    return 0
}

configure_systemd_resolved() {
    printf "Configuring systemd-resolved...\n"
    mkdir -p /etc/systemd/resolved.conf.d
    cat > /etc/systemd/resolved.conf.d/cloudflare-dns.conf <<EOF
[Resolve]
DNS=1.1.1.3 1.0.0.3 2606:4700:4700::1113 2606:4700:4700::1003
FallbackDNS=
DNSOverTLS=yes
DNSSEC=yes
EOF
    systemctl restart systemd-resolved
    printf "systemd-resolved configured\n"
}

configure_networkmanager() {
    printf "Configuring NetworkManager...\n"
    cat > /etc/NetworkManager/conf.d/dns.conf <<EOF
[main]
dns=none
EOF
    systemctl reload NetworkManager 2>/dev/null || true
    configure_resolv_conf
    chattr +i "${RESOLV_CONF}" 2>/dev/null || chmod 444 "${RESOLV_CONF}"
    printf "NetworkManager configured\n"
}

configure_resolvconf() {
    printf "Configuring resolvconf...\n"
    mkdir -p /etc/resolvconf/resolv.conf.d
    printf "%s\n" "${DNS_SERVERS}" > /etc/resolvconf/resolv.conf.d/head
    if command -v resolvconf >/dev/null 2>&1; then
        resolvconf -u
    fi
    printf "resolvconf configured\n"
}

configure_resolv_conf() {
    if [ -f "${RESOLV_CONF}" ] && [ ! -L "${RESOLV_CONF}" ]; then
        cp "${RESOLV_CONF}" "${RESOLV_CONF}.bak.$(date +%Y%m%d%H%M%S)"
    fi
    
    if [ -L "${RESOLV_CONF}" ]; then
        rm -f "${RESOLV_CONF}"
    fi
    
    printf "# Cloudflare DNS - Malware & Adult Content Filtering\n" > "${RESOLV_CONF}"
    printf "%s\n" "${DNS_SERVERS}" >> "${RESOLV_CONF}"
}

install_hblock() {
    printf "Installing hblock...\n"
    
    HBLOCK_URL="https://raw.githubusercontent.com/hectorm/hblock/v${HBLOCK_VERSION}/hblock"
    
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL -o /tmp/hblock "${HBLOCK_URL}"
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O /tmp/hblock "${HBLOCK_URL}"
    else
        printf "Error: curl or wget required\n" >&2
        return 1
    fi
    
    if command -v sha256sum >/dev/null 2>&1; then
        printf "%s  /tmp/hblock\n" "${HBLOCK_SHA256}" | sha256sum -c -
    elif command -v shasum >/dev/null 2>&1; then
        printf "%s  /tmp/hblock\n" "${HBLOCK_SHA256}" | shasum -a 256 -c -
    else
        printf "Warning: Cannot verify checksum\n" >&2
    fi
    
    mv /tmp/hblock /usr/local/bin/hblock
    chown 0:0 /usr/local/bin/hblock
    chmod 755 /usr/local/bin/hblock
    
    /usr/local/bin/hblock
    
    if command -v crontab >/dev/null 2>&1; then
        (crontab -l 2>/dev/null | grep -v hblock; printf "0 3 * * * /usr/local/bin/hblock -qS none\n") | crontab -
        printf "hblock scheduled daily at 3 AM\n"
    fi
    
    printf "hblock installed successfully\n"
}

printf "Configuring DNS filtering...\n"

detect_resolver
RESOLVER_TYPE=$?

case ${RESOLVER_TYPE} in
    1)
        configure_systemd_resolved
        ;;
    2)
        configure_networkmanager
        ;;
    3)
        configure_resolvconf
        ;;
    0)
        configure_resolv_conf
        chattr +i "${RESOLV_CONF}" 2>/dev/null || chmod 444 "${RESOLV_CONF}"
        ;;
esac

install_hblock

printf "\nDNS Configuration Complete\n"
printf "Active DNS servers:\n"
cat "${RESOLV_CONF}" 2>/dev/null || resolvectl status 2>/dev/null | grep "DNS Servers" || printf "Check your resolver configuration\n"

exit 0
