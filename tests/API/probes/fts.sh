#!/usr/bin/env bash
#
# Copyright 2011 Red Hat Inc., Durham, North Carolina.
# All Rights Reserved.
#
# Authors:
#      Daniel Kopecek <dkopecek@redhat.com>
#      Tomas Heinrich <theinric@redhat.com>

. $builddir/tests/test_common.sh

function gen_tree {
	echo "Generating tree for traversal" >&2

	mkdir -p $ROOT/{d1/{d11/d111,d12},d2/d21}
	touch $ROOT/{d1/{d11/{d111/f1111,f111,f112,f113},d12/f121,f11},d2/{d21/f211,f21}}
}

function oval_fts {
	echo "=== $1 ==="
	shift
	./oval_fts_list "$@" | sort | tee ${tmpdir}/oval_fts_list.out | \
		sed "s|${ROOT}/||" | tr '\n' ',' > ${tmpdir}/oval_fts_list.out2
	if [ $? -ne 0 ]; then
		echo "oval_fts_list failed"
		return 2
	fi

	shift 10
	echo -e "expected result:\n$1\noval_fts_list.out2:"
	cat ${tmpdir}/oval_fts_list.out2
	echo
	if [ "$(cat ${tmpdir}/oval_fts_list.out2 | openssl md5)" == \
		"$(echo -n $1 | openssl md5)" ]; then
		return 0
	else
		return 1
	fi
}

set -e -o pipefail

if [ -n "${CUSTOM_OSCAP+x}" ] ; then
	exit 255
fi

name=$(basename $0 .sh)
tmpdir=$(make_temp_dir /tmp ${name})

ROOT=${tmpdir}/ftsroot
echo "Temp dir: ${tmpdir}."
gen_tree $ROOT

# The format for the arguments is as follows:
#
# <name of test>
# <path_operation_number> <path_operation_argument>
# <filename_operation_number> <filename_operation_argument>
# <filepath_operation_number> <filepath_operation_argument>
# <behaviors_max_depth> <behaviors_recurse> <behaviors_recurse_direction> <behaviors_recurse_file_system>
#
# When path is specified, filename must also be. Else, filepath can be
# specified. The first case is equivalent to the following SEXPs:
#
# ((path :operation <path_operation_number>) <path_operation_argument>)
# ((filename :operation <filename_operation_number>) <filename_operation_argument)
# ---empty filepath expression---
# ((behaviors :max_depth <behaviors_max_depth> :recurse <behaviors_recurse> :recurse_direction <behaviors_recurse_direction> :recurse_file_system <behaviors_recurse_file_system>))
#
# Else with filepath:
#
# ---empty path expression---
# ---empty filename expression---
# ((filepath :operation <filepath_operation_number>) <filepath_operation_argument>)
# ((behaviors :max_depth <behaviors_max_depth> :recurse <behaviors_recurse> :recurse_direction <behaviors_recurse_direction> :recurse_file_system <behaviors_recurse_file_system>))
#
# When both <*_operation_number> and <*_operation_argument> are empty, the
# resulting SEXP is not add. When <*_operation_argument> is empty, the
# resulting SEXP looks like:
#     ((* :operation <*_operation_number))
# For filename only, if <filename_operation_argument> is equal to the string
# "EMPTY_STRING", the resulting SEXP looks like:
#     ((filename :operation <filename_operation_number>) '')
#
# In general the utilized values of operation_number are:
#   equals (5) - a comparison against a fixed string
#   pattern match (11) - a regex based comparison
# and the value of the argument is then directly passed as a string.
#
# behaviors_recurse can be some combination of "symlinks" and "directories"
#
# behaviors_recurse_direction can either be none, down, or up
#
# behaviors_recurse_file_system is commonly used as all or local
#
# All of this is implemented in oval_fts_list.c.

while read args; do
	[ -z "${args%%#*}" ] && continue
	eval oval_fts $args
