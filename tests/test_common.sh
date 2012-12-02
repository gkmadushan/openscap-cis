#!/usr/bin/env bash

# Copyright 2009 Red Hat Inc., Durham, North Carolina.
# All Rights Reserved.
#
# OpenScap Testing Helpers.
#
# Authors:
#      Ondrej Moris <omoris@redhat.com>

# Normalized path.
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin

export XPATH=$(cd $(dirname $BASH_SOURCE); pwd)/xpath.pl
[ -z "$builddir" ] || export OSCAP=$(cd $builddir/utils/.libs; pwd)/oscap
export XMLDIFF=$(cd $(dirname $BASH_SOURCE); pwd)/xmldiff.pl

# Overall test result.
result=0

# Logging file (stderr is redirected here).
log=test.log

# Set-up testing environment.
function test_init {
    [ $# -eq 1 ] && log="$1"
    exec 2>$log
    echo ""
    echo "--------------------------------------------------"
}

# Execute test and report its results.
function test_run {    
    printf "+ %-40s" "$1";
    echo -e "TEST: $1" >&2; 
    shift
    ( exec 1>&2 ; eval "$@" )
    ret_val=$?
    if [ $ret_val -eq 0 ]; then 
	echo "[ PASS ]"; 
	echo -e "RESULT: PASSED\n" >&2
	return 0;
    elif [ $ret_val -eq 1 ]; then
        result=$[$result + $ret_val]
	echo "[ FAIL ]"; 
	echo -e "RESULT: FAILED\n" >&2
	return 1;
    elif [ $ret_val -eq 255 ]; then
	echo "[ SKIP ]"; 
	echo -e "RESULT: SKIPPED\n" >&2
	return 0; 
    else
        result=$[$result + $ret_val]
	echo "[ WARN ]"; 
	echo -e "RESULT: WARNING (unknown exist status $ret_val)\n" >&2
	return 1;
    fi    
}

# Clean-up testing environment.
function test_exit {
    echo "--------------------------------------------------"
    echo -e "See `pwd | sed 's|.*/\(tests/.*\)|\1|'`/${log}.\n"

    if [ $# -eq 1 ]
    then
        ( exec 1>&2 ; eval "$@" )
    fi

    [ $result -eq 0 ] && exit 0
    exit 1
}

# Check if requirements are in a path, use it as follows:
# require 'program' || return 255
function require {
    eval "which $1 > /dev/null 2>&1"    
    if [ ! $? -eq 0 ]; then	
        echo -e "No '$1' found in $PATH!\n" 
	return 1; # Test is not applicable.
    fi
    return 0
}

# Check if probe exists, use it as follows:
# probecheck 'probe' || return 255
function probecheck {
    if [ ! -f ${OVAL_PROBE_DIR}/probe_${1} ]; then
	echo -e "Probe $1 does not exist!\n"
	return 255; # Test is not applicable.
    fi
    return 0
}

function verify_results {

    require "grep" || return 255

    local ret_val=0;
    local TYPE="$1"
    local CONTENT="$2"
    local RESULTS="$3"
    local COUNT="$4" 
    local FULLTYPE="definition"
    
    [ $TYPE == "tst" ] && FULLTYPE="test"

    ID=1
    while [ $ID -le $COUNT ]; do
	
	CON_ITEM=`grep "id=\"oval:1:${TYPE}:${ID}\"" $CONTENT`
	RES_ITEM=`grep "${FULLTYPE}_id=\"oval:1:${TYPE}:${ID}\"" $RESULTS`	
	if (echo $RES_ITEM | grep "result=\"true\"") >/dev/null; then
	    RES="TRUE"
	elif (echo $RES_ITEM | grep "result=\"false\"" >/dev/null); then
	    RES="FALSE"
	else
	    RES="ERROR"
	fi
	
	if (echo $CON_ITEM | grep "comment=\"true\"" >/dev/null); then
	    CMT="TRUE"
	elif (echo $CON_ITEM | grep "comment=\"false\"" >/dev/null); then
	    CMT="FALSE"
	else
	    CMT="ERROR"
	fi
	
	if [ ! $RES = $CMT ]; then
	    echo "Result of oval:1:${TYPE}:${ID} should be ${CMT} and is ${RES}" 
	    ret_val=$[$ret_val + 1]
	fi
	
	ID=$[$ID+1]
    done

    return $([ $ret_val -eq 0 ])
}
