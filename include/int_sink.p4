#ifndef __INT_SINK__
#define __INT_SINK__

control Int_sink(inout headers_t hdr, inout local_metadata_t meta, inout standard_metadata_t standard_metadata) {

    action remove_sink_header() {
         // restore original headers
        hdr.ipv4.dscp = hdr.int_shim.dscp;
        bit<16> len_bytes = ((bit<16>)hdr.int_shim.len) << 2;
        hdr.ipv4.len = hdr.ipv4.len - len_bytes;
        if (hdr.udp.isValid()) {
            hdr.udp.length_ = hdr.udp.length_ - len_bytes;
        }

        // remove INT data added in INT sink
        hdr.int_switch_id.setInvalid();
        hdr.int_port_ids.setInvalid();
        hdr.int_ingress_tstamp.setInvalid();
        hdr.int_egress_tstamp.setInvalid();
        hdr.int_hop_latency.setInvalid();
        hdr.int_level2_port_ids.setInvalid();
        hdr.int_q_occupancy.setInvalid();
        hdr.int_egress_port_tx_util.setInvalid();
        
        // remove int data
        hdr.int_shim.setInvalid();
        hdr.int_header.setInvalid();
    }

    apply {

        // INT sink must process only INT packets
        if (!hdr.int_header.isValid())
            return;

        remove_sink_header();
    }
}

#endif