# SUSE's openQA tests
#
# Copyright 2016-2018 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Package: crmsh
# Summary: Execute fence command on one of the cluster nodes
# Maintainer: QE-SAP <qe-sap@suse.de>, Loic Devulder <ldevulder@suse.com>

use base 'opensusebasetest';
use strict;
use warnings;
use testapi;
use lockapi;
use hacluster;

sub run {
    my $cluster_name = get_cluster_name;
    my $node_to_fence = get_var('NODE_TO_FENCE', undef);
    my $node_index = !defined $node_to_fence ? 1 : 2;

    # Check cluster state *before* fencing
    barrier_wait("CHECK_BEFORE_FENCING_BEGIN_${cluster_name}_NODE${node_index}");
    check_cluster_state;
    barrier_wait("CHECK_BEFORE_FENCING_END_${cluster_name}_NODE${node_index}");

    # Give time for HANA to replicate the database
    if (check_var('CLUSTER_NAME', 'hana')) {
        'sles4sap'->check_replication_state;
        'sles4sap'->check_hanasr_attr;
        save_screenshot;
        barrier_wait("HANA_REPLICATE_STATE_${cluster_name}_NODE${node_index}");
    }

    # Fence a node with sysrq or crm node fence
    # Sysrq fencing is more a real crash simulation
    if (get_var('USE_SYSRQ_FENCING')) {
        record_info('Fencing info', 'Fencing done by sysrq');
        enter_cmd "echo b > /proc/sysrq-trigger" if ((!defined $node_to_fence && check_var('HA_CLUSTER_INIT', 'yes')) || (defined $node_to_fence && get_hostname eq "$node_to_fence"));
    }
    else {
        record_info('Fencing info', 'Fencing done by crm');
        if (defined $node_to_fence) {
            assert_script_run "crm -F node fence $node_to_fence" if (get_hostname ne "$node_to_fence");
        } elsif (is_node(2)) {
            assert_script_run('crm -F node fence ' . get_node_to_join, timeout => 300);
        }
    }

    # exit virtio console because node 2 will reboot
    select_console('root-console', skip_set_standard_prompt => 1, skip_setterm => 1) if is_node(1);

    # In case of HANA cluster we also have to test the failback/takeback after the first fencing
    if (check_var('CLUSTER_NAME', 'hana') && !defined $node_to_fence) {
        set_var('TAKEOVER_NODE', choose_node(2));
    } else {
        set_var('TAKEOVER_NODE', choose_node(1)) if check_var('CLUSTER_NAME', 'hana');
    }
}

1;
