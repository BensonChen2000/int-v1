#ifndef __HEADERS__
#define __HEADERS__

#include "defines.p4"

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/



/* bit<48> is just an unsigned integer that is exactly 48 bits wide.
 * P4_16 also has int<N> for 2's complement signed integers, and
 * varbit<N> for variable length header fields with a maximum size of
 * N bits. */

/* header types are required for all headers you want to parse in
 * received packets, or transmit in packets sent. */


header ethernet_t {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<6>  dscp;
    bit<2>  ecn;
    bit<16> len;
    bit<16> identification;
    bit<3>  flags;
    bit<13> frag_offset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
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

/*************************************************************************
*********************** INT v1.0  ***********************************
*************************************************************************/





/* INT shim header for TCP/UDP */
header int_shim_t {
    bit<8> int_type;
    bit<8> rsvd1;
    bit<8> len;
    bit<6> dscp;
    bit<2> rsvd2;
}

/* INT header */
header int_header_t {
    bit<4>  ver;
    bit<2>  rep;
    bit<1>  c;
    bit<1>  e;
    bit<1>  m;
    bit<7>  rsvd1;
    bit<3>  rsvd2;
    bit<5>  hop_metadata_len; /* the length of the metadata added by a single INT node (4-byte words) */
    bit<8>  remaining_hop_cnt;
    bit<4>  instruction_mask_0003; /* split the bits for lookup */
    bit<4>  instruction_mask_0407;
    bit<4>  instruction_mask_0811;
    bit<4>  instruction_mask_1215;
    bit<16> rsvd3;
}

/* INT metadata headers */
header int_switch_id_t {
    bit<32> switch_id;
}

header int_port_ids_t {
    bit<16> ingress_port_id;
    bit<16> egress_port_id;
}

header int_hop_latency_t {
    bit<32> hop_latency;
}

header int_q_occupancy_t {
    bit<8> q_id;
    bit<24> q_occupancy;
}

header int_ingress_tstamp_t {
    bit<32> ingress_tstamp;
}

header int_egress_tstamp_t {
    bit<32> egress_tstamp;
}

header int_level2_port_ids_t {
    bit<32> ingress_port_id;
    bit<32> egress_port_id;
}

header int_egress_port_tx_util_t {
    bit<32> egress_port_tx_util;
}

header int_data_t {
    // Maximum int metadata stack size in bits
    // (0x3F - 3) * 4 * 8 (excluding INT shim header and INT header)
    varbit<1920> data;
}

/* INT report headers */
header int_report_fixed_header_t {
    bit<4>  ver;
    bit<4>  len;
    bit<3>  nproto;
    bit<6>  rep_md_bits;
    bit<6>  rsvd;
    bit<1>  d;
    bit<1>  q;
    bit<1>  f;
    bit<6>  hw_id;
    bit<32> sw_id;
    bit<32> seq_no;
    bit<32> ingress_tstamp;
}



struct int_metadata_t {
    switch_id_t switch_id;
    bit<16> new_bytes;
    bit<8>  new_words;
    bool  source;
    bool  sink;
    bool transit;
    bit<8> int_shim_len;

    // record ingress_time stamp and port
    bit<48> ingress_tstamp;
    bit<16> ingress_port;

    // record which port the int report is sent to
    bit<16> sink_reporting_port;
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

struct local_metadata_t {
    bit<16>       l4_src_port;
    bit<16>       l4_dst_port;
    next_hop_id_t next_hop_id;
    bit<16>       selector;
    int_metadata_t int_meta;
    bool compute_checksum;
}

struct headers_t {

    /* Original packet headers */
    ethernet_t   ethernet;
    ipv4_t       ipv4;
    tcp_t        tcp;
    udp_t        udp;

    /* INT headers */
    int_shim_t                int_shim;
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

#endif /* __HEADERS__ */