#!/usr/bin/env python3
import sys
import struct
import os

from scapy.all import sniff, sendp, hexdump, get_if_list, get_if_hwaddr
from scapy.all import Packet, IPOption
from scapy.all import ShortField, IntField, LongField, BitField, FieldListField, FieldLenField
from scapy.all import IP, TCP, UDP, Raw
from scapy.layers.inet import _IPOption_HDR
import time

# header sizes in bytes
INT_REPORT_SIZE = 16
ETH_SIZE = 14 
IP_SIZE = 20
UDP_SIZE = 8
INT_SHIM_SIZE = 4
INT_HEADER = 8

BYTE_SIZE = 8

# use this constant to specify which int data to collect
INGRESS_PORT_ID_DATA = 0
EGRESS_PORT_ID_DATA = 1
HOP_LATENCY_DATA = 2
Q_ID_DATA = 3
Q_OCCUPANCY_DATA = 4
INGRESS_TSTAMP_DATA = 5
EGRESS_TSTAMP_DATA = 6
EGRESS_PORT_TX_UTIL_DATA = 7

# convert a byte String to a binary String
def bytes2bin(byteStr : bytes):

    binaryString = ''

    for byte in byteStr:
        # [2:] to strip the 0x and add 0 padding to the left
        b = bin(byte)[2:].rjust(BYTE_SIZE, '0')
        binaryString += b

    return binaryString

# will read len number of binary from binStr starting 
# at bin_idx position, then increments bin_idx by len 
def bin2int(binStr, bin_idx, len):
    b = binStr[bin_idx : bin_idx + len]
    bin_idx += len 
    value = int(b, 2)
    return value, bin_idx


def parse_int_report_hdr(payload : bytes, payload_idx, printInfo=False):
    # header int_report_fixed_header_t
    # bit<4>  ver;
    # bit<4>  len;
    # bit<3>  nproto;
    # bit<6>  rep_md_bits;
    # bit<6>  rsvd;
    # bit<1>  d;
    # bit<1>  q;
    # bit<1>  f;
    # bit<6>  hw_id;
    # bit<32> sw_id;
    # bit<32> seq_no;
    # bit<32> ingress_tstamp;

    int_rep_hdr = payload[payload_idx : payload_idx + INT_REPORT_SIZE]
    payload_idx += INT_REPORT_SIZE

    hdr_idx = 0
    binStr = bytes2bin(int_rep_hdr)


    ver, hdr_idx = bin2int(binStr, hdr_idx, 4)

    len, hdr_idx = bin2int(binStr, hdr_idx, 4)

    nproto, hdr_idx = bin2int(binStr, hdr_idx, 3)

    rep_md_bits, hdr_idx = bin2int(binStr, hdr_idx, 6)

    rsvd, hdr_idx = bin2int(binStr, hdr_idx, 6)

    d, hdr_idx = bin2int(binStr, hdr_idx, 1)

    q, hdr_idx = bin2int(binStr, hdr_idx, 1)

    f, hdr_idx = bin2int(binStr, hdr_idx, 1)

    hw_id, hdr_idx = bin2int(binStr, hdr_idx, 6)

    sw_id, hdr_idx = bin2int(binStr, hdr_idx, 32)

    seq_no, hdr_idx = bin2int(binStr, hdr_idx, 32)
    ingress_tstamp, hdr_idx = bin2int(binStr, hdr_idx, 32)

    if printInfo:

        print("report_fixed_header".center(40, "*"))
        print(f'ver is {ver}')
        print(f'len is {len}')
        print(f'nproto is {nproto}')
        print(f'rep_md_bits is {rep_md_bits}')
        print(f'rsvd is {rsvd}')
        print(f'd is {d}')
        print(f'q is {q}')
        print(f'f is {f}')
        print(f'hw_id is {hw_id}')
        print(f'sw_id is {sw_id}')
        print(f'seq_no is {seq_no}')
        print(f'ingress_tstamp is {ingress_tstamp}')
    return payload_idx

def parse_ethernet_hdr(payload : bytes, payload_idx, printInfo=False):
    # header ethernet_t 
    # bit<48> dst_addr;
    # bit<48> src_addr;
    # bit<16>   etherType;

    eth_hdr = payload[payload_idx : payload_idx + ETH_SIZE]
    payload_idx += ETH_SIZE

    hdr_idx = 0
    binStr = bytes2bin(eth_hdr)

    dst_addr, hdr_idx = bin2int(binStr, hdr_idx, 48)
    src_addr, hdr_idx = bin2int(binStr, hdr_idx, 48)
    etherType, hdr_idx = bin2int(binStr, hdr_idx, 16)

    if printInfo:
        print("ethernet".center(40, "*"))
        print(f'dst_addr is {dst_addr}')
        print(f'src_addr is {src_addr}')
        print(f'etherType is {etherType}')

    return payload_idx

