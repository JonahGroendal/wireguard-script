#! /usr/bin/env bash
umask 077

# ipv4="$1$4"
# ipv6="$2$4"
# serv4="${1}1"
# serv6="${2}1"
# target="$3"
# name="$5"
name="$1"

# get current clients count then increment
count=$(head -n 1 client-count)
echo "$(($count + 1))" > client-count

ipv4="192.168.3.${count}"

wg genkey | tee "${name}.key" | wg pubkey > "${name}.pub"
wg genpsk > "${name}.psk"

echo "# $name" >> /etc/wireguard/wg0.conf
echo "[Peer]" >> /etc/wireguard/wg0.conf
echo "PublicKey = $(cat "${name}.pub")" >> /etc/wireguard/wg0.conf
echo "PresharedKey = $(cat "${name}.psk")" >> /etc/wireguard/wg0.conf
echo "AllowedIPs = $ipv4/32" >> /etc/wireguard/wg0.conf
echo "" >> /etc/wireguard/wg0.conf

echo "[Interface]" > "wg-${name}.conf"
echo "Address = $ipv4/32" >> "wg-${name}.conf"
# echo "DNS = ${serv4}, ${serv6}" >> "wg-${name}.conf" #Specifying DNS Server
echo "PrivateKey = $(cat "${name}.key")" >> "wg-${name}.conf"
echo "" >> "wg-${name}.conf"
echo "[Peer]" >> "wg-${name}.conf"
echo "PublicKey = $(cat server.pub)" >> "wg-${name}.conf"
echo "PresharedKey = $(cat "${name}.psk")" >> "wg-${name}.conf"
echo "Endpoint = www.mightymistclean.com:51820" >> "wg-${name}.conf"
# echo "AllowedIPs = ${serv4}/32, ${serv6}/128" >> "wg-${name}.conf" # clients isolated from one another
# echo "AllowedIPs = ${1}0/24, ${2}/64" >> "wg-${name}.conf" # clients can see each other
echo "AllowedIPs = 0.0.0.0/0, ::/0" >> "wg-${name}.conf"
echo "PersistentKeepalive = 21" >> "wg-${name}.conf"

echo "[Interface]" > "wg-${name}-lan-only.conf"
echo "Address = $ipv4/32" >> "wg-${name}-lan-only.conf"
# echo "DNS = ${serv4}, ${serv6}" >> "wg-${name}-lan-only.conf" #Specifying DNS Server
echo "PrivateKey = $(cat "${name}.key")" >> "wg-${name}-lan-only.conf"
echo "" >> "wg-${name}-lan-only.conf"
echo "[Peer]" >> "wg-${name}-lan-only.conf"
echo "PublicKey = $(cat server.pub)" >> "wg-${name}-lan-only.conf"
echo "PresharedKey = $(cat "${name}.psk")" >> "wg-${name}-lan-only.conf"
echo "Endpoint = www.mightymistclean.com:51820" >> "wg-${name}-lan-only.conf"
echo "AllowedIPs = 192.168.1.0/24, 192.168.2.0/24, 192.168.3.0/24" >> "wg-${name}-lan-only.conf"
echo "PersistentKeepalive = 21" >> "wg-${name}-lan-only.conf"

chown "${SUDO_USER:-${USER}}:" "wg-${name}.conf"
chown "${SUDO_USER:-${USER}}:" "wg-${name}-lan-only.conf"

rm "${name}.pub"
rm "${name}.psk"
rm "${name}.key"

# Print QR code scanable by the Wireguard mobile app on screen
qrencode -t ansiutf8 < "wg-${name}.conf"
qrencode -t ansiutf8 < "wg-${name}-lan-only.conf"

systemctl restart wg-quick@wg0
