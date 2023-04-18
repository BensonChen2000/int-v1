#include <core.p4>
#include <v1model.p4>

#define DEBUG

#include "include/defines.p4"
#include "include/headers.p4"
#include "include/fwd.p4"
#include "include/parser.p4"
#include "include/int_source.p4"
#include "include/int_transit.p4"

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

/* INT parser defined in "include/parser.p4" */




/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers_t hdr, inout local_metadata_t local_metadata) {   
    apply {  }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers_t hdr,
                  inout local_metadata_t local_metadata,
                  inout standard_metadata_t standard_metadata) {
    
    
    apply {
        FwdIngress.apply(hdr, local_metadata, standard_metadata);
        process_int_source_sink.apply(hdr, local_metadata, standard_metadata);

        // record ingress port and ingress timestamp
        local_metadata.int_meta.ingress_tstamp = standard_metadata.ingress_global_timestamp;
        local_metadata.int_meta.ingress_port = (bit<16>)standard_metadata.ingress_port;

        if (local_metadata.int_meta.source == true) {
            process_int_source.apply(hdr, local_metadata, standard_metadata);
        }
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers_t hdr,
                 inout local_metadata_t local_metadata,
                 inout standard_metadata_t standard_metadata) {

    apply { 
        Int_transit.apply(hdr, local_metadata, standard_metadata);
    }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

/* In the v1model.p4 architecture this program is written for, there
 * is a 'slot' for a control block that performs checksums on the
 * already-parsed packet, and can modify metadata fields with the
 * results of those checks, e.g. to set error flags, increment error
 * counts, drop the packet, etc. */
control MyComputeChecksum(inout headers_t  hdr, inout local_metadata_t local_metadata) {
    apply {
        /* The verify_checksum() extern function is declared in
         * v1model.p4.  Its behavior is implementated in the target,
         * e.g. the BMv2 software switch.
         *
         * It can takes a single header field by itself as the second
         * parameter, but more commonly you want to use a list of
         * header fields inside curly braces { }.  They are
         * concatenated together and the checksum calculation is
         * performed over all of them.
         *
         * The computed checksum is compared against the received
         * checksum in the field hdr.ipv4.hdrChecksum, given as the
         * 3rd argument.
         *
         * The verify_checksum() primitive can perform multiple kinds
         * of hash or checksum calculations.  The 4th argument
         * specifies that we want 'HashAlgorithm.csum16', which is the
         * Internet checksum.
         *
         * The first argument is a Boolean true/false value.  The
         * entire verify_checksum() call does nothing if that value is
         * false.  In this case it is true only when the parsed packet
         * had an IPv4 header, which is true exactly when
         * hdr.ipv4.isValid() is true, and if that IPv4 header has a
         * header length 'ihl' of 5 32-bit words.
         *
         * In September 2018, the simple_switch process in the
         * p4lang/behavioral-model Github repository was enhanced so
         * that it initializes the value of stdmeta.checksum_error to
         * 0 for all received packets, and if any call to
         * verify_checksum() with a first parameter of true finds an
         * incorrect checksum value, it assigns 1 to the
         * checksum_error field.  This field can be read in your
         * ingress control block code, e.g. using it in an 'if'
         * condition to choose to drop the packet.  This example
         * program does not demonstrate that.
         */
        update_checksum(
            hdr.ipv4.isValid(),
                { 
                    hdr.ipv4.version,
                    hdr.ipv4.ihl,
                    hdr.ipv4.dscp,
                    hdr.ipv4.ecn,
                    hdr.ipv4.len,
                    hdr.ipv4.identification,
                    hdr.ipv4.flags,
                    hdr.ipv4.frag_offset,
                    hdr.ipv4.ttl,
                    hdr.ipv4.protocol,
                    hdr.ipv4.src_addr,
                    hdr.ipv4.dst_addr 
                },
                hdr.ipv4.hdr_checksum,
                HashAlgorithm.csum16);
    }
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

/* INT deparser defined in "include/parser.p4"

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

/* This is a "package instantiation".  There must be at least one
 * named "main" in any complete P4_16 program.  It is what specifies
 * which pieces to plug into which "slot" in the target
 * architecture. */
V1Switch(
int_parser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
int_deparser()
) main;