def parse_ipv4_hdr(payload : bytes, payload_idx, printInfo=False):
    # bit<4>  version;
    # bit<4>  ihl;
    # bit<6>  dscp;
    # bit<2>  ecn;
    # bit<16> len;
    # bit<16> identification;
    # bit<3>  flags;
    # bit<13> frag_offset;
    # bit<8>  ttl;
    # bit<8>  protocol;
    # bit<16> hdr_checksum;
    # bit<32> src_addr;
    # bit<32> dst_addr;
    
    ipv4_hdr = payload[payload_idx : payload_idx + IP_SIZE]
    payload_idx += IP_SIZE

    hdr_idx = 0
    binStr : str = bytes2bin(ipv4_hdr)

    version, hdr_idx = bin2int(binStr, hdr_idx, 4)
    ihl, hdr_idx = bin2int(binStr, hdr_idx, 4)
    dscp, hdr_idx = bin2int(binStr, hdr_idx, 6)
    ecn, hdr_idx = bin2int(binStr, hdr_idx, 2)
    length, hdr_idx = bin2int(binStr, hdr_idx, 16)
    identification, hdr_idx = bin2int(binStr, hdr_idx, 16)
    flags, hdr_idx = bin2int(binStr, hdr_idx, 3)
    frag_offset, hdr_idx = bin2int(binStr, hdr_idx, 13)
    ttl, hdr_idx = bin2int(binStr, hdr_idx, 8)
    protocol, hdr_idx = bin2int(binStr, hdr_idx, 8)
    hdr_checksum, hdr_idx = bin2int(binStr, hdr_idx, 16)
    src_addr, hdr_idx = bin2int(binStr, hdr_idx, 32)
    dst_addr, hdr_idx = bin2int(binStr, hdr_idx, 32)

    if printInfo:
        print("ipv4".center(40, "*"))
        print(f'version is {version}')
        print(f'ihl is {ihl}')
        print(f'dscp is {dscp}')
        print(f'ecn is {ecn}')
        print(f'length is {length}')
        print(f'identification is {identification}')
        print(f'flags is {flags}')
        print(f'frag_offset is {frag_offset}')
        print(f'ttl is {ttl}')
        print(f'protocol is {protocol}')
        print(f'hdr_checksum is {hdr_checksum}')
        print(f'src_addr is {src_addr}')
        print(f'dst_addr is {dst_addr}')

    return payload_idx


def parse_udp_hdr(payload : bytes, payload_idx, printInfo=False):
    # bit<16> src_port;
    # bit<16> dst_port;
    # bit<16> length_;
    # bit<16> checksum;

    udp_hdr = payload[payload_idx : payload_idx + UDP_SIZE]
    payload_idx += UDP_SIZE

    hdr_idx = 0
    binStr : str = bytes2bin(udp_hdr)

    src_port, hdr_idx = bin2int(binStr, hdr_idx, 16)
    dst_port, hdr_idx = bin2int(binStr, hdr_idx, 16)
    length_, hdr_idx = bin2int(binStr, hdr_idx, 16)
    checksum, hdr_idx = bin2int(binStr, hdr_idx, 16)

    if printInfo:
        print("udp".center(40, "*"))
        print(f'src_port is {src_port}')
        print(f'dst_port is {dst_port}')
        print(f'length_ is {length_}')
        print(f'checksum is {checksum}')

    return payload_idx

def parse_int_shim_hdr(payload : bytes, payload_idx, printInfo=False):
    # bit<8> int_type;
    # bit<8> rsvd1;
    # bit<8> len;
    # bit<6> dscp;
    # bit<2> rsvd2;
    
    int_shim_hdr = payload[payload_idx : payload_idx + INT_SHIM_SIZE]
    payload_idx += INT_SHIM_SIZE

    hdr_idx = 0
    binStr : str = bytes2bin(int_shim_hdr)

    int_type, hdr_idx = bin2int(binStr, hdr_idx, 8)
    rsvd1, hdr_idx = bin2int(binStr, hdr_idx, 8)
    length, hdr_idx = bin2int(binStr, hdr_idx, 8)
    dscp, hdr_idx = bin2int(binStr, hdr_idx, 6)
    rsvd2, hdr_idx = bin2int(binStr, hdr_idx, 2)

    if printInfo:
        print("int_shim".center(40, "*"))
        print(f'int_type is {int_type}')
        print(f'rsvd1 is {rsvd1}')
        print(f'len is {length}')
        print(f'dscp is {dscp}')
        print(f'rsvd2 is {rsvd2}')

    return payload_idx

