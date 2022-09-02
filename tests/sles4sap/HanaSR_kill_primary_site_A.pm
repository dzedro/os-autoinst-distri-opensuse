# SUSE's openQA tests
#
# Copyright 2022 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Summary: HANA SR - Kill database on site A
# Stop database on Site A by HDB kill-9.
# Do takeover do Site B
# https://documentation.suse.com/sbp/all/html/SLES4SAP-hana-sr-guide-costopt-15/index.html#id-test-crash-primary-database-on-site-a-node-1-2
#
# Maintainer: QE-SAP <qe-sap@suse.de>

use base sles4sap_remote;
use strict;
use warnings FATAL => 'all';
use diagnostics;
use testapi;

sub run {
    my ($self) = @_;
    $self->select_serial_terminal;

    $self->stop_hana(node => 'hana-node01', method => 'kill', runas => 'ha1adm');
    $self->check_takeover(node => 'hana-node01');
    $self->enable_replication(node => 'hana-node01', second_node => 'hana-node02');
    $self->cleanup_resource(node => 'hana-node01');
}

1;
