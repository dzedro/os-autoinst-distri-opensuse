# SUSE's openQA tests
#
# Copyright 2022 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Summary: HANA SR - Stop database on site B
# Stop database on Site A by stopping HDB.
# Do takeover do Site B
# https://documentation.suse.com/sbp/all/html/SLES4SAP-hana-sr-guide-costopt-15/index.html#id-test-stop-primary-database-on-site-b-node-2-2
#
# Maintainer: QE-SAP <qe-sap@suse.de>

use base sles4sap_remote;
use strict;
use warnings FATAL => 'all';
use diagnostics;

sub run {
    my ($self) = @_;
    $self->select_serial_terminal;

    $self->stop_hana(node => 'hana-node02', method => 'stop', runas => 'ha1adm');
    $self->check_takeover(node => 'hana-node02');
    $self->enable_replication(node => 'hana-node02', second_node => 'hana-node01');
    $self->cleanup_resource(node => 'hana-node02');
}

1;
