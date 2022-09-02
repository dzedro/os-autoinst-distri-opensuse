# SUSE's openQA tests
#
# Copyright 2016-2018 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Summary: Configure software watchdog
# Maintainer: QE-SAP <qe-sap@suse.de>, Loic Devulder <ldevulder@suse.com>

use base 'opensusebasetest';
use strict;
use warnings;
use testapi;
use hacluster;
use lockapi;
use utils;

sub run {
    my $module = 'softdog';

    # Configure the software watchdog
    assert_script_run "echo $module > /etc/modules-load.d/$module.conf";
    assert_script_run "echo 'options $module soft_margin=$softdog_timeout' > /etc/modprobe.d/99-$module.conf";
    systemctl 'restart systemd-modules-load.service';
    systemctl 'status systemd-modules-load.service';

    # Softdog module needs to be loaded
    # Note: 'grep -q' is not always working, because it can exits with RC=141 due to the pipe...
    assert_script_run "dmesg | grep -i $module";
    script_retry("lsmod | grep $module", delay => 5, retry => 3);

    # Keep the screenshot for this test
    save_screenshot;
}

1;
