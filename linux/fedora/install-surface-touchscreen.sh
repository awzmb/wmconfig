#/bin/sh
# NOTE: run this after install-surface.sh

# install ithc dkms module
TMPDIR=$(mktemp)
mkdir -p ${TMPDIR}
git clone https://github.com/quo/ithc-linux.git ${TMPDIR}/ithc
cd ${TMPDIR}/ithc
sudo sudo make dkms-install
