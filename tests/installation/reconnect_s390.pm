# SUSE's openQA tests
#
# Copyright © 2009-2013 Bernhard M. Wiedemann
# Copyright © 2012-2016 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Reconnect s390-consoles after reboot
# Maintainer: Matthias Grießmeier <mgriessmeier@suse.de>

use base "installbasetest";

use testapi;

use strict;
use warnings;

sub run() {
    my $login_ready = check_var('VERSION', 'Tumbleweed') ? qr/Welcome to openSUSE Tumbleweed 20.*/ : qr/Welcome to SUSE Linux Enterprise Server.*\(s390x\)/;

    # different behaviour for z/VM and z/KVM
    if (check_var('BACKEND', 's390x')) {

        # kill serial ssh connection (if it exists)
        eval { console('iucvconn')->kill_ssh unless get_var('BOOT_EXISTING_S390', ''); };
        diag('ignoring already shut down console') if ($@);

        # 'wait_serial' implementation for x3270
        console('x3270')->expect_3270(
            output_delim => $login_ready,
            timeout      => 300
        );

        reset_consoles;

        # reconnect the ssh for serial grab
        select_console('iucvconn');
    }
    else {
        if (get_var('ENCRYPT')) {
            my $password = $testapi::password;
            my $svirt    = select_console('svirt');
            my $name     = $svirt->name;
            $svirt->suspend;
            type_string "export pty=`virsh dumpxml $name | grep \"console type=\" | sed \"s/'/ /g\" | awk '{ print \$5 }'`\n";
            type_string "echo \$pty\n";
            $svirt->resume;

            wait_serial("Please enter passphrase for disk.*", 100);
            type_string "echo $password > \$pty\n";
            wait_serial("Please enter passphrase for disk.*", 100);
            type_string "echo $password > \$pty\n";
        }
        wait_serial($login_ready, 300);
    }

    if (!check_var('DESKTOP', 'textmode')) {
        select_console('x11');
    }
}
1;
1;