done <<EOF
test1 \
'' '' \
'' '' \
"equals" "$ROOT/d1/d12/f121" \
"-1" "symlinks and directories" "none" "all" \
d1/d12/f121,

test2 \
'' '' \
'' '' \
"pattern match" "^$ROOT/d1/.*/f1111" \
"-1" "symlinks and directories" "none" "all" \
d1/d11/d111/f1111,

test3 \
"equals" "$ROOT/d2" \
"equals" "f21" \
'' '' \
"-1" "symlinks and directories" "none" "all" \
d2/f21,

test4 \
"equals" "$ROOT/d1/d11" \
"pattern match" "^f11[23]$" \
'' '' \
"-1" "symlinks and directories" "none" "all" \
d1/d11/f112,d1/d11/f113,

test5 \
"pattern match" "^$ROOT/d1/d1[12]$" \
"pattern match" "^f..1$" \
'' '' \
"-1" "symlinks and directories" "none" "all" \
d1/d11/f111,d1/d12/f121,

test6 \
"pattern match" "^$ROOT/d1/.*" \
"equals" "f1111" \
'' '' \
"-1" "symlinks and directories" "none" "all" \
d1/d11/d111/f1111,

test7 \
"equals" "$ROOT/d1" \
"equals" "f112" \
'' '' \
"-1" "symlinks and directories" "down" "all" \
d1/d11/f112,

test8 \
"equals" "$ROOT/d1" \
"pattern match" "^f.*1$" \
'' '' \
"1" "symlinks and directories" "down" "all" \
d1/d11/f111,d1/d12/f121,d1/f11,

test9 \
"equals" "$ROOT/d1/d11/d111" \
"equals" "f11" \
'' '' \
"3" "symlinks and directories" "up" "all" \
d1/f11,

test10 \
"equals" "$ROOT/d2" \
"pattern match" "^f21.*$" \
'' '' \
"-1" "symlinks and directories" "down" "all" \
d2/d21/f211,d2/f21,

test11 \
"equals" "$ROOT/d2" \
"pattern match" "^f21.*$" \
'' '' \
"-1" "symlinks" "down" "all" \
d2/f21,

test12 \
"equals" "$ROOT/d1" \
"equals" "" \
'' '' \
"0" "symlinks and directories" "none" "all" \
d1/,

test13 \
"equals" "$ROOT/d1" \
"equals" "" \
'' '' \
"0" "symlinks and directories" "down" "all" \
d1/,

test14 \
"equals" "$ROOT/d1" \
"equals" "" \
'' '' \
"0" "symlinks and directories" "up" "all" \
d1/,

test15 \
"equals" "$ROOT/d1" \
"equals" "" \
'' '' \
"1" "symlinks and directories" "down" "all" \
d1/,d1/d11/,d1/d12/,

test16 \
"equals" "$ROOT/d1/d11" \
"equals" "" \
'' '' \
"1" "symlinks and directories" "up" "all" \
d1/,d1/d11/,

test17 \
"equals" "$ROOT/d1/d11" \
"equals" "" \
'' '' \
"-1" "symlinks and directories" "down" "all" \
d1/d11/,d1/d11/d111/,

# support for empty string as a pattern in 'filename' entity
test18 \
"equals" "$ROOT/d2" \
"pattern match" "EMPTY_STRING" \
'' '' \
"-1" "symlinks and directories" "none" "all" \
d2/f21,

# don't return nonexistent filepath
test19 \
'' '' \
'' '' \
"equals" "/nonexistent" \
"-1" "symlinks and directories" "none" "all" \
# intentionally left blank

# test for a regression caused by the errno check that follows calls to fts_open()
test20 \
"equals" "$ROOT/d1/d11/d111" \
"equals" "f1111" \
'' '' \
"-1" "directories" "down" "local" \
d1/d11/d111/f1111,

EOF

rm -rf $tmpdir
