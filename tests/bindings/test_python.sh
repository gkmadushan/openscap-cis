#!/usr/bin/env bash

# Author:
#   Martin Preisler <mpreisle@redhat.com>
#   Dominique Blaze <contact@d0m.tech>
#
#	All tests use import_handler.py as import manager
#	in order to ensure that the tested module come from the tested env 
#	and not from an existing local/other installation.
#	Read import_handler.py comments to learn more.

. $builddir/tests/test_common.sh

# Test Cases.

function test_python_import {
    bash $builddir/run python3 "${srcdir}/python/import_handler.py"
}

function run_pyfile () {
	echo "$builddir/run python3 ${srcdir}/python/$1"
	bash $builddir/run python3 "${srcdir}/python/$1"
}

# Testing.
test_init

# used by oval checks
echo "Hello World !" > /tmp/foo_python.txt

if [ -z ${CUSTOM_OSCAP+x} ] ; then
	# first test only the openscap_api module loading
    test_run "python_import" test_python_import
    
    test_run "python_benchmark_import_results" run_pyfile benchmark_import_results.py
    test_run "python_oval_eval" run_pyfile oval_eval.py
    test_run "python_introspection_features" run_pyfile introspection_features.py
    test_run "python_xccdf_policy" run_pyfile xccdf_policy.py
    test_run "python_xccdf_evaluation" run_pyfile xccdf_evaluation.py
    test_run "python_xccdf_single_evaluation" run_pyfile xccdf_single_evaluation.py
fi

rm /tmp/foo_python.txt

test_exit
