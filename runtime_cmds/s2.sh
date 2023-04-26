#!/bin/bash
SWITCH_NUM=2
# set the thrift port
THRIFT_PORT=$((9090 + SWITCH_NUM - 1))

# Set ingress port 1 as INT sink 
simple_switch_CLI --thrift-port $THRIFT_PORT <<< "table_add tb_set_sink int_set_sink 1 =>"
simple_switch_CLI --thrift-port $THRIFT_PORT <<< "table_add tb_configure_sink configure_sink 1 => 3"

# add mirroring session, from session id 1 to port 4
simple_switch_CLI --thrift-port $THRIFT_PORT <<< "mirroring_add 1 3"

simple_switch_CLI --thrift-port $THRIFT_PORT <<< "table_add tb_int_reporting send_report => 08:00:00:00:02:22  10.0.2.2  08:00:00:00:04:00  10.0.4.4  8002"

