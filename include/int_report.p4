register<bit<32>> (1) report_seq_num_register;

control Int_report(inout headers_t hdr, inout local_metadata_t meta, inout standard_metadata_t standard_metadata) {

    bit<32> seq_num_value = 0;

    // INT Report structure
    // [Eth][IP][UDP][INT RAPORT HDR][ETH][IP][UDP/TCP][INT SHIM][INT HEADER][INT DATA]

    action send_report(bit<48> dp_mac, bit<32> dp_ip, bit<48> collector_mac, bit<32> collector_ip, bit<16> collector_port) {

        // Ethernet **********************************************************
        hdr.report_ethernet.setValid();
        hdr.report_ethernet.dst_addr = collector_mac;
        hdr.report_ethernet.src_addr = dp_mac;
        hdr.report_ethernet.etherType = 0x0800;

        // IPv4 **************************************************************
        hdr.report_ipv4.setValid();
        hdr.report_ipv4.version = 4;
        hdr.report_ipv4.ihl = 5;
        hdr.report_ipv4.dscp = 0;
        hdr.report_ipv4.ecn = 0;

        // [IP header = 20][UDP header = 8][INT REPORT HEADER][ETH = 14][IPV4 len]
        hdr.report_ipv4.len = 20 + 8 + + ((bit<16>)(INT_REPORT_HEADER_LEN_WORDS)<<2) +  14 + hdr.ipv4.len;
            
        // add size of original tcp/udp header
        if (hdr.tcp.isValid()) {
            hdr.report_ipv4.len = hdr.report_ipv4.len
                + (((bit<16>)hdr.tcp.data_offset) << 2);

        } else {
            hdr.report_ipv4.len = hdr.report_ipv4.len + 8;
        }

        hdr.report_ipv4.identification = 0;
        hdr.report_ipv4.flags = 0;
        hdr.report_ipv4.frag_offset = 0;
        hdr.report_ipv4.ttl = 64;
        hdr.report_ipv4.protocol = 17; // UDP
        hdr.report_ipv4.src_addr = dp_ip;
        hdr.report_ipv4.dst_addr = collector_ip;

        // UDP ***************************************************************
        hdr.report_udp.setValid();
        hdr.report_udp.src_port = 0;
        hdr.report_udp.dst_port = collector_port;
        hdr.report_udp.length_ = hdr.report_ipv4.len - 20;
        // INT report fixed header ************************************************/
        // INT report version 1.0
        hdr.report_fixed_header.setValid();
        hdr.report_fixed_header.ver = INT_REPORT_VERSION;
        hdr.report_fixed_header.len = INT_REPORT_HEADER_LEN_WORDS;

        hdr.report_fixed_header.nproto = 0; // 0 for Ethernet
        hdr.report_fixed_header.rep_md_bits = 0;
        hdr.report_fixed_header.rsvd = 0;
        hdr.report_fixed_header.d = 0;
        hdr.report_fixed_header.q = 0;
        // f - indicates that report is for tracked flow, INT data is present
        hdr.report_fixed_header.f = 1;
        // hw_id - specific to the switch, e.g. id of linecard
        hdr.report_fixed_header.hw_id = 0;
        hdr.report_fixed_header.sw_id = meta.int_meta.switch_id;
        report_seq_num_register.read(seq_num_value, 0);
        hdr.report_fixed_header.seq_no = seq_num_value;
        report_seq_num_register.write(0, seq_num_value + 1);

        hdr.report_fixed_header.ingress_tstamp = (bit<32>)standard_metadata.ingress_global_timestamp;

        // Original packet headers, INT shim and INT data come after report header.
        // drop all data besides int report and report eth header
        // truncate((bit<32>)hdr.report_ipv4.len + 14);
        }
        table tb_int_reporting {
            actions = {
                send_report;
            }
            // size = 512;
        }

    apply {
        tb_int_reporting.apply();
    }
}