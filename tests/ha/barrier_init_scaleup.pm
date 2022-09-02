# SUSE's openQA tests
#
# Copyright 2016-2018 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Summary: Initialize barriers used in HA cluster tests
# Maintainer: QE-SAP <qe-sap@suse.de>, Loic Devulder <ldevulder@suse.com>

use base 'opensusebasetest';
use strict;
use warnings;
use testapi;
use lockapi;
use mmapi;

# This tells the module whether the test is running in a supportserver or in node1
sub is_not_supportserver_scenario {
    return (get_var('HOSTNAME', '') =~ /node01$/ and !get_var('USE_SUPPORT_SERVER'));
}

sub run {
    my $cluster_infos = get_required_var('CLUSTER_INFOS');

    foreach (split(/,/, $cluster_infos)) {
        # The CLUSTER_INFOS variable for support_server also contains the number of node
        my ($cluster_name, $num_nodes) = split(/:/, $_);

        # Number of node is a mandatory variable!
        die 'A valid number of nodes is mandatory' if ($num_nodes lt '2');

            mutex_create 'iscsi';    # Mutex is already created in supportserver, no need to create it before
            barrier_create("BARRIER_HA_$cluster_name", $num_nodes);
            barrier_create("BARRIER_HA_NFS_SUPPORT_DIR_SETUP_$cluster_name", $num_nodes);
            barrier_create("BARRIER_HA_HOSTS_FILES_READY_$cluster_name", $num_nodes);
            barrier_create("BARRIER_HA_LUNS_FILES_READY_$cluster_name", $num_nodes);
            barrier_create("BARRIER_HA_NONSS_FILES_SYNCED_$cluster_name", $num_nodes);
        }
        else {
    }
}

1;
