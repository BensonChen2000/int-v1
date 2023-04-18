#ifndef __INT_TRANSIT__
#define __INT_TRANSIT__

#include "defines.p4"

control Int_transit(inout headers_t hdr, inout local_metadata_t meta, inout standard_metadata_t standard_metadata) {

        // Configure parameters of INT transit node:
        // switch_id which is used within INT node metadata
        // l3_mtu is curently not used but should allow to detect condition if adding new INT metadata will exceed allowed MTU packet size

        // checked
        action configure_transit(bit<32> switch_id) {
            meta.int_meta.switch_id = switch_id;
            meta.int_meta.new_bytes = 0;
            meta.int_meta.new_words = 0;
            meta.int_meta.transit = true;
        }

        // Table used to configure a switch as a INT transit
        // If INT transit configured then all packets with INT header will be precessed by INT transit logic
        
        // checked
        table tb_int_transit {

            actions = {

                configure_transit;
            }
        }

        // record switch id in deta data

        // checked 
        action int_set_header_0() {
            hdr.int_switch_id.setValid();
            hdr.int_switch_id.switch_id = meta.int_meta.switch_id;
        }

        // TODO : record ingress port during ingress then record in hear here

        // checked
        action int_set_header_1() {
            hdr.int_port_ids.setValid();

            // change later
            hdr.int_port_ids.ingress_port_id = 0;
            hdr.int_port_ids.egress_port_id = 0;

            // hdr.int_port_ids.ingress_port_id = (bit<16>)meta.int_meta.ingress_tstamp;
            // hdr.int_port_ids.egress_port_id = (bit<16>)standard_metadata.egress_port;
        }

        // TODO : uncomment the line to enable recording hop latency 

        // checked
        action int_set_header_2() {
            hdr.int_hop_latency.setValid();

            // change later
            hdr.int_hop_latency.hop_latency = 0;

            //  hdr.int_hop_latency.hop_latency = (bit<32>)(standard_metadata.egress_global_timestamp - standard_metadata.ingress_global_timestamp);
        }

        // TODO : uncomment q_occupancy to record q_occupancy

        // checked
        action int_set_header_3() {
            hdr.int_q_occupancy.setValid();
            hdr.int_q_occupancy.q_id = 0; // qid not defined in v1model

            // change later
            hdr.int_q_occupancy.q_occupancy = 0;
            // hdr.int_q_occupancy.q_occupancy = (bit<24>)standard_metadata.enq_qdepth;
        }

        // TODO : record ingress time stamp during ingress then save it to header

        // checked   
        action int_set_header_4() {
            hdr.int_ingress_tstamp.setValid();

            // change later
            hdr.int_ingress_tstamp.ingress_tstamp = 0;

            // bit<64> _timestamp = (bit<64>)meta.int_meta.ingress_tstamp;  
            // hdr.int_ingress_tstamp.ingress_tstamp = hdr.int_ingress_tstamp.ingress_tstamp + 1000 * _timestamp;
        }

        // TODO : uncomment when transit is working

        // checked
        action int_set_header_5() {
            hdr.int_egress_tstamp.setValid();

            // change later
            hdr.int_egress_tstamp.egress_tstamp = 0;

            // bit<64> _timestamp = (bit<64>)standard_metadata.egress_global_timestamp;
            // hdr.int_egress_tstamp.egress_tstamp = hdr.int_egress_tstamp.egress_tstamp + 1000 * _timestamp;
        }

        // checked
        action int_set_header_6() {
            hdr.int_level2_port_ids.setValid();
            // no such metadata in v1model
            hdr.int_level2_port_ids.ingress_port_id = 0;
            hdr.int_level2_port_ids.egress_port_id = 0;
        }

        // checked
        action int_set_header_7() {
            hdr.int_egress_port_tx_util.setValid();
            // no such metadata in v1model
            hdr.int_egress_port_tx_util.egress_port_tx_util = 0;
        }

        action add_1() {
            meta.int_meta.new_words = meta.int_meta.new_words + 1;
            meta.int_meta.new_bytes = meta.int_meta.new_bytes + 4;
        }

        action add_2() {
            meta.int_meta.new_words = meta.int_meta.new_words + 2;
            meta.int_meta.new_bytes = meta.int_meta.new_bytes + 8;
        }

        action add_3() {
            meta.int_meta.new_words = meta.int_meta.new_words + 3;
            meta.int_meta.new_bytes = meta.int_meta.new_bytes + 12;
        }

        action add_4() {
            meta.int_meta.new_words = meta.int_meta.new_words + 4;
            meta.int_meta.new_bytes = meta.int_meta.new_bytes + 16;
        }


        action add_5() {
            meta.int_meta.new_words = meta.int_meta.new_words + 5;
            meta.int_meta.new_bytes = meta.int_meta.new_bytes + 20;
        }

        action add_6() {
            meta.int_meta.new_words = meta.int_meta.new_words + 6;
            meta.int_meta.new_bytes = meta.int_meta.new_bytes + 24;
        }

        // hdr.int_switch_id     0
        // hdr.int_port_ids       1
        // hdr.int_hop_latency    2
        // hdr.int_q_occupancy    3
        // hdr.int_ingress_tstamp  4
        // hdr.int_egress_tstamp   5
        // hdr.int_level2_port_ids   6
        // hdr.int_egress_port_tx_util   7

        action int_set_header_0003_i0() {
            ;
        }
        action int_set_header_0003_i1() {
            int_set_header_3();
            add_1();
        }
        action int_set_header_0003_i2() {
            int_set_header_2();
            add_1();
        }
        action int_set_header_0003_i3() {
            int_set_header_5();
            int_set_header_2();
            add_3();
        }
        action int_set_header_0003_i4() {
            int_set_header_1();
            add_1();
        }
        action int_set_header_0003_i5() {
            int_set_header_3();
            int_set_header_1();
            add_2();
        }
        action int_set_header_0003_i6() {
            int_set_header_2();
            int_set_header_1();
            add_2();
        }
        action int_set_header_0003_i7() {
            int_set_header_3();
            int_set_header_2();
            int_set_header_1();
            add_3();
        }
        action int_set_header_0003_i8() {
            int_set_header_0();
            add_1();
        }
        action int_set_header_0003_i9() {
            int_set_header_3();
            int_set_header_0();
            add_2();
        }
        action int_set_header_0003_i10() {
            int_set_header_2();
            int_set_header_0();
            add_2();
        }
        action int_set_header_0003_i11() {
            int_set_header_3();
            int_set_header_2();
            int_set_header_0();
            add_3();
        }
        action int_set_header_0003_i12() {
            int_set_header_1();
            int_set_header_0();
            add_2();
        }
        action int_set_header_0003_i13() {
            int_set_header_3();
            int_set_header_1();
            int_set_header_0();
            add_3();
        }
        action int_set_header_0003_i14() {
            int_set_header_2();
            int_set_header_1();
            int_set_header_0();
            add_3();
        }
        action int_set_header_0003_i15() {
            int_set_header_3();
            int_set_header_2();
            int_set_header_1();
            int_set_header_0();
            add_4();
        }
        action int_set_header_0407_i0() {
            ;
        }

        action int_set_header_0407_i1() {
            int_set_header_7();
            add_1();
        }
        action int_set_header_0407_i2() {
            int_set_header_6();
            add_1();
        }
        action int_set_header_0407_i3() {
            int_set_header_7();
            int_set_header_6();
            add_2();

        }
        action int_set_header_0407_i4() {
            int_set_header_5();
            add_2();
        }
        action int_set_header_0407_i5() {
            int_set_header_7();
            int_set_header_5();
            add_3();
        }
        action int_set_header_0407_i6() {
            int_set_header_6();
            int_set_header_5();
            add_3();
        }
        action int_set_header_0407_i7() {
            int_set_header_7();
            int_set_header_6();
            int_set_header_5();
            add_4();
        }
        action int_set_header_0407_i8() {
            int_set_header_4();
            add_2();
        }
        action int_set_header_0407_i9() {
            int_set_header_7();
            int_set_header_4();
            add_3();
        }
        action int_set_header_0407_i10() {
            int_set_header_6();
            int_set_header_4();
            add_3();
        }
        action int_set_header_0407_i11() {
            int_set_header_7();
            int_set_header_6();
            int_set_header_4();
            add_4();
        }
        action int_set_header_0407_i12() {
            int_set_header_5();
            int_set_header_4();
            add_4();
        }
        action int_set_header_0407_i13() {
            int_set_header_7();
            int_set_header_5();
            int_set_header_4();
            add_5();
        }
        action int_set_header_0407_i14() {
            int_set_header_6();
            int_set_header_5();
            int_set_header_4();
            add_5();
        }
        action int_set_header_0407_i15() {
            int_set_header_7();
            int_set_header_6();
            int_set_header_5();
            int_set_header_4();
            add_6();
        }


        table tb_int_inst_0003 {
            actions = {
                int_set_header_0003_i0;
                int_set_header_0003_i1;
                int_set_header_0003_i2;
                int_set_header_0003_i3;
                int_set_header_0003_i4;
                int_set_header_0003_i5;
                int_set_header_0003_i6;
                int_set_header_0003_i7;
                int_set_header_0003_i8;
                int_set_header_0003_i9;
                int_set_header_0003_i10;
                int_set_header_0003_i11;
                int_set_header_0003_i12;
                int_set_header_0003_i13;
                int_set_header_0003_i14;
                int_set_header_0003_i15;
            }
            key = {
                hdr.int_header.instruction_mask_0003: ternary;
            }
            const entries = {
                0x0 &&& 0xF : int_set_header_0003_i0();
                // 0x1000 &&& 0xF000 : int_set_header_0003_i1();
                // 0x2000 &&& 0xF000 : int_set_header_0003_i2();
                // 0x3000 &&& 0xF000 : int_set_header_0003_i3();
                // 0x4000 &&& 0xF000 : int_set_header_0003_i4();
                // 0x5000 &&& 0xF000 : int_set_header_0003_i5();
                // 0x6000 &&& 0xF000 : int_set_header_0003_i6();
                // 0x7000 &&& 0xF000 : int_set_header_0003_i7();
                // 0x8000 &&& 0xF000 : int_set_header_0003_i8();
                // 0x9000 &&& 0xF000 : int_set_header_0003_i9();
                // 0xA000 &&& 0xF000 : int_set_header_0003_i10();
                // 0xB000 &&& 0xF000 : int_set_header_0003_i11();
                // 0xC000 &&& 0xF000 : int_set_header_0003_i12();
                // 0xD000 &&& 0xF000 : int_set_header_0003_i13();
                // 0xE000 &&& 0xF000 : int_set_header_0003_i14();
                // 0xF000 &&& 0xF000 : int_set_header_0003_i15();
            }
        }

        table tb_int_inst_0407 {
            actions = {
                int_set_header_0407_i0;
                int_set_header_0407_i1;
                int_set_header_0407_i2;
                int_set_header_0407_i3;
                int_set_header_0407_i4;
                int_set_header_0407_i5;
                int_set_header_0407_i6;
                int_set_header_0407_i7;
                int_set_header_0407_i8;
                int_set_header_0407_i9;
                int_set_header_0407_i10;
                int_set_header_0407_i11;
                int_set_header_0407_i12;
                int_set_header_0407_i13;
                int_set_header_0407_i14;
                int_set_header_0407_i15;
            }
            key = {
                hdr.int_header.instruction_mask_0407: ternary;
            }
            const entries = {
                0x0 &&& 0xF : int_set_header_0407_i0();
                // 0x0100 &&& 0x0F00 : int_set_header_0407_i1();
                // 0x0200 &&& 0x0F00 : int_set_header_0407_i2();
                // 0x0300 &&& 0x0F00 : int_set_header_0407_i3();
                // 0x0400 &&& 0x0F00 : int_set_header_0407_i4();
                // 0x0500 &&& 0x0F00 : int_set_header_0407_i5();
                // 0x0600 &&& 0x0F00 : int_set_header_0407_i6();
                // 0x0700 &&& 0x0F00 : int_set_header_0407_i7();
                // 0x0800 &&& 0x0F00 : int_set_header_0407_i8();
                // 0x0900 &&& 0x0F00 : int_set_header_0407_i9();
                // 0x0A00 &&& 0x0F00 : int_set_header_0407_i10();
                // 0x0B00 &&& 0x0F00 : int_set_header_0407_i11();
                // 0x0C00 &&& 0x0F00 : int_set_header_0407_i12();
                // 0x0D00 &&& 0x0F00 : int_set_header_0407_i13();
                // 0x0E00 &&& 0x0F00 : int_set_header_0407_i14();
                // 0x0F00 &&& 0x0F00 : int_set_header_0407_i15();
            }
        }

        // checked
        action int_hop_cnt_increment() {
            hdr.int_header.remaining_hop_cnt = hdr.int_header.remaining_hop_cnt - 1;
        }

        // checked
        action int_hop_exceeded() {
            hdr.int_header.e = 1w1;
        }

        // checked
        action int_update_ipv4_ac() {
            hdr.ipv4.len = hdr.ipv4.len + (bit<16>)meta.int_meta.new_bytes;
        }

        // checked
        action int_update_shim_ac() {
            hdr.int_shim.len = hdr.int_shim.len + (bit<8>)meta.int_meta.new_words;
        }

        // checked
        action int_update_udp_ac() {
            hdr.udp.length_ = hdr.udp.length_ + (bit<16>)meta.int_meta.new_bytes;
        }

        apply {	

            // INT transit must process only INT packets

            // checked
            if (!hdr.int_header.isValid())
                return;

            //TODO: check if hop-by-hop INT or destination INT

            // check if INT transit can add a new INT node metadata

            // checked
            if (hdr.int_header.remaining_hop_cnt == 0 || hdr.int_header.e == 1) {
                int_hop_exceeded();
                return;
            }

            int_hop_cnt_increment();

            // add INT node metadata headers based on INT instruction_mask
            tb_int_transit.apply();

            if (meta.int_meta.switch_id == 1) {
                meta.int_meta.switch_id = 1;
            } 

            tb_int_inst_0003.apply();
            tb_int_inst_0407.apply();

            //update length fields in IPv4, UDP and INT
            int_update_ipv4_ac();

            if (hdr.udp.isValid())
                int_update_udp_ac();

            if (hdr.int_shim.isValid()) 
                int_update_shim_ac();
        }
    }

#endif  /* __INT_TRANSIT__ */