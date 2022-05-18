# SUSE's openQA tests
#
# Copyright 2020 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Package: pacemaker-cli
# Summary: Check cluster integrity
# Maintainer: QE-SAP <qe-sap@suse.de>, Christian Lanig <clanig@suse.com>

use base 'opensusebasetest';
use strict;
use warnings;
use testapi;
use hacluster;

sub run {
    my $self = shift;
    $self->select_serial_terminal;
    sleep 120;
    # Check for the state of the whole cluster
    check_cluster_state;
}

1;
