#!/usr/bin/env bash

# Check for uninitialized variables
set -u
# Exit on error
set -e

echo "Installing EPICS"

# Source environment variables
. ./env-vars.sh

# Source EPICS variables
. ./bash.bashrc.local

USER=$(whoami)
TOP_DIR=$(pwd)
EPICS_ENV_DIR=/etc/profile.d
LDCONF_DIR=/etc/ld.so.conf.d
EPICS_EXTENSIONS_SRC=${EPICS_EXTENSIONS}/src

# Install EPICS base and used modules

# Source repo versions
. ./repo-versions.sh

EPICS_MSI=${EPICS_EXTENSIONS_SRC}/msi${MSI_VERSION}
EPICS_PROCSERV=${EPICS_EXTENSIONS_SRC}/procServ-${PROCSERV_VERSION}

if [ "${DOWNLOAD_APP}" == "yes" ]; then
    wget -nc http://www.aps.anl.gov/epics/download/base/baseR${EPICS_BASE_VERSION}.tar.gz
    wget -nc http://www.aps.anl.gov/epics/download/extensions/extensionsTop_${EXTERNSIONS_VERSION}.tar.gz
    wget -nc http://www.aps.anl.gov/epics/download/extensions/msi${MSI_VERSION}.tar.gz
    wget -nc http://downloads.sourceforge.net/project/procserv/${PROCSERV_VERSION}/procServ-${PROCSERV_VERSION}.tar.gz
fi

############################## EPICS Base #####################################

if [ "${INSTALL_APP}" == "no" ]; then
    # Good for debug
    echo "Not installing EPICS per user request (-i flag not set)"
    exit 0
fi

# Prepare environment
sudo mkdir -p ${EPICS_FOLDER}
sudo chmod 755 ${EPICS_FOLDER}
sudo chown ${USER}:${USER} ${EPICS_FOLDER}

# Copy EPICS environment variables to profile
sudo bash -c "cat ${TOP_DIR}/bash.bashrc.local >> /etc/profile.d/epics.sh"

# Extract and install EPICS
cd ${EPICS_FOLDER}
tar xvzf ${TOP_DIR}/baseR${EPICS_BASE_VERSION}.tar.gz

# Remove possible existing symlink
rm -f base
# Symlink to EPICS base
ln -sf base-${EPICS_BASE_VERSION} base

# Update ldconfig with EPICS libs
sudo touch ${LDCONF_DIR}/epics.conf
echo "${EPICS_BASE}/lib/${EPICS_HOST_ARCH}" | sudo tee -a /etc/ld.so.conf.d/epics.conf
echo "/usr/lib64" | sudo tee -a /etc/ld.so.conf.d/epics.conf
echo "/lib64" | sudo tee -a /etc/ld.so.conf.d/epics.conf
echo "/usr/lib" | sudo tee -a /etc/ld.so.conf.d/epics.conf

# Update ldconfig cache
sudo ldconfig

# Compile EPICS base
cd ${EPICS_BASE}
make
if [ "${CLEANUP_APP}" == "yes" ]; then
    make clean
fi

############################ EPICS Extensions ##################################

# Extract and install extensions
cd ${EPICS_FOLDER}
tar xvzf ${TOP_DIR}/extensionsTop_${EXTERNSIONS_VERSION}.tar.gz

# Jump to dir and compile
cd ${EPICS_EXTENSIONS}
make
make install
if [ "${CLEANUP_APP}" == "yes" ]; then
    make clean
fi

########################### EPICS msi Extension ################################

cd ${EPICS_EXTENSIONS_SRC}
tar xvzf ${TOP_DIR}/msi${MSI_VERSION}.tar.gz

cd ${EPICS_MSI}
make
make install
if [ "${CLEANUP_APP}" == "yes" ]; then
    make clean
fi

######################### EPICS procServ Extension #############################

cd ${EPICS_EXTENSIONS_SRC}
tar xvzf ${TOP_DIR}/procServ-${PROCSERV_VERSION}.tar.gz

cd ${EPICS_PROCSERV}
./configure
make
sudo make install
if [ "${CLEANUP_APP}" == "yes" ]; then
    make clean
fi

echo "EPICS installation successfully completed"
