#!/usr/bin/env python3
import sys
import struct
import os

from scapy.all import sniff, sendp, hexdump, get_if_list, get_if_hwaddr
from scapy.all import Packet, IPOption
from scapy.all import ShortField, IntField, LongField, BitField, FieldListField, FieldLenField
from scapy.all import IP, TCP, UDP, Raw
from scapy.layers.inet import _IPOption_HDR

# header sizes in bytes
INT_REPORT_SIZE = 16
ETH_SIZE = 14 
IP_SIZE = 20
UDP_SIZE = 8
INT_SHIM_SIZE = 4
INT_HEADER = 8

BYTE_SIZE = 8

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


def parse_int_report_hdr(payload : bytes, payload_idx):
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

    print("report_fixed_header".center(40, "*"))
    ver, hdr_idx = bin2int(binStr, hdr_idx, 4)
    print(f'ver is {ver}')
    len, hdr_idx = bin2int(binStr, hdr_idx, 4)
    print(f'len is {len}')
    nproto, hdr_idx = bin2int(binStr, hdr_idx, 3)
    print(f'nproto is {nproto}')
    rep_md_bits, hdr_idx = bin2int(binStr, hdr_idx, 6)
    print(f'rep_md_bits is {rep_md_bits}')
    rsvd, hdr_idx = bin2int(binStr, hdr_idx, 6)
    print(f'rsvd is {rsvd}')
    d, hdr_idx = bin2int(binStr, hdr_idx, 1)
    print(f'd is {d}')
    q, hdr_idx = bin2int(binStr, hdr_idx, 1)
    print(f'q is {q}')
    f, hdr_idx = bin2int(binStr, hdr_idx, 1)
    print(f'f is {f}')
    hw_id, hdr_idx = bin2int(binStr, hdr_idx, 6)
    print(f'hw_id is {hw_id}')
    sw_id, hdr_idx = bin2int(binStr, hdr_idx, 32)
    print(f'sw_id is {sw_id}')
    seq_no, hdr_idx = bin2int(binStr, hdr_idx, 32)
    print(f'seq_no is {seq_no}')
    ingress_tstamp, hdr_idx = bin2int(binStr, hdr_idx, 32)
    print(f'ingress_tstamp is {ingress_tstamp}')
    return payload_idx

def parse_ethernet_hdr(payload : bytes, payload_idx):
    # header ethernet_t 
    # bit<48> dst_addr;
    # bit<48> src_addr;
    # bit<16>   etherType;

    eth_hdr = payload[payload_idx : payload_idx + ETH_SIZE]
    payload_idx += ETH_SIZE

    hdr_idx = 0
    binStr = bytes2bin(eth_hdr)

    print(f"length of ethernet is {len(binStr)}")

    print("ethernet".center(40, "*"))

    dst_addr, hdr_idx = bin2int(binStr, hdr_idx, 48)
    print(f'dst_addr is {dst_addr}')

    src_addr, hdr_idx = bin2int(binStr, hdr_idx, 48)
    print(f'src_addr is {src_addr}')

    etherType, hdr_idx = bin2int(binStr, hdr_idx, 16)
    print(f'etherType is {etherType}')

    return payload_idx

def parse_ipv4_hdr(payload : bytes, payload_idx):
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

    print("ipv4".center(40, "*"))

    version, hdr_idx = bin2int(binStr, hdr_idx, 4)
    print(f'version is {version}')

    ihl, hdr_idx = bin2int(binStr, hdr_idx, 4)
    print(f'ihl is {ihl}')

    dscp, hdr_idx = bin2int(binStr, hdr_idx, 6)
    print(f'dscp is {dscp}')

    ecn, hdr_idx = bin2int(binStr, hdr_idx, 2)
    print(f'ecn is {ecn}')

    length, hdr_idx = bin2int(binStr, hdr_idx, 16)
    print(f'length is {length}')

    identification, hdr_idx = bin2int(binStr, hdr_idx, 16)
    print(f'identification is {identification}')

    flags, hdr_idx = bin2int(binStr, hdr_idx, 3)
    print(f'flags is {flags}')

    frag_offset, hdr_idx = bin2int(binStr, hdr_idx, 13)
    print(f'frag_offset is {frag_offset}')

    ttl, hdr_idx = bin2int(binStr, hdr_idx, 8)
    print(f'ttl is {ttl}')

    protocol, hdr_idx = bin2int(binStr, hdr_idx, 8)
    print(f'protocol is {protocol}')

    hdr_checksum, hdr_idx = bin2int(binStr, hdr_idx, 16)
    print(f'hdr_checksum is {hdr_checksum}')

    src_addr, hdr_idx = bin2int(binStr, hdr_idx, 32)
    print(f'src_addr is {src_addr}')

    dst_addr, hdr_idx = bin2int(binStr, hdr_idx, 32)
    print(f'dst_addr is {dst_addr}')

    return payload_idx


