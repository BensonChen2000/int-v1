#ifndef __INT_SINK__
#define __INT_SINK__

control Int_sink(inout headers_t hdr, inout local_metadata_t meta, inout standard_metadata_t standard_metadata) {

    action remove_sink_header() {
         // restore original headers
        hdr.ipv4.dscp = hdr.int_shim.dscp;
        bit<16> len_bytes = ((bit<16>)hdr.int_shim.len) << 2;
        hdr.ipv4.totalLen = hdr.ipv4.totalLen - len_bytes;
        if (hdr.udp.isValid()) {
            hdr.udp.len = hdr.udp.len - len_bytes;
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

        if (standard_metadata.instance_type == PKT_INSTANCE_TYPE_NORMAL && meta.int_metadata.remove_int == 1) {
            // remove INT headers from a frame
            remove_sink_header();
        }
        if (standard_metadata.instance_type == PKT_INSTANCE_TYPE_INGRESS_CLONE) {
            // prepare an INT report for the INT collector
            Int_report.apply(hdr, meta, standard_metadata);
        }
    }
}

#endif