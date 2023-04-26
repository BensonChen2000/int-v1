#!/bin/bash
SWITCH_NUM=1
# set the thrift port
THRIFT_PORT=$((9090 + SWITCH_NUM - 1))

# Set ingress port 1 as INT source
simple_switch_CLI --thrift-port $THRIFT_PORT <<< "table_add tb_set_source int_set_source 1 =>"

# To match packets in the range of 10.0.1.1 to 10.0.1.255, use a 32-bit mask of 0xFFFFFF00. 
# This bitmask will match the first 24 bits of the IP address, which corresponds to the network address of 10.0.1.0, 
# and will ignore the last 8 bits, which correspond to the host address. 
# Therefore, any packet with an IP address in the range of 10.0.1.1 to 10.0.1.255 will match this bitmask.
# A bitmask of 0xFFFFFFFF means that all bits in the corresponding field should be used during the matching process.
# This bitmask will match any value in that field, which means that no wildcard match is performed. In other words, the # exact value in that field must be matched for a successful match.

# Port 8001 corresponds to the hexadecimal number 0x1F41, and port 8002 corresponds to 0x1F42. Bitmask (0x0000) can be # used for a wildcard match.
# A bitmask of 0x0000 means that all the bits in the corresponding field should be ignored during the matching process. 
# In other words, any value in that field will be considered as a match.

# The last value of 0 in the table_add command sets the priority. This value seems to be mandatory when using ternary match.
simple_switch_CLI --thrift-port $THRIFT_PORT <<< "table_add tb_int_source int_source_dscp 10.0.1.1&&&0xFFFFFF00 10.0.2.2&&&0xFFFFFF00 0x1F41&&&0x0000 0x1F41&&&0x0000 => 8 4 0xF 0xF 0"

simple_switch_CLI --thrift-port $THRIFT_PORT <<< "table_add tb_int_transit configure_transit => 1"
simple_switch_CLI --thrift-port $THRIFT_PORT <<< "table_add tb_set_transit int_set_transit 1 =>"
