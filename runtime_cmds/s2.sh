#!/bin/bash
SWITCH_NUM=2
# set the thrift port
THRIFT_PORT=$((9090 + SWITCH_NUM - 1))

# Set ingress port 1 as INT source
simple_switch_CLI --thrift-port $THRIFT_PORT <<< "table_add tb_set_sink int_set_sink 1 =>"
