/*
 * standard #include in just about every P4 program.  You can see its
 * (short) contents here:
 *
 * https://github.com/p4lang/p4c/blob/master/p4include/core.p4
 */
#include <core.p4>

/* v1model.p4 defines one P4_16 'architecture', i.e. is there an
 * ingress and an egress pipeline, or just one?  Where is parsing
 * done, and how many parsers does the target device have?  etc.
 *
 * You can see its contents here:
 * https://github.com/p4lang/p4c/blob/master/p4include/v1model.p4
 *
 * The standard P4_16 architecture called PSA (Portable Switch
 * Architecture) version 1.1 was published on November 22, 2018 here:
 *
 * https://p4.org/specs/
 *
 * P4_16 programs written for the PSA architecture should include the
 * file psa.p4 instead of v1model.p4, and several parts of the program
 * after that would use different extern objects and functions than
 * this example program shows.
 *
 * In the v1model.p4 architecture, ingress consists of these things,
 * programmed in P4.  Each P4 program can name these things as they
 * choose.  The name used in this program for that piece is given in
 * parentheses:
 *
 * + a parser (parserImpl)
 * + a specialized control block intended for verifying checksums
 *   in received headers (verifyChecksum)
 * + ingress match-action pipeline (ingressImpl)
 *
 * Then there is a packet replication engine and packet buffer, which
 * are not P4-programmable.
 *
 * Egress consists of these things, programmed in P4:
 *
 * + egress match-action pipeline (egressImpl)
 * + a specialized control block intended for computing checksums in
 *   transmitted headers (updateChecksum)
 * + deparser (also called rewrite in some networking chips, deparserImpl)
 */
#include <v1model.p4>

/* The notation <decimal number>w<something> means that the
* <something> represents a constant unsigned integer value.  The
* <decimal number> is the width of that number in bits.  '0x' is
* taken from C's method of specifying that what follows is
* hexadecimal.  You can also do decimal (no special prefix),
* binary (prefix 0b), or octal (0o), but note that octal is _not_
* specified as it is in C.
*
* You can also have <decimal number>s<something> where the 's'
* indicates the number is a 2's complement signed integer value.
*
* For just about every integer constant in your P4 program, it is
* usually perfectly fine to leave out the '<number>w' width
* specification, because the compiler infers the width it should
* be from the context, e.g. for the assignment below, if you
* leave off the '16w' the compiler infers that 0x0800 should be
* 16 bits wide because it is being assigned as the value of a
* bit<16> constant.
*/
const bit<16> TYPE_IPV4 = 0x800;

#include "include/headers.p4"
#include "include/fwd.p4"

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

/* The ingress parser here is pretty simple.  It assumes every packet
 * starts with a 14-byte Ethernet header, and if the ether type is
 * 0x0800, it proceeds to parse the 20-byte mandatory part of an IPv4
 * header, ignoring whether IPv4 options might be present. */


parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {
    
    /* A parser is specified as a finite state machine, with a 'state'
     * definition for each state of the FSM.  There must be a state
     * named 'start', which is the starting state.  'transition'
     * statements indicate what the next state will be.  There are
     * special states 'accept' and 'reject' indicating that parsing is
     * complete, where 'accept' indicates no error during parsing, and
     * 'reject' indicates some kind of parsing error. */
    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        /* extract() is the name of a method defined for packets,
         * declared in core.p4 #include'd above.  The parser's
         * execution model starts with a 'pointer' to the beginning of
         * the received packet.  Whenever you call the extract()
         * method, it takes the size of the argument header in bits B,
         * copies the next B bits from the packet into that header
         * (making that header valid), and advances the pointer into
         * the packet by B bits.  Some P4 targets, such as the
         * behavioral model called BMv2 simple_switch, restrict the
         * headers and pointer to be a multiple of 8 bits. */

        packet.extract(hdr.ethernet);
        /* The 'select' keyword introduces an expression that is like
         * a C 'switch' statement, except that the expression for each
         * of the cases must be a state name in the parser.  This
         * makes convenient the handling of many possible Ethernet
         * types or IPv4 protocol values. */
        transition select(hdr.ethernet.etherType) {
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition accept;
    }

}

/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {   
    apply {  }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    
    
    apply {
        FwdIngress.apply(hdr, meta, standard_metadata);
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply {  }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

/* In the v1model.p4 architecture this program is written for, there
 * is a 'slot' for a control block that performs checksums on the
 * already-parsed packet, and can modify metadata fields with the
 * results of those checks, e.g. to set error flags, increment error
 * counts, drop the packet, etc. */
control MyComputeChecksum(inout headers  hdr, inout metadata meta) {
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
                    hdr.ipv4.diffserv,
                    hdr.ipv4.totalLen,
                    hdr.ipv4.identification,
                    hdr.ipv4.flags,
                    hdr.ipv4.fragOffset,
                    hdr.ipv4.ttl,
                    hdr.ipv4.protocol,
                    hdr.ipv4.srcAddr,
                    hdr.ipv4.dstAddr 
                },
                hdr.ipv4.hdrChecksum,
                HashAlgorithm.csum16);
    }
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

/* The deparser controls what headers are created for the outgoing
 * packet. */
control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        /* The emit() method takes a header.  If that header's hidden
         * 'valid' bit is true, then emit() appends the contents of
         * the header (which may have been modified in the ingress or
         * egress pipelines above) into the outgoing packet.
         *
         * If that header's hidden 'valid' bit is false, emit() does
         * nothing. */
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);

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

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

/* This is a "package instantiation".  There must be at least one
 * named "main" in any complete P4_16 program.  It is what specifies
 * which pieces to plug into which "slot" in the target
 * architecture. */
V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
