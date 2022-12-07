#!/bin/bash -e
#
# Build gitcache on Ubuntu
#

if [ $# -ne 1 ]; then
    echo "Usage: $0 <target file name>"
    echo
    echo "Build gitcache and move the binary to <target file name>."
    echo
    echo "Example:"
    echo "  $0 gitcache_v1.0.0_$(lsb_release -i -s)$(lsb_release -r -s)_amd64"
    exit 1
fi
TARGET_FILE="$1"

export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true

cat > /tmp/tzdata_preseed <<EOF
tzdata tzdata/Areas select Europe
tzdata tzdata/Zones/Europe select Berlin
EOF
debconf-set-selections /tmp/tzdata_preseed

apt-get update
apt-get -y dist-upgrade

apt-get -y install lsb-release make binutils git git-lfs jq

if [ $(lsb_release -r -s) == "18.04" ]; then
    apt-get -y install software-properties-common
    add-apt-repository ppa:deadsnakes/ppa
    apt-get update
    apt-get -y install python3-venv python3.8-dev python3.8-venv
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 1
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 2
else
    apt-get -y install python3-dev python3-venv
fi

ln -sf bash /bin/sh

function cleanup() {
    echo "Cleanup..."
    cd /workdir
    make clean || true
}
trap cleanup EXIT

if [ $(lsb_release -r -s) == "21.04" ]; then
    git config --global pull.rebase false
fi

cd /workdir
git lfs install
make clean
make unittests.venv
make pyinstaller.venv
make pyinstaller-test

mv dist/gitcache ${TARGET_FILE}
chown $TGTUID:$TGTGID ${TARGET_FILE}
