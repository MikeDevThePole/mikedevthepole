arch=$(uname -m)
base_url="http://dl-cdn.alpinelinux.org/alpine/edge/releases/${arch}"
file_name=$(curl -s "${base_url}/latest-releases.yaml" | grep -oP 'alpine-minirootfs-\S+' | head -n 1)
wget -c "${base_url}/${file_name}"

set +e
mkdir -p alpine
tar -xzf $file_name -C alpine
rm $file_name
cp /etc/resolv.conf alpine/etc/

cat > alpine/etc/apk/repositories << EOF
https://dl-cdn.alpinelinux.org/alpine/edge/main
https://dl-cdn.alpinelinux.org/alpine/edge/community
https://dl-cdn.alpinelinux.org/alpine/edge/testing
EOF

cat > alpine.sh << EOF
if [ "\$EUID" -ne 0 ]; then
    exec sudo "\$0" "\$@"
    exit 1
fi

cleanup() {
    echo "Unmounting..."
    set +e
    umount alpine/dev/pts
    umount alpine/dev
    umount alpine/sys
    umount alpine/proc
    set -e
}
trap cleanup EXIT INT TERM

mount -t proc /proc alpine/proc
mount -t sysfs /sys alpine/sys
mount -o bind /dev alpine/dev
mount -t devpts /dev/pts alpine/dev/pts

chroot alpine /usr/bin/env -i HOME=/root TERM="\$TERM" COLORTERM="\$COLORTERM" /bin/ash -l
EOF

chmod +x alpine.sh
set -e
