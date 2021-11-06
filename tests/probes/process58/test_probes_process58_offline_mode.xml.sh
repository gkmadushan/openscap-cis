#!/usr/bin/env bash

VALID=$1

cat <<EOF
<?xml version="1.0"?>
<oval_definitions xmlns:oval-def="http://oval.mitre.org/XMLSchema/oval-definitions-5" xmlns:oval="http://oval.mitre.org/XMLSchema/oval-common-5" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:ind-def="http://oval.mitre.org/XMLSchema/oval-definitions-5#independent" xmlns:unix-def="http://oval.mitre.org/XMLSchema/oval-definitions-5#unix" xmlns:lin-def="http://oval.mitre.org/XMLSchema/oval-definitions-5#linux" xmlns="http://oval.mitre.org/XMLSchema/oval-definitions-5" xsi:schemaLocation="http://oval.mitre.org/XMLSchema/oval-definitions-5#unix unix-definitions-schema.xsd http://oval.mitre.org/XMLSchema/oval-definitions-5#independent independent-definitions-schema.xsd http://oval.mitre.org/XMLSchema/oval-definitions-5#linux linux-definitions-schema.xsd http://oval.mitre.org/XMLSchema/oval-definitions-5 oval-definitions-schema.xsd http://oval.mitre.org/XMLSchema/oval-common-5 oval-common-schema.xsd">

  <generator>
    <oval:product_name>process58</oval:product_name>
    <oval:product_version>1.0</oval:product_version>
    <oval:schema_version>5.11</oval:schema_version>
    <oval:timestamp>2011-07-13T00:00:00-00:00</oval:timestamp>
  </generator>

  <definitions>

    <definition class="compliance" version="1" id="oval:1:def:1"> <!-- comment="${VALID}" -->
      <metadata>
        <title></title>
        <description></description>
      </metadata>
      <criteria>
        <criteria operator="AND">
          <criterion test_ref="oval:1:tst:1"/>
        </criteria>
      </criteria>
    </definition>

  </definitions>

  <tests>
    <process58_test version="1" id="oval:1:tst:1" check="at least one" comment="${VALID}" xmlns="http://oval.mitre.org/XMLSchema/oval-definitions-5#unix">
      <object object_ref="oval:1:obj:1"/>
      <state state_ref="oval:1:ste:1"/>
    </process58_test>
  </tests>

  <objects>
    <process58_object version="1" id="oval:1:obj:1" xmlns="http://oval.mitre.org/XMLSchema/oval-definitions-5#unix">
      <command_line operation="pattern match">.*</command_line>
      <pid datatype="int">1</pid>
    </process58_object>
  </objects>

  <states>
    <process58_state version="1" id="oval:1:ste:1" xmlns="http://oval.mitre.org/XMLSchema/oval-definitions-5#unix">
      <pid datatype="int">1</pid>
    </process58_state>
  </states>

</oval_definitions>
EOF