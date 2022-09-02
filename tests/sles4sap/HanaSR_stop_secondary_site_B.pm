# SUSE's openQA tests
#
# Copyright 2022 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Summary: HANA SR - Stop database on secondary node02 (site B)
# Stop database on site B by HDB stop.
# No takeover is done, non-replicated DB not affected on node02 (site B)
# https://documentation.suse.com/sbp/all/html/SLES4SAP-hana-sr-guide-costopt-15/index.html#id-test-stop-the-secondary-database-on-site-b-node-2-2
#
# Maintainer: QE-SAP <qe-sap@suse.de>

use base sles4sap_remote;
use strict;
use warnings FATAL => 'all';
use diagnostics;
use testapi;
use lockapi;
use hacluster qw(get_cluster_name);

sub run {
    my ($self) = @_;
    $self->select_serial_terminal;
    my $cluster_name = get_cluster_name;

    $self->wait_for_sync(node => 'hana-node02');
    $self->run_cmd(cmd => 'HDB stop', node => 'hana-node02', runas => 'ha1adm', timeout => 300);
    $self->run_cmd(cmd => 'crm status', node => 'hana-node02');
#    $self->check_sapcontrol(node => 'hana-node02', function => 'GetSystemInstanceList', expect => 'GRAY');
    $self->run_cmd(cmd => 'until SAPHanaSR-showAttr|grep -Ez "PRIM.*SFAIL"; do sleep 2; done', node => 'hana-node02', timeout => 600);
    $self->run_cmd(cmd => 'SAPHanaSR-showAttr', node => 'hana-node02');
    $self->run_cmd(cmd => 'crm status', node => 'hana-node02');
    $self->run_cmd(cmd => 'crm_mon -R -r -n -N -1', node => 'hana-node02');
    $self->wait_for_sync(node => 'hana-node02');
    barrier_wait("BARRIER_REPLICATION_DONE_$cluster_name");
}

1;