def parse_int_header(payload : bytes, payload_idx, printInfo=False):
    # bit<4>  ver;
    # bit<2>  rep;
    # bit<1>  c;
    # bit<1>  e;
    # bit<1>  m;
    # bit<7>  rsvd1;
    # bit<3>  rsvd2;
    # bit<5>  hop_metadata_len; /* the length of the metadata added by a single INT node (4-byte words) */
    # bit<8>  remaining_hop_cnt;
    # bit<4>  instruction_mask_0003; /* split the bits for lookup */
    # bit<4>  instruction_mask_0407;
    # bit<4>  instruction_mask_0811;
    # bit<4>  instruction_mask_1215;
    # bit<16> rsvd3;
    
    int_hdr = payload[payload_idx : payload_idx + INT_HEADER]
    payload_idx += INT_HEADER

    hdr_idx = 0
    binStr : str = bytes2bin(int_hdr)

    ver, hdr_idx = bin2int(binStr, hdr_idx, 4)
    rep, hdr_idx = bin2int(binStr, hdr_idx, 2)
    c, hdr_idx = bin2int(binStr, hdr_idx, 1)
    e, hdr_idx = bin2int(binStr, hdr_idx, 1)
    m, hdr_idx = bin2int(binStr, hdr_idx, 1)
    rsvd1, hdr_idx = bin2int(binStr, hdr_idx, 7)
    rsvd2, hdr_idx = bin2int(binStr, hdr_idx, 3)
    hop_metadata_len, hdr_idx = bin2int(binStr, hdr_idx, 5)
    remaining_hop_cnt, hdr_idx = bin2int(binStr, hdr_idx, 8)
    instruction_mask_0003, hdr_idx = bin2int(binStr, hdr_idx, 4)
    instruction_mask_0407, hdr_idx = bin2int(binStr, hdr_idx, 4)
    instruction_mask_0811, hdr_idx = bin2int(binStr, hdr_idx, 4)
    instruction_mask_1215, hdr_idx = bin2int(binStr, hdr_idx, 4)
    rsvd3, hdr_idx = bin2int(binStr, hdr_idx, 16)


    if printInfo:
        print("int_header".center(40, "*"))
        print(f'ver is {ver}')
        print(f'rep is {rep}')
        print(f'c is {c}')
        print(f'e is {e}')
        print(f'm is {m}')
        print(f'rsvd1 is {rsvd1}')
        print(f'rsvd2 is {rsvd2}')
        print(f'hop_metadata_len is {hop_metadata_len}')
        print(f'remaining_hop_cnt is {remaining_hop_cnt}')
        print(f'instruction_mask_0003 is {instruction_mask_0003}')
        print(f'instruction_mask_0407 is {instruction_mask_0407}')
        print(f'instruction_mask_0811 is {instruction_mask_0811}')
        print(f'instruction_mask_1215 is {instruction_mask_1215}')
        print(f'rsvd3 is {rsvd3}')

    return payload_idx
 
