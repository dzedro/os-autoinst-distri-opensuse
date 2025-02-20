# SUSE's openQA tests
#
# Copyright 2021 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Summary: Basic systemtap functions
# * Test simple hello world
# * Test stap-server output
# * Test simple probing
# Maintainer: Anastasiadis Vasileios <vasilios.anastasiadis@suse.de>

use base 'consoletest';
use strict;
use warnings;
use testapi;
use serial_terminal 'select_serial_terminal';
use utils;
use kdump_utils;
use version_utils qw(is_sle);
use power_action_utils qw(power_action);

sub run {
    my ($self) = @_;
    select_serial_terminal;
    prepare_for_kdump();
    zypper_call("in systemtap systemtap-docs kernel-devel systemtap-server");
    script_run('ti=$(ls /lib/modules/ | grep $(uname -r) | grep -oP ".*(?=-default)") && zypper se -i -s kernel-default-devel | grep $ti > vertmp');
    my $vers = script_output('cat vertmp');
    if (!$vers) {
        my $kernel_d = script_output('uname -r | grep -oP ".*(?=-default)"');
        my $dev = zypper_call("se -i -s kernel-default-devel", exitcode => [0, 104]);
        if ($dev ne '104') {
            record_info('Update', 'Install latest kernel and boot it');
            zypper_call('up');
            power_action('reboot', textmode => 1);
            $self->wait_boot(bootloader_time => 300);
            select_serial_terminal;
        } else {
            die "kernel-devel package is required but not installed\nExpected: $kernel_d, Found: No kernel-default-devel package installed";
        }
    }
    assert_script_run("stap /usr/share/doc/packages/systemtap/examples/general/helloworld.stp | grep 'hello world'", 200);
    assert_script_run("stap-server condrestart | grep --line-buffered \"managed\"");
    assert_script_run("stap -v -e 'probe vfs.read {printf(\"read performed\\n\"); exit()}'");
}

1;
