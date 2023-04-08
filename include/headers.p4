#ifndef __HEADERS__
#define __HEADERS__

#include "int_headers.p4"

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

/* bit<48> is just an unsigned integer that is exactly 48 bits wide.
 * P4_16 also has int<N> for 2's complement signed integers, and
 * varbit<N> for variable length header fields with a maximum size of
 * N bits. */

/* header types are required for all headers you want to parse in
 * received packets, or transmit in packets sent. */


header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

header tcp_t {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4>  data_offset;
    bit<3>  res;
    bit<3>  ecn;
    bit<6>  ctrl;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

header udp_t {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> length_;
    bit<16> checksum;
}


/* "Metadata" is the term used for information about a packet, but
 * that might not be inside of the packet contents itself, e.g. a
 * bridge domain (BD) or VRF (Virtual Routing and Forwarding) id.
 * They can also contain copies of packet header fields if you wish,
 * which can be useful if they can be filled in from one of several
 * possible places in a packet, e.g. an outer IPv4 destination address
 * for non-IP-tunnel packets, or an inner IPv4 destination address for
 * IP tunnel packets.
 *
 * You can define as many or as few structs for metadata as you wish.
 * Some people like to have more than one struct so that metadata for
 * a forwarding feature can be grouped together, but separated from
 * unrelated metadata. */

/* The v1model.p4 and psa.p4 architectures require you to define one
 * type that contains instances of all headers you care about, which
 * will typically be a struct with one member for each header instance
 * that your parser code might parse.
 *
 * You must also define another type that contains all metadata fields
 * that you use in your program.  It is typically a struct type, and
 * may contain bit vector fields, nested structs, or any other types
 * you want.
 *
 * Instances of these two types are then passed as parameters to the
 * top level controls defined by the architectures.  For example, the
 * ingress parser takes a parameter that contains your header type as
 * an 'out' parameter, returning filled-in headers when parsing is
 * complete, whereas the ingress control block takes that same
 * parameter with direction 'inout', since it is initially filled in
 * by the parser, but the ingress control block is allowed to modify
 * the contents of the headers during packet processing.
 *
 * Note: If you ever want to parse an outer and an inner IPv4 header
 * from a packet, the struct containing headers that you define should
 * contain two members, both with type ipv4_t, perhaps with field
 * names like "outer_ipv4" and "inner_ipv4", but the names are
 * completely up to you.  Similarly the struct type names 'metadata'
 * and 'headers' below can be anything you want to name them. */

struct metadata {
    int_metadata_t       int_metadata;
    intl4_shim_t         int_shim;
    bit<16>              int_len_bytes;
}

struct headers {

    /* Original packet headers */
    ethernet_t   ethernet;
    ipv4_t       ipv4;

    /* INT headers */
    intl4_shim_t              int_shim;
    int_header_t              int_header;

    /* Local INT node metadata */
    int_egress_port_tx_util_t int_egress_port_tx_util;
    int_egress_tstamp_t       int_egress_tstamp;
    int_hop_latency_t         int_hop_latency;
    int_ingress_tstamp_t      int_ingress_tstamp;
    int_port_ids_t            int_port_ids;
    int_level2_port_ids_t     int_level2_port_ids;
    int_q_occupancy_t         int_q_occupancy;
    int_switch_id_t           int_switch_id;


    /* INT metadata of previous nodes */
    int_data_t                int_data;

    /* INT report headers */
    ethernet_t                report_ethernet;
    ipv4_t                    report_ipv4;
    udp_t                     report_udp;
    int_report_fixed_header_t report_fixed_header;
}

#endif