# currently does not support multiple transits with different modes (different num_fileds) 
# num_fields is the number of fields that are set valid during int transit
# num_transits is the number of 
def parse_int_data(num_fields, num_transits, payload, payload_idx, dataToRecord, s1, s2, s3, s4, tic, printInfo=False) :
    #  each field is 32 bits, which is 4 bytes
    int_data = payload[payload_idx : payload_idx + (4 * num_fields * num_transits)]
    payload_idx += 4 * num_fields * num_transits

    hdr_idx = 0
    binStr : str = bytes2bin(int_data)

    if printInfo:
        print("int_data".center(40, "*"), "\n")

    for i in range(num_transits):

        int_switch_id, hdr_idx = bin2int(binStr, hdr_idx, 32)
        ingress_port_id, hdr_idx = bin2int(binStr, hdr_idx, 16)
        egress_port_id, hdr_idx = bin2int(binStr, hdr_idx, 16)
        int_hop_latency, hdr_idx = bin2int(binStr, hdr_idx, 32)
        q_id, hdr_idx = bin2int(binStr, hdr_idx, 8)
        q_occupancy, hdr_idx = bin2int(binStr, hdr_idx, 24)
        int_ingress_tstamp, hdr_idx = bin2int(binStr, hdr_idx, 32)
        int_egress_tstamp, hdr_idx = bin2int(binStr, hdr_idx, 32)
        ingress_port_id, hdr_idx = bin2int(binStr, hdr_idx, 16)
        egress_port_id, hdr_idx = bin2int(binStr, hdr_idx, 16)
        int_egress_port_tx_util, hdr_idx = bin2int(binStr, hdr_idx, 32)

        if printInfo:
            print(f"switch {int_switch_id}".center(40, "*"))
            print(f'ingress_port_id is {ingress_port_id}')
            print(f'egress_port_id is {egress_port_id}')
            print(f'int_hop_latency is {int_hop_latency}')
            print(f'q_id is {q_id}')     
            print(f'q_occupancy is {q_occupancy}')
            print(f'int_ingress_tstamp is {int_ingress_tstamp}')
            print(f'int_egress_tstamp is {int_egress_tstamp}')
            print(f'int_egress_port_tx_util is {int_egress_port_tx_util}')

        toc = time.perf_counter()

        fileToWrite = None

        if int_switch_id == 1:
            fileToWrite = s1
        elif int_switch_id == 2:
            fileToWrite = s2
        elif int_switch_id == 3:
            fileToWrite = s3
        elif int_switch_id == 4:
            fileToWrite = s4
        
        if dataToRecord == HOP_LATENCY_DATA:
            fileToWrite.write(f"{toc - tic:0.4f}, {int_hop_latency}\n")
        elif dataToRecord == Q_OCCUPANCY_DATA:
            fileToWrite.write(f"{toc - tic:0.4f}, {q_occupancy}\n")

    return payload_idx

# printInfo sets either to print the packet headers and int data
def int_parser(payload : bytes, s1, s2, s3, s4, tic, printInfo=False) :

    dataToRecord = HOP_LATENCY_DATA
    #  INT report strucure
    # [Eth][IP][UDP][INT RAPORT HDR][ETH][IP][UDP/TCP][INT SHIM][INT HEADER][INT DATA]
    # payload : [INT RAPORT HDR]      [ETH]                  [IP]             
    #           16 bytes : 0-15       14 bytes : 16-29      20 bytes : 30-49
    #           [UDP/TCP]             [INT SHIM]             [INT HEADER]              [INT DATA]
    #           8 bytes : 50->57      4 bytes : 58->61       8 bytes : 62-69
    
    # start parsing from index = payload_idx
    payload_idx = 0
    payload_idx = parse_int_report_hdr(payload, payload_idx, printInfo=printInfo)
    payload_idx = parse_ethernet_hdr(payload, payload_idx, printInfo=printInfo)
    payload_idx = parse_ipv4_hdr(payload, payload_idx, printInfo=printInfo)
    payload_idx = parse_udp_hdr(payload, payload_idx, printInfo=printInfo)
    payload_idx = parse_int_shim_hdr(payload, payload_idx, printInfo=printInfo)
    payload_idx = parse_int_header(payload, payload_idx, printInfo=printInfo)
    payload_idx = parse_int_data(8, 3, payload, payload_idx, dataToRecord, s1, s2, s3, s4, tic, printInfo=printInfo)
    
def get_if():
    ifs = get_if_list()
    iface = None
    for i in get_if_list():
        if "eth0" in i:
            iface = i
            break
    if not iface:
        print("Cannot find eth0 interface")
        exit(1)
    return iface


def handle_pkt(pkt, s1, s2, s3, s4, tic):
    if UDP in pkt and pkt[UDP].dport == 8002:
        print("got a packet")
        # pkt.show2()
        payload = bytes(pkt[UDP].payload)
        int_parser(payload, s1, s2, s3, s4, tic)
        sys.stdout.flush()


def main():

    with open("s1_data.txt", "w") as s1, \
         open("s2_data.txt", "w") as s2, \
         open("s3_data.txt", "w") as s3, \
         open("s4_data.txt", "w") as s4: 
        
        tic = time.perf_counter()
        iface = get_if()
        print("sniffing on %s" % iface)
        sys.stdout.flush()
        sniff(iface=iface,
            prn=lambda x: handle_pkt(x, s1, s2, s3, s4, tic))


if __name__ == '__main__':
    main()
