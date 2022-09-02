# SUSE's openQA tests
#
# Copyright 2022 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Summary: Initialize locks used in HANA scaleup test
# Maintainer: QE-SAP <qe-sap@suse.de>

use base 'opensusebasetest';
use strict;
use warnings;
use testapi;
use lockapi;
use mmapi;

sub run {
    if (get_var('SUPPORT_SERVER')) {
        my $cluster_infos = get_required_var('CLUSTER_INFOS');

        foreach (split(/,/, $cluster_infos)) {
            # The CLUSTER_INFOS variable for support_server also contains the number of node
            my ($cluster_name, $num_nodes) = split(/:/, $_);

            # Number of node is a mandatory variable!
            die 'A valid number of nodes is mandatory' if ($num_nodes lt '2');

            barrier_create("BARRIER_SLES4SAP_$cluster_name", $num_nodes)
            mutex_create('WAIT_FOR_BARRIERS_CREATE');
        }
    }
    else {
         mutex_wait('WAIT_FOR_BARRIERS_CREATE');
    }
}

1;
