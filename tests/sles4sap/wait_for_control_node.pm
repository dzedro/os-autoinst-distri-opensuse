# SUSE's openQA tests
#
# Copyright 2021 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Summary: HANA SR - Kill database on site A
# Stop database on Site A by killing all processes.
# Do takeover do Site B
#
# Maintainer: QE-SAP <qe-sap@suse.de>

use base sles4sap;
use strict;
use warnings FATAL => 'all';
use diagnostics;
use testapi;
use lockapi;
use utils qw(script_retry systemctl);
use hacluster qw(get_cluster_name get_my_ip get_hostname);

sub run {
    my ($self) = @_;
    $self->select_serial_terminal;
    my $cluster_name = get_cluster_name;

    my $ip = get_my_ip;
    my $hostname = get_hostname;

    enter_cmd "expect -c '
set timeout -1
spawn ssh-copy-id 10.0.2.1
sleep 5
expect {
    \"Are you sure\" {
        send yes\\n; sleep 2; exp_continue
    }
    assword: {
        send $testapi::password\\n; exp_continue
    }
    # {
        interact
    }
}'";

    # reboot system after 5 seconds after system crash 'echo c > /proc/sysrq-trigger'
    assert_script_run 'sysctl kernel.panic=5';
    # set grub to finite value otherwise node will not boot after 'crash'
    assert_script_run 'sed -i \'s/timeout=-1/timeout=2/\' /boot/grub2/grub.cfg';
    assert_script_run 'grep timeout /boot/grub2/grub.cfg';
    # Add path to SAP exe to e.g. execute sapcontrol as root
    assert_script_run 'echo "export PATH=$PATH:/usr/sap/HA1/HDB00/exe/" >>/etc/bash.bashrc';
    $self->run_cmd(cmd => qq(echo "$ip $hostname" >>/etc/hosts), node => '10.0.2.1');
#    select_console('root-console');
    barrier_wait("BARRIER_REPLICATION_READY_$cluster_name");
    barrier_wait("BARRIER_REPLICATION_DONE_$cluster_name");
}

1;