def parse_udp_hdr(payload : bytes, payload_idx):
    # bit<16> src_port;
    # bit<16> dst_port;
    # bit<16> length_;
    # bit<16> checksum;

    udp_hdr = payload[payload_idx : payload_idx + UDP_SIZE]
    payload_idx += UDP_SIZE

    hdr_idx = 0
    binStr : str = bytes2bin(udp_hdr)

    print("udp".center(40, "*"))

    src_port, hdr_idx = bin2int(binStr, hdr_idx, 16)
    print(f'src_port is {src_port}')

    dst_port, hdr_idx = bin2int(binStr, hdr_idx, 16)
    print(f'dst_port is {dst_port}')

    length_, hdr_idx = bin2int(binStr, hdr_idx, 16)
    print(f'length_ is {length_}')

    checksum, hdr_idx = bin2int(binStr, hdr_idx, 16)
    print(f'checksum is {checksum}')

    return payload_idx

def parse_int_shim_hdr(payload : bytes, payload_idx):
    # bit<8> int_type;
    # bit<8> rsvd1;
    # bit<8> len;
    # bit<6> dscp;
    # bit<2> rsvd2;
    
    int_shim_hdr = payload[payload_idx : payload_idx + INT_SHIM_SIZE]
    payload_idx += INT_SHIM_SIZE

    hdr_idx = 0
    binStr : str = bytes2bin(int_shim_hdr)

    print("int_shim".center(40, "*"))

    int_type, hdr_idx = bin2int(binStr, hdr_idx, 8)
    print(f'int_type is {int_type}')

    rsvd1, hdr_idx = bin2int(binStr, hdr_idx, 8)
    print(f'rsvd1 is {rsvd1}')

    length, hdr_idx = bin2int(binStr, hdr_idx, 8)
    print(f'len is {length}')

    dscp, hdr_idx = bin2int(binStr, hdr_idx, 6)
    print(f'dscp is {dscp}')

    rsvd2, hdr_idx = bin2int(binStr, hdr_idx, 2)
    print(f'rsvd2 is {rsvd2}')

    return payload_idx

def parse_int_header(payload : bytes, payload_idx):
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

    print("int_header".center(40, "*"))

    ver, hdr_idx = bin2int(binStr, hdr_idx, 4)
    print(f'ver is {ver}')

    rep, hdr_idx = bin2int(binStr, hdr_idx, 2)
    print(f'rep is {rep}')

    c, hdr_idx = bin2int(binStr, hdr_idx, 1)
    print(f'c is {c}')

    e, hdr_idx = bin2int(binStr, hdr_idx, 1)
    print(f'e is {e}')

    m, hdr_idx = bin2int(binStr, hdr_idx, 1)
    print(f'm is {m}')

    rsvd1, hdr_idx = bin2int(binStr, hdr_idx, 7)
    print(f'rsvd1 is {rsvd1}')

    rsvd2, hdr_idx = bin2int(binStr, hdr_idx, 3)
    print(f'rsvd2 is {rsvd2}')

    hop_metadata_len, hdr_idx = bin2int(binStr, hdr_idx, 5)
    print(f'hop_metadata_len is {hop_metadata_len}')

    remaining_hop_cnt, hdr_idx = bin2int(binStr, hdr_idx, 8)
    print(f'remaining_hop_cnt is {remaining_hop_cnt}')

    instruction_mask_0003, hdr_idx = bin2int(binStr, hdr_idx, 4)
    print(f'instruction_mask_0003 is {instruction_mask_0003}')

    instruction_mask_0407, hdr_idx = bin2int(binStr, hdr_idx, 4)
    print(f'instruction_mask_0407 is {instruction_mask_0407}')

    instruction_mask_0811, hdr_idx = bin2int(binStr, hdr_idx, 4)
    print(f'instruction_mask_0811 is {instruction_mask_0811}')

    instruction_mask_1215, hdr_idx = bin2int(binStr, hdr_idx, 4)
    print(f'instruction_mask_1215 is {instruction_mask_1215}')

    rsvd3, hdr_idx = bin2int(binStr, hdr_idx, 16)
    print(f'rsvd3 is {rsvd3}')

    return payload_idx

def int_parser(payload : bytes) :
    #  INT report strucure
    # [Eth][IP][UDP][INT RAPORT HDR][ETH][IP][UDP/TCP][INT SHIM][INT HEADER][INT DATA]
    # payload : [INT RAPORT HDR]      [ETH]                  [IP]             
    #           16 bytes : 0-15       14 bytes : 16-29      20 bytes : 30-49
    #           [UDP/TCP]             [INT SHIM]             [INT HEADER]              [INT DATA]
    #           8 bytes : 50->57      4 bytes : 58->61       8 bytes : 62-69
    
    # start parsing from index = payload_idx
    payload_idx = 0
    payload_idx = parse_int_report_hdr(payload, payload_idx)
    payload_idx = parse_ethernet_hdr(payload, payload_idx)
    payload_idx = parse_ipv4_hdr(payload, payload_idx)
    payload_idx = parse_udp_hdr(payload, payload_idx)
    payload_idx = parse_int_shim_hdr(payload, payload_idx)
    payload_idx = parse_int_header(payload, payload_idx)
    
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


def handle_pkt(pkt):
    if UDP in pkt and pkt[UDP].dport == 8002:
        print("got a packet")
        pkt.show2()
        payload = bytes(pkt[UDP].payload)
        int_parser(payload)
        sys.stdout.flush()


def main():
    iface = get_if()
    print("sniffing on %s" % iface)
    sys.stdout.flush()
    sniff(iface=iface,
          prn=lambda x: handle_pkt(x))


if __name__ == '__main__':
    main()
