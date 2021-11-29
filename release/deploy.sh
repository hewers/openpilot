#!/bin/bash
# Deploy pre-built minimum size
# Untested, will explode.
set -euxo pipefail

# Use 1st argument as branch, or default
REPO="${1:-qadmus/deploy}"
USER=`echo $REPO | cut -d'/' -f1`
BRANCH=`echo $REPO | cut -d'/' -f2`
OP_DIR=op.$USER.$BRANCH

# ips for tether, two, three
ips=("192.168.43.1" "tici.local")
for ip in ${ips[@]}; do
    if ping -c 1 -W 1 "$ip"; then
        DEVICE_IP=$ip
        break
    fi
done
if [ -z "$DEVICE_IP" ]; then
    echo No comma device pingable
    exit 1
fi

# Local shallow clone of branch
rm -rf $OP_DIR
git clone --depth=1 --single-branch --no-tags --recurse-submodules --shallow-submodules --j $(nproc) \
git@github.com:$USER/openpilot.git --branch $BRANCH $OP_DIR

# Remote delete branch folder
ssh comma@$DEVICE_IP -p 8022 -i ~/.ssh/id_ed25519 -T <<ENDSSH
rm -rf /data/$OP_DIR
ENDSSH

# Copy local to remote
rsync -avP -e 'ssh -p 8022 -i ~/.ssh/id_ed25519' $OP_DIR comma@$DEVICE_IP:/data/
# Delete local
rm -rf $OP_DIR

# Build & cleanup on remote
ssh comma@$DEVICE_IP -p 8022 -i ~/.ssh/id_ed25519 -T <<ENDSSH

cd /data/$OP_DIR

tmux kill-server || true
sudo python3 ./system/hardware/tici/hardware.py
scons -j$(nproc)

mv panda/board/obj/panda.bin.signed /tmp/panda.bin.signed

find . -name '*.a' -delete
find . -name '*.o' -delete
find . -name '*.os' -delete
find . -name '*.pyc' -delete
find . -name 'moc_*' -delete
find . -name '__pycache__' -delete
rm -rf panda/board panda/certs panda/crypto
rm -rf .sconsign.dblite Jenkinsfile release/
rm selfdrive/modeld/models/supercombo.dlc

mkdir -p panda/board/obj
mv /tmp/panda.bin.signed panda/board/obj/panda.bin.signed
git checkout third_party/
touch prebuilt

rm -rf .git
rm -rf /data/log/*
rm -rf /data/media/0/realdata/boot
rm -rf /data/scons_cache/*
rm -rf /tmp/scons_cache/*

# Final step: switch out openpilot for this branch
rm -rf /data/openpilot
ln -s /data/$OP_DIR /data/openpilot

if [ $(hostname) == 'TICI' ]; then
    sudo reboot
else
    reboot
fi

ENDSSH