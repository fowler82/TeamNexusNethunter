#!/bin/bash
# Samsung kernel for Samsung Galaxy Note 5 / S6 / S6 Edge / S6 Edge+ build script by jcadduono

################### BEFORE STARTING ################
#
# download a working toolchain and extract it somewhere and configure this
# file to point to the toolchain's root directory.
#
# once you've set up the config section how you like it, you can simply run
# ./build.sh [VARIANT]
#
##################### DEVICES ######################
#
# noblelte = Galaxy Note 5
#            SM-N920
#
# zenlte   = Galaxy S6 Edge+
#            SM-G928
#
# zerolte  = Galaxy S6 Edge
#            SM-G925
#
# zeroflte = Galaxy S6
#            SM-G920
#
##################### VARIANTS #####################
#
# can = W8 (Canada)
# eur = C/CD/F/FD (Europe)
# zt  = 0/8 (China Duos)
# spr = P (Sprint)
# tmo = T (T-Mobile)
# usc = R4 (US Cellular)
# ktt = K (Korea - KT Corporation)
# lgt = L (Korea - LG Telecom)
# skt = S (Korea - SK Telecom)
# kor = K/L/S (Korea - Unified)
#
###################### CONFIG ######################

# root directory of universal7420 kernel git repo (default is this script's location)
RDIR=$(pwd)

[ "$VER" ] ||
# version number
VER=$(cat "$RDIR/VERSION")

# directory containing cross-compile arm64 toolchain
TOOLCHAIN=/home/madscript/Toolchains-Compilation/gcc-linaro-4.9.4-2017.01-x86_64_aarch64-linux-gnu

CPU_THREADS=$(grep -c "processor" /proc/cpuinfo)
# amount of cpu threads to use in kernel make process
THREADS=$((CPU_THREADS + 1))

############## SCARY NO-TOUCHY STUFF ###############

ABORT()
{
	[ "$1" ] && echo "Error: $*"
	exit 1
}

export ARCH=arm64
export CROSS_COMPILE=$TOOLCHAIN/bin/aarch64-linux-gnu-

[ -x "${CROSS_COMPILE}gcc" ] ||
ABORT "Unable to find gcc cross-compiler at location: ${CROSS_COMPILE}gcc"

[ "$TARGET" ] || TARGET=nethunter
[ "$1" ] && DEVICE=$1
[ "$2" ] && VARIANT=$2
[ "$DEVICE" ] || DEVICE=zeroflte
[ "$VARIANT" ] || VARIANT=xx

DEFCONFIG=${TARGET}_${DEVICE}${VARIANT}_defconfig

[ -f "$RDIR/arch/$ARCH/configs/${DEFCONFIG}" ] ||
ABORT "Config $DEFCONFIG not found in $ARCH configs!"

export LOCALVERSION=madScript-$TARGET-$DEVICE-$VARIANT-$VER

CLEAN_BUILD()
{
	echo "Cleaning build..."
	rm -rf build
}

SETUP_BUILD()
{
	echo "Creating kernel config for $LOCALVERSION..."
	mkdir -p build
	make -C "$RDIR" O=build "$DEFCONFIG" \
		|| ABORT "Failed to set up build"
}

BUILD_KERNEL()
{
	echo "Starting build for $LOCALVERSION..."
	while ! make -C "$RDIR" O=build -j"$THREADS"; do
		read -rp "Build failed. Retry? " do_retry
		case $do_retry in
			Y|y) continue ;;
			*) return 1 ;;
		esac
	done
}

INSTALL_MODULES() {
	grep -q 'CONFIG_MODULES=y' build/.config || return 0
	echo "Installing kernel modules to build/lib/modules..."
	make -C "$RDIR" O=build \
		INSTALL_MOD_PATH="." \
		INSTALL_MOD_STRIP=1 \
		modules_install
	rm build/lib/modules/*/build build/lib/modules/*/source
}

BUILD_DTB()
{
	echo "Generating dtb.img..."
	./dtbgen.sh "$DEVICE" "$VARIANT" || ABORT "Failed to generate dtb.img!"
}

cd "$RDIR" || ABORT "Failed to enter $RDIR!"

CLEAN_BUILD &&
SETUP_BUILD &&
BUILD_KERNEL &&
INSTALL_MODULES &&
BUILD_DTB &&
echo "Finished building $LOCALVERSION!"

