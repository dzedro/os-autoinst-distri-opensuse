# SUSE's openQA tests
#
# Copyright 2018-2020 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Package: mdadm
# Summary: mdadm test, run script creating RAID 0, 1, 5, re-assembling and replacing faulty drive
# - Fetch mdadm.sh from datadir
# - Execute bash mdadm.sh |& tee mdadm.log
# - Upload mdadm.log
# Maintainer: Jozef Pupava <jpupava@suse.com>

use base 'consoletest';
use testapi;
use serial_terminal 'select_serial_terminal';
use version_utils 'is_sle';
use strict;
use warnings;
use power_action_utils qw(power_action);
use utils;

sub run {
    my ($self) = @_;
    select_serial_terminal;
    my $timeout = 360;

    if (is_sle('=15-sp4') && check_var('ARCH', 'aarch64')) {
        assert_script_run("sed -i 's/set timeout=-1/set timeout=2/' /boot/grub2/grub.cfg");
        zypper_call('ar -G -f http://download.suse.de/ibs/home:/colyli:/branches:/SUSE:/SLE-15-SP4:/Update/SUSE_SLE-15-SP4_Update/ mdadm_fix');
        zypper_call('rm kernel-default*');
        zypper_call('in -f --from mdadm_fix kernel-default');
        power_action 'reboot', textmode => 1;
        $self->wait_boot;
        select_serial_terminal;
    }

    assert_script_run 'wget ' . data_url('qam/mdadm.sh');
    if (is_sle('<15')) {
        if (script_run('bash mdadm.sh |& tee mdadm.log; if [ ${PIPESTATUS[0]} -ne 0 ]; then false; fi', $timeout)) {
            record_soft_failure 'bsc#1105628';
            assert_script_run 'bash mdadm.sh |& tee mdadm.log; if [ ${PIPESTATUS[0]} -ne 0 ]; then false; fi', $timeout;
        }
    }
    else {
        assert_script_run 'bash mdadm.sh |& tee mdadm.log; if [ ${PIPESTATUS[0]} -ne 0 ]; then false; fi', $timeout;
    }
    upload_logs 'mdadm.log';

    if (is_sle('=15-sp4') && check_var('ARCH', 'aarch64')) {
        zypper_call('rr mdadm_fix');
        zypper_call('up --allow-vendor-change kernel-default');
        power_action 'reboot', textmode => 1;
        $self->wait_boot;
        select_serial_terminal;
    }
}

sub post_fail_hook {
    upload_logs 'mdadm.log';
}

1;
