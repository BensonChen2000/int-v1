#ifndef __INT_SOURCE__
#define __INT_SOURCE__

#include "defines.p4"

// Insert INT header to the packet
control process_int_source (
    inout headers_t hdr,
    inout local_metadata_t local_metadata,
    inout standard_metadata_t standard_metadata) {

    

    /* In P4, direct counters are used to track packet and byte counts for a specific flow, 
     * while indirect counters are used to track packet and byte counts across all flows. 
     * Direct counters can be accessed directly from the control plane, while indirect counters 
     * require a lookup to retrieve the counter value.
    */
    direct_counter(CounterType.packets_and_bytes) counter_int_source;

    action int_source(bit<5> hop_metadata_len, bit<8> remaining_hop_cnt, bit<4> ins_mask0003, bit<4> ins_mask0407) {
        // insert INT shim header
        hdr.int_shim.setValid();
        // int_type: Hop-by-hop type (1) , destination type (2)
        hdr.int_shim.int_type = 1;
        hdr.int_shim.len = INT_HEADER_LEN_WORD;
        hdr.int_shim.dscp = hdr.ipv4.dscp;

        // insert INT header
        hdr.int_header.setValid();
        hdr.int_header.ver = 0;
        hdr.int_header.rep = 0;
        hdr.int_header.c = 0;
        hdr.int_header.e = 0;
        hdr.int_header.m = 0;
        hdr.int_header.rsvd1 = 0;
        hdr.int_header.rsvd2 = 0;
        hdr.int_header.hop_metadata_len = hop_metadata_len;
        hdr.int_header.remaining_hop_cnt = remaining_hop_cnt;
        hdr.int_header.instruction_mask_0003 = ins_mask0003;
        hdr.int_header.instruction_mask_0407 = ins_mask0407;
        hdr.int_header.instruction_mask_0811 = 0; // not supported
        hdr.int_header.instruction_mask_1215 = 0; // not supported

        // add the header len (3 words) to total len
        hdr.ipv4.len = hdr.ipv4.len + INT_HEADER_SIZE + INT_SHIM_HEADER_SIZE;
        hdr.udp.length_ = hdr.udp.length_ + INT_HEADER_SIZE + INT_SHIM_HEADER_SIZE;
    }

    /* hop_metadata_len - how INT metadata words are added by a single INT node */
    action int_source_dscp(bit<5> hop_metadata_len, bit<8> remaining_hop_cnt, bit<4> ins_mask0003, bit<4> ins_mask0407) {
        int_source(hop_metadata_len, remaining_hop_cnt, ins_mask0003, ins_mask0407);
        hdr.ipv4.dscp = DSCP_INT;

        /*
        * This line increments the direct counter for packets and bytes
        * associated with the INT source. This method is typically called inside an action of a table, which is
        * executed when a matching entry in the table is found. In the given code, the int_source_dscp action 
        * calls this method after setting the DSCP value for the IPv4 header and before returning. This helps 
        * track the number of packets that have been processed by the int_source_dscp action.
        */
        counter_int_source.count();
    }

    action nop() { }

    table tb_int_source {
        key = {
            hdr.ipv4.src_addr: ternary;
            hdr.ipv4.dst_addr: ternary;
            local_metadata.l4_src_port: ternary;
            local_metadata.l4_dst_port: ternary;
        }
        actions = {
            int_source_dscp;
            @defaultonly nop();
        }
        counters = counter_int_source;
        const default_action = nop();
    }

    apply {
        tb_int_source.apply();
    }
}

/* Sets the sink and source fields in the local_metadata of the incoming packets.
 * It uses two direct counters to track the number of packets and bytes for which the 
 * local_metadata.int_meta.source and local_metadata.int_meta.sink fields are set to true. 
 * The control block applies two tables, tb_set_source and tb_set_sink, to respectively 
 * identify the ingress and egress ports of the packet and set the metadata fields accordingly. 
 * It also increments the counters for each identified source and sink packet.
 */
control process_int_source_sink (
    inout headers_t hdr,
    inout local_metadata_t local_metadata,
    inout standard_metadata_t standard_metadata) {

    direct_counter(CounterType.packets_and_bytes) counter_set_source;
    direct_counter(CounterType.packets_and_bytes) counter_set_sink;
    direct_counter(CounterType.packets_and_bytes) counter_set_transit;

    action nop() { }

    action int_set_source () {
        local_metadata.int_meta.source = true;
        counter_set_source.count();
    }

    action int_set_sink () {
        local_metadata.int_meta.sink = true;
        counter_set_sink.count();
    }

    action int_set_transit () {

        local_metadata.int_meta.transit = true;
        counter_set_transit.count();
    }

    table tb_set_source {
        key = {
            standard_metadata.ingress_port: exact;
        }
        actions = {
            int_set_source;
            @defaultonly nop();
        }
        counters = counter_set_source;
        const default_action = nop();
        size = MAX_PORTS;
    }
    table tb_set_sink {
        key = {
            standard_metadata.egress_spec: exact;
        }
        actions = {
            int_set_sink;
            @defaultonly nop();
        }
        counters = counter_set_sink;
        const default_action = nop();
        size = MAX_PORTS;
    }

    table tb_set_transit {
        key = {
            standard_metadata.ingress_port: exact;
        }
        actions = {
            int_set_transit;
            @defaultonly nop();
        }
        counters = counter_set_transit;
        const default_action = nop();
        size = MAX_PORTS;
    }

    apply {
        tb_set_source.apply();
        tb_set_sink.apply();
        tb_set_transit.apply();
    }
}
#endif  /* __INT_SOURCE__ */