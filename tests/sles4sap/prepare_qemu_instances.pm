# SUSE's openQA tests
#
# Copyright 2022 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Summary: Define site A and site B
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
    my ($self) = @_;
    $self->select_serial_terminal;
    my $cluster_name = get_cluster_name;

    printf "TADA\n";
    print Dumper $self->{my_instance};

    barrier_wait("BARRIER_REPLICATION_READY_$cluster_name");
    foreach (split /\n/, script_output q(awk '{print $2}' /etc/hosts)) {
        enter_cmd "expect -c 'spawn ssh-copy-id $_;expect \"Are you sure\";send yes\\n;expect sword:;send $testapi::password\\n;expect #;send \\n;interact'";
    }
}

1;
