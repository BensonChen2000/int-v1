#ifndef __INT_HEADERS__
#define __INT_HEADERS__

/*************************************************************************
*********************** INT v1.0  ***********************************
*************************************************************************/

/* indicate INT by DSCP value */
const bit<6> DSCP_INT = 0x17;
const bit<6> DSCP_MASK = 0x3F;

const bit<8> INT_HEADER_LEN_WORD = 3;
const bit<16> INT_HEADER_SIZE = 8;
const bit<16> INT_SHIM_HEADER_SIZE = 4;

typedef bit<32> switch_id_t;

/* INT shim header for TCP/UDP */
header intl4_shim_t {
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
    bit<8> intl4_shim_len;
}




#endif /* __INT__HEADERS__ */