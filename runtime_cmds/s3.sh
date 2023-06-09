#!/bin/bash
SWITCH_NUM=3
# set the thrift port
THRIFT_PORT=$((9090 + SWITCH_NUM - 1))

# Set ingress port 2 as INT transit
simple_switch_CLI --thrift-port $THRIFT_PORT <<< "table_add tb_int_transit configure_transit => 3"
simple_switch_CLI --thrift-port $THRIFT_PORT <<< "table_add tb_set_transit int_set_transit 1 =>"