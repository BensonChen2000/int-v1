#ifndef __DEFINES__
#define __DEFINES__

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
const bit<8> TYPE_TCP = 0x06; // Value for TCP protocol in IP header
const bit<8> TYPE_UDP = 0x11; // Value for UDP protocol in IP header

/* indicate INT by DSCP value 
 * 0x17 is 23 in decimal 
 */
const bit<6> DSCP_INT = 0x17;
/* Masking is done by setting all the bits except the one(s) we want to 0. 
 * 0x3F in binary is 00111111 */
const bit<6> DSCP_MASK = 0x3F;

const bit<8> INT_HEADER_LEN_WORD = 3;
const bit<16> INT_HEADER_SIZE = 8;
const bit<16> INT_SHIM_HEADER_SIZE = 4;

const bit<8> EMPTY_FL    = 0;
const bit<8> RESUB_FL_1  = 1;
const bit<8> CLONE_FL_1  = 2;
const bit<8> RECIRC_FL_1 = 3;

const bit<32> INT_REPORT_MIRROR_SESSION_ID = 1;   // mirror session specyfing egress_port for cloned INT report packets, defined by switch CLI command   

// defines that is the type of packet instance
#define PKT_INSTANCE_TYPE_NORMAL 0
#define PKT_INSTANCE_TYPE_INGRESS_CLONE 1
#define PKT_INSTANCE_TYPE_EGRESS_CLONE 2
#define PKT_INSTANCE_TYPE_COALESCED 3
#define PKT_INSTANCE_TYPE_INGRESS_RECIRC 4
#define PKT_INSTANCE_TYPE_REPLICATION 5
#define PKT_INSTANCE_TYPE_RESUBMIT 6

// defines int header length
const bit<4> INT_REPORT_HEADER_LEN_WORDS = 4;
const bit<4> INT_REPORT_VERSION = 1;

typedef bit<9>  egress_spec_t;
typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<16> l4_port_t;
typedef bit<9>  port_t;
typedef bit<16> next_hop_id_t;
typedef bit<32> switch_id_t;

#define MAX_PORTS 255

#endif /* __DEFINES__ */