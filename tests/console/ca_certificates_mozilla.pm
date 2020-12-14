# SUSE's openQA tests
#
# Copyright © 2018-2020 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Package: ca-certificates-mozilla openssl
# Summary: Install ca-certificates-mozilla and test connection to a secure website
# - install ca-certificates-mozilla and openssl
# - connect to static.opensuse.org:443 using openssl and verify that the return code is 0
# Maintainer: Orestis Nalmpantis <onalmpantis@suse.de>

use base "consoletest";
use strict;
use warnings;
use testapi;
use utils 'zypper_call';

sub run {
    my $self = shift;
    $self->select_serial_terminal;
    zypper_call 'in ca-certificates-mozilla openssl';
    assert_script_run('echo "x" | openssl s_client -connect static.opensuse.org:443 | grep "Verify return code: 0"');
}

1;
