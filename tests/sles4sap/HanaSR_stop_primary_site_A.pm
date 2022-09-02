# SUSE's openQA tests
#
# Copyright 2022 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Summary: HANA SR - stop database on site A
# Stop database on Site A by stopping HDB.
# Do takeover do Site B
# https://documentation.suse.com/sbp/all/html/SLES4SAP-hana-sr-guide-costopt-15/index.html#id-test-stop-primary-database-on-site-a-node-1-2
#
# Maintainer: QE-SAP <qe-sap@suse.de>

use base sles4sap_remote;
use strict;
use warnings FATAL => 'all';
use diagnostics;
use testapi;
use lockapi;
use hacluster qw(get_cluster_name);
use Data::Dumper;

sub run {
    my ($self, $run_args) = @_;
    $self->select_serial_terminal;
    $self->{instances} = $run_args->{instances};

#    printf "TADA1\n";
#    print ref(sles4sap_remote->qemu_instances->{site_a});
#    print ref(sles4sap_remote->qemu_instances);
 
    # Switch to control Site A (currently PROMOTED)
#    if (check_var('MACHINE', '64bit')) {
#        $self->{my_instance} = sles4sap_remote->qemu_instances->{site_a};
#    }
#    else {
#        $self->{my_instance} = $run_args->{site_a};
#    }

#    printf "TADA2\n";
#    print Dumper $self->{my_instance};

#    barrier_wait("BARRIER_REPLICATION_READY_$cluster_name");
#    foreach (split /\n/, script_output q(awk '{print $2}' /etc/hosts)) {
#        enter_cmd "expect -c 'spawn ssh-copy-id $_;expect \"Are you sure\";send yes\\n;expect sword:;send $testapi::password\\n;expect #;send \\n;interact'";
#    }
    $self->stop_hana(node => 'hana-node01', method => 'stop', runas => 'ha1adm');
    $self->check_takeover(node => 'hana-node01');
    $self->enable_replication(node => 'hana-node01', second_node => 'hana-node02');
    $self->cleanup_resource(node => 'hana-node01');
}

1;
