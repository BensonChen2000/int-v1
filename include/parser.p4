#ifndef __PARSER__
#define __PARSER__

#include "defines.p4"

parser IntParser(packet_in packet,
                out headers_t hdr,
                inout local_metadata_t local_metadata,
                inout standard_metadata_t standard_metadata) {

    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            TYPE_TCP : parse_tcp;
            TYPE_UDP : parse_udp;
            default: accept;
        }
    }

    state parse_tcp {
        packet.extract(hdr.tcp);
        local_metadata.l4_src_port = hdr.tcp.src_port;
        local_metadata.l4_dst_port = hdr.tcp.dst_port;
        transition select(hdr.ipv4.dscp) {
            DSCP_INT &&& DSCP_MASK: parse_intl4_shim;
            default: accept;
        }
    }

    state parse_udp {
        packet.extract(hdr.udp);
        local_metadata.l4_src_port = hdr.udp.src_port;
        local_metadata.l4_dst_port = hdr.udp.dst_port;
        // transition select(hdr.ipv4.dscp) {
        //     DSCP_INT &&& DSCP_MASK: parse_intl4_shim;
        //     default: accept;
        // }
        transition accept;
    }

    state parse_intl4_shim {
        packet.extract(hdr.int_shim);
        local_metadata.int_meta.int_shim_len = hdr.int_shim.len;
        transition parse_int_header;
    }

    state parse_int_header {
        packet.extract(hdr.int_header);
        // transition parse_int_data;
        transition accept;
    }

    // state parse_int_data {
    //     // Parse INT metadata stack
    //     packet.extract(hdr.int_data, ((bit<32>) (local_metadata.int_meta.intl4_shim_len - INT_HEADER_LEN_WORD)) << 5);
    //     transition accept;
    // }

}


#endif /* __PARSER__ */