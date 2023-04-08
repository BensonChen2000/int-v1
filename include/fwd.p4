#ifndef __FWD__
#define __FWD__

#include "headers.p4"

control FwdIngress(inout headers_t hdr,
                  inout local_metadata_t local_metadata,
                  inout standard_metadata_t standard_metadata) {
    
    /*
     * Why bother creating an action that just does one primitive
     * action?  That is, why not just use 'mark_to_drop' as one of the
     * possible actions when defining a table?  Because the P4_16
     * compiler does not allow primitive actions to be used directly
     * as actions of tables.  You must use 'compound actions',
     * i.e. ones explicitly defined with the 'action' keyword like
     * below.
     *
     * mark_to_drop is an extern function defined in v1model.h,
     * implemented in the behavioral model by setting an appropriate
     * 'standard metadata' field with a code indicating the packet
     * should be dropped.
     *
     * See the following page if you are interested in more detailed
     * documentation on the behavior of mark_to_drop and several other
     * operations in the v1model architecture, as implemented in the
     * open source behavioral-model BMv2 software switch:
     * https://github.com/p4lang/behavioral-model/blob/master/docs/simple_switch.md
     */
    action drop() {
        mark_to_drop(standard_metadata);
    }
    
    action ipv4_forward(mac_addr_t dst_addr, egress_spec_t port) {
        standard_metadata.egress_spec = port;
        hdr.ethernet.src_addr = hdr.ethernet.src_addr;
        hdr.ethernet.dst_addr = dst_addr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }
    
    table ipv4_lpm {
        key = {
            /* lpm means 'Longest Prefix Match'.  It is called a
             * 'match_kind' in P4_16, and the two most common other
             * choices seen in P4 programs are 'exact' and
             * 'ternary'. */
            hdr.ipv4.dst_addr: lpm;
        }
        actions = {
            ipv4_forward;
            drop;
            NoAction;
        }
        size = 1024;
        /* If at packet forwarding time, there is no matching entry
         * found in the table, the action specified by the
         * 'default_action' keyword will be performed on the packet.
         *
         * In this case, drop is only the default action for this
         * table when the P4 program is first loaded into the device.
         * The control plane can choose to change that default action,
         * via an appropriate API call, to a different action.  If you
         * put 'const' before 'default_action', then it means that
         * this default action cannot be changed by the control
         * plane. */
        default_action = drop();
    }
    
    apply {
        if (hdr.ipv4.isValid()) {
            ipv4_lpm.apply();
        }
    }
}

#endif