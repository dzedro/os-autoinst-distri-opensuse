# SUSE's openQA tests
#
# Copyright 2026 SUSE LLC
# SPDX-License-Identifier: FSFAP
#
# Package: stalld
# Summary: Install and validate the stalld package and service,
# and perform a basic upstream build and test check.
# Maintainer: QE Core <qe-core@suse.com>

use Mojo::Base 'consoletest';
use testapi;
use utils;
use serial_terminal 'select_serial_terminal';

sub run {
    select_serial_terminal;

    my $pkg = "stalld";
    my $repo = "https://gitlab.com/rt-linux-tools/stalld.git";
    my $srcdir = "/tmp/stalld-src";

    # Install stalld package
    zypper_call("in $pkg");
    assert_script_run("rpm -q $pkg");
    record_info("VERSION", script_output("stalld --version"));
    # Start service and verify service is active
    systemctl("enable --now stalld");
    systemctl("is-active stalld");
    validate_script_output("ps aux", sub { /stalld/ });

    # Configuration check
    if (script_run("test -f /etc/sysconfig/stalld") == 0) {
        assert_script_run("grep -v '^#' /etc/sysconfig/stalld || true");
        systemctl("restart stalld");
        systemctl("is-active stalld");
    }
    # Journal logs
    assert_script_run('journalctl -u stalld --no-pager | grep "Started Stall Monitor"');
    systemctl("stop stalld");
    # Running the upstream test suite
    # Install packages required for compiling stalld and running upstream tests
    zypper_call("in git make clang bpftool libbpf-devel llvm");
    assert_script_run("rm -rf $srcdir");
    assert_script_run("git clone $repo $srcdir", timeout => 120);
    if (script_run("test -d $srcdir") == 0) {
        assert_script_run("cd $srcdir");
        assert_script_run("make clean", timeout => 300);
        assert_script_run("make", timeout => 300);
        assert_script_run("make clean -C tests");
        assert_script_run("make -C tests");
        validate_script_output("./tests/run_tests.sh --test test_cpu_selection", sub { m/Test PASSED/ }, timeout => 120, proceed_on_failure => 1);
    }
}

sub cleanup {
    # Cleanup
    my $pkg = "stalld";
    zypper_call("rm -y $pkg");
    assert_script_run("test ! -d /tmp/stalld-src || rm -rf /tmp/stalld-src");
}

sub post_run_hook {
    cleanup();
}

sub post_fail_hook {
    systemctl("stop stalld");
    cleanup();
}
1;
