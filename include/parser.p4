#ifndef __PARSER__
#define __PARSER__

#include "defines.p4"

parser int_parser(packet_in packet,
                out headers_t hdr,
                inout local_metadata_t local_metadata,
                inout standard_metadata_t standard_metadata) {

    state start {
        transition parse_ethernet;
    }

    /* The ingress parser here is pretty simple.  It assumes every packet
    * starts with a 14-byte Ethernet header, and if the ether type is
    * 0x0800, it proceeds to parse the 20-byte mandatory part of an IPv4
    * header, ignoring whether IPv4 options might be present. */
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
            /* &&& is a mask operator in p4_16 */
            DSCP_INT &&& DSCP_MASK: parse_int_shim;
            default: accept;
        }
    }

    state parse_udp {
        packet.extract(hdr.udp);
        local_metadata.l4_src_port = hdr.udp.src_port;
        local_metadata.l4_dst_port = hdr.udp.dst_port;
        transition select(hdr.ipv4.dscp) {
            DSCP_INT &&& DSCP_MASK: parse_int_shim;
            default: accept;
        }
    }

    state parse_int_shim {
        packet.extract(hdr.int_shim);
        local_metadata.int_meta.int_shim_len = hdr.int_shim.len;
        transition parse_int_header;
    }

    state parse_int_header {
        packet.extract(hdr.int_header);
        transition parse_int_data;
    }

    state parse_int_data {
        // Parse INT metadata stack
        packet.extract(hdr.int_data, ((bit<32>) (local_metadata.int_meta.int_shim_len - INT_HEADER_LEN_WORD)) << 5);
        transition accept;
    }

}

control int_deparser(
            packet_out packet,
            in headers_t hdr) {

    apply {

        /* INT report headers */
        packet.emit(hdr.report_ethernet);
        packet.emit(hdr.report_ipv4);
        packet.emit(hdr.report_udp);
        packet.emit(hdr.report_fixed_header);

        /* Original packet headers */
        /* The emit() method takes a header.  If that header's hidden
         * 'valid' bit is true, then emit() appends the contents of
         * the header (which may have been modified in the ingress or
         * egress pipelines above) into the outgoing packet.
         *
         * If that header's hidden 'valid' bit is false, emit() does
         * nothing. */
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.tcp);
        packet.emit(hdr.udp);

        /* INT headers */
        packet.emit(hdr.int_shim);
        packet.emit(hdr.int_header);

        /* Local INT node metadata */
        packet.emit(hdr.int_switch_id);
        packet.emit(hdr.int_port_ids);
        packet.emit(hdr.int_hop_latency);
        packet.emit(hdr.int_q_occupancy);
        packet.emit(hdr.int_ingress_tstamp);
        packet.emit(hdr.int_egress_tstamp);
        packet.emit(hdr.int_level2_port_ids);
        packet.emit(hdr.int_egress_port_tx_util);

        /* INT data from previous hops */
        packet.emit(hdr.int_data);

        /* This ends the deparser definition.
         *
         * Note that for each packet, the target device records where
         * parsing ended, and it considers every byte of data in the
         * packet after the last parsed header as 'payload'.  For
         * _this_ P4 program, even a TCP header immediately following
         * the IPv4 header is considered part of the payload.  For a
         * different P4 program that parsed the TCP header, the TCP
         * header would not be considered part of the payload.
         * 
         * Whatever is considered as payload for this particular P4
         * program for this packet, that payload is appended after the
         * end of whatever sequence of bytes that the deparser
         * creates. */
    }
}


#endif /* __PARSER__ */