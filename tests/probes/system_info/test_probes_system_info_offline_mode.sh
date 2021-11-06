#!/usr/bin/env bash

# Copyright 2018 Red Hat Inc., Durham, North Carolina.
# All Rights Reserved.
#
# OpenSCAP Test Suite
#
# Authors:
#      Jan Černý <jcerny@redhat.com>

. $builddir/tests/test_common.sh

set -e -o pipefail

function test_offline_mode_system_info_offline {
	# This test is dependent on /etc/os-release being present, so skip this test if it doesn't exist.
	[ -f "/etc/os-release" ] || return 255

	temp_dir="$(mktemp -d)"

	ln -s /etc $temp_dir

	result="$(mktemp)"

	set_chroot_offline_test_mode "$temp_dir"

	$OSCAP oval eval --results $result $srcdir/test_probes_system_info.oval.xml

	unset_chroot_offline_test_mode

	[ -s "$result" ]

	. /etc/os-release

	case $(uname) in
		FreeBSD)
			HOSTNAME=`grep hostname= /etc/rc.conf | cut -d '"' -f 2`
			;;
		*)
			HOSTNAME=`cat /etc/hostname`
			;;
	esac

	assert_exists 1 '/oval_results/results/system/oval_system_characteristics/system_info'
	assert_exists 1 "/oval_results/results/system/oval_system_characteristics/system_info/os_name[text()=\"${NAME}\"]"
	assert_exists 1 "/oval_results/results/system/oval_system_characteristics/system_info/os_version[text()=\"${VERSION}\"]"
	assert_exists 1 '/oval_results/results/system/oval_system_characteristics/system_info/architecture[text()="Unknown"]'
	assert_exists 1 "/oval_results/results/system/oval_system_characteristics/system_info/primary_host_name[text()=\"${HOSTNAME}\"]"

	assert_exists 1 '/oval_results/results/system/oval_system_characteristics/system_info/interfaces'
	# Getting network interfaces information from the guest is not implemented,
	# check if there are no interfaces from the host
	assert_exists 0 '/oval_results/results/system/oval_system_characteristics/system_info/interfaces/interface'

	rm -rf "$temp_dir"
	rm -f "$result"
}

test_run "test_offline_mode_system_info_offline" test_offline_mode_system_info_offline
