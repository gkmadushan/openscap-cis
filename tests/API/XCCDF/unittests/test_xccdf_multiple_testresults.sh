#!/usr/bin/env bash
. $builddir/tests/test_common.sh

set -e
set -o pipefail

name=$(basename $0 .sh)
result=$(make_temp_file /tmp ${name}.out)
stderr=$(make_temp_file /tmp ${name}.out)

cp $srcdir/${name}.xccdf.xml $result

echo "Stderr file = $stderr"
echo "Result and input file = $result"
tmpdir=$(dirname $result)

for i in {1..5}; do
	$OSCAP xccdf eval --results $result $result 2> $stderr
	[ -f $stderr ]
	grep "Skipping $tmpdir/non_existent\.oval\.xml file which is referenced from XCCDF content" $stderr
	:> $stderr

	$OSCAP xccdf validate $result
	assert_exists $i '//TestResult'
	assert_exists $i '//TestResult/rule-result/result[text()="notchecked"]'
	assert_exists $i '//TestResult/score'
	assert_exists 1 '//TestResult[@id="xccdf_org.open-scap_testresult_default-profile"]'
	assert_exists $i '//TestResult[contains(@id, "xccdf_org.open-scap_testresult_default-profile")]'
	let n=i-1 || true
	assert_exists $n '//TestResult[contains(@id, "xccdf_org.open-scap_testresult_default-profile00")]'
	for j in `seq 1 $n`; do
		# Compatibility for FreeBSD's seq
		if [ "$j" -gt "$n" ]; then
			break;
		fi
		assert_exists 1 '//TestResult[contains(@id, "xccdf_org.open-scap_testresult_default-profile00'$j'")]'
	done
done

rm $result
