# SUSE's openQA tests
#
# Copyright 2017-2020 SUSE LLC
# SPDX-License-Identifier: FSFAP
#
# Summary: Functions for SAP tests

## no critic (RequireFilenameMatchesPackage);
package sles4sap_remote;
use base "opensusebasetest";
use strict;
use warnings;
use testapi;
use utils;
use hacluster qw(get_hostname ha_export_logs pre_run_hook save_state wait_until_resources_started);
use isotovideo;
use ipmi_backend_utils;
use x11utils qw(ensure_unlocked_desktop);
use power_action_utils qw(power_action);
use Utils::Backends;
use registration qw(add_suseconnect_product);
use version_utils qw(is_sle);
use utils qw(zypper_call);
use Utils::Systemd qw(systemctl);
use publiccloud::instance;
use Data::Dumper;

use constant {
    CRM_MON => 'crm_mon -R -r -n -N -1',
};

#sub qemu_instance {
#    my $class = shift;
#    my %instances = (
#        site_a => {
#            username => 'ha1adm',
#            instance_id => 'hana-node01',
#            public_ip => 'hana-node01'
#        },
#        site_b => {
#            username => 'ha1adm',
#            instance_id => 'hana-node02',
#            public_ip => 'hana-node02'
#        }
#    );
#    bless %instances, $class;
#    return \%instances;
#}
=head2 mess
sub qemu_instances {
    my ($self, $class) = @_;
    my $instances = {};
    $instances = (
        site_a => {
            username => 'ha1adm',
            instance_id => 'hana-node01',
            public_ip => 'hana-node01'
        },
        site_b => {
            username => 'ha1adm',
            instance_id => 'hana-node02',
            public_ip => 'hana-node02'
        }
    );
    return $instances, $class;
}
=cut

=head2 run_cmd
    run_cmd(cmd => 'command', [runas => 'user', timeout => 60]);
Runs a command C<cmd> via ssh in the given VM and log the output.
All commands are executed through C<sudo>.
If 'runas' defined, command will be executed as specified user,
otherwise it will be executed as root.
=cut

sub run_cmd {
    my ($self, %args) = @_;
    die('Argument <cmd> missing') unless $args{cmd};
    die('Argument <node> missing') unless $args{node};
    my $timeout = $args{timeout} // 90;
    my $node = $args{node};
    my $runas = defined($args{runas}) ? "su - $args{runas} -c \"$args{cmd}\"" : $args{cmd};
    my $cmd = "ssh $node '$runas'";
    my $out;

    if ($args{ignore_failure}) {
        $out = enter_cmd("timeout $timeout " . $cmd, timeout => $timeout);
        wait_serial('# ', undef, 0, no_regex => 1);
    } else {
        $out = script_output($cmd, timeout => $timeout);
    }
    return $out;
}

=head2 old
sub run_cmd {
    my ($self, %args) = @_;
    die('Argument <cmd> missing') unless ($args{cmd});
    my $timeout = bmwqemu::scale_timeout($args{timeout} // 60);
    my $title = $args{title} // $args{cmd};
    $title =~ s/[[:blank:]].+// unless defined $args{title};
    my $cmd = defined($args{'runas'}) ? "su - $args{'runas'} -c '$args{cmd}'" : "$args{cmd}";

    # Without cleaning up variables SSH commands get executed under wrong user
    delete($args{cmd});
    delete($args{title});
    delete($args{timeout});
    delete($args{runas});

    #my $out = $self->{my_instance}->run_ssh_command(cmd => "$cmd", timeout => $timeout, %args);
    my $out = $self->run_ssh_command(cmd => "$cmd", timeout => $timeout, %args);
    record_info("$title output - $self->{my_instance}->{instance_id}", $out) unless ($timeout == 0 or $args{quiet} or $args{rc_only});
    return $out;
}
=cut

=head2 get_replication_info
    get_replication_info();
    Parses hdbnsutil command output.
    Returns hash of found values converted to lowercase and replaces spaces to underscores.
=cut
sub get_replication_info {
    my ($self, %args) = @_;
    my $output_cmd = $self->run_cmd(cmd => "hdbnsutil -sr_state| grep -E :[^\^]", node => $args{node}, runas => 'ha1adm');

    # Create a hash from hdbnsutil output ,convert to lowercase with underscore instead of space.
    my %out = $output_cmd =~ /^?\s?([\/A-z\s]*\S+):\s(\S+)\n/g;
    %out = map { $_ =~ s/\s/_/g; lc $_} %out;
    return \%out;
}

=head2 parse_showattr
    parse_showattr([hostname => $hostname]);
    Parses  command output, returns list of hashes containing values for each host.
    If hostname defined, returns hash with values only for host specified.
=cut
sub get_hana_topology {
    my ($self, %args) = @_;
    my $hostname = $args{hostname};
    my @topology;
    my $cmd = "SAPHanaSR-showAttr | sed -E \"s/\\s+/ /g\" |grep -E \"^(\\S+\\s){13}\"";
    $cmd = $self->run_cmd(cmd => $cmd, node => $args{node});
    my @cmd_output = split(/\n/, $cmd);
    my @keys = split(/\s/, $cmd_output[0]);
    shift @cmd_output;

    while (my $entry = shift(@cmd_output)) {
        my %host_entry;
        my @host_values = split(/\s/, $entry);
        @host_entry{@keys} = @host_values;
        next if (defined($hostname) && $host_entry{Hosts} ne $hostname);
        return \%host_entry if (defined($hostname) && $host_entry{Hosts} eq $hostname);
        push(@topology, \%host_entry);
    }
    return \@topology;
}

=head2 is_hana_online
    is_hana_online([timeout => 120, wait_for_start => 'false']);
Check if hana DB is online. Define 'wait_for_start' to wait for DB to start.
=cut
sub is_hana_online {
    my ($self, %args) = @_;
    my $wait_for_start = defined($args{wait_for_start}) ? 1 : 0;
    my $timeout = bmwqemu::scale_timeout($args{timeout} // 120);
    my $start_time = time;
    my $db_status = 0;

    while ($db_status != 1) {
        $db_status = 1 if ($self->get_replication_info(node => $args{node})->{online} eq "true");
        last if $wait_for_start == 0;
        die("DB did not start within defined timeout: $timeout s") if (time - $start_time > $timeout);
        sleep 30;
    }
    return $db_status;
}

=head2 is_hana_resource_running
    is_hana_resource_running([timeout => 60]);
Checks if resource msl_SAPHana_HA1_HDB00 is running on given node.
=cut
sub is_hana_resource_running {
    my ($self, %args) = @_;
    my $resource_output = $self->run_cmd(cmd => 'crm resource status msl_SAPHana_HA1_HDB00', node => $args{node});
    my $node_status = grep /is running on: $args{node}/, $resource_output;
    record_info("Node status", "$args{node}: $node_status");
    return $node_status;
}

=head2 stop_hana

Stops hana database using method specified and waits for resources being stopped.
Default method is 'stop = HDB stop'
Methods available:
  stop = HDB stop
  kill = HDB kill -9
  crash = proc-systrigger

=cut

sub stop_hana {
    my ($self, %args) = @_;
    my $method = $args{method} // 'stop';
    my $timeout = bmwqemu::scale_timeout($args{timeout} // 300);
    my %commands = (
        'stop'  => 'HDB stop',
        'kill'  => 'HDB kill-9',
        'crash' => '(echo c > /proc/sysrq-trigger &)'
    );
    my $cmd = $commands{$method};

    # wait for data sync before stopping DB
    $self->wait_for_sync(node => $args{node});

    record_info('Stopping HANA DB', "Running '$cmd' on $args{node}");
    if ($method eq 'crash') {
        # sync all fs, otherwise unsynced data will be lost e.g. authorized ssh keys
        $self->run_cmd(cmd => 'echo s > /proc/sysrq-trigger', node => $args{node});
        $self->run_cmd(cmd => $cmd, node => $args{node}, timeout => 60, ignore_failure => $args{ignore_failure});
        assert_script_run("until nc -zvw30 $args{node} 22; do sleep 10; done", 500);
        script_run("until timeout 30 ssh $args{node} ss -apn|grep '\@pacemakerd\@'; do sleep 10; done", die_on_timeout => 0, timeout => 500);
        sleep 10;
        if (script_run("ssh $args{node} systemctl status pacemaker", die_on_timeout => 0) != 0) {
            script_run("ssh $args{node} systemctl start pacemaker", die_on_timeout => 0);
            sleep 10;
        }
        # wait until pacemaker is ready
        script_run("until timeout 15 ssh $args{node} crm status;do sleep 10; done", die_on_timeout => 0);
    }
    else {
        $self->run_cmd(cmd => $cmd, node => $args{node}, runas => $args{runas});
    }

    # Wait for resource to stop
    my $start_time = time;
    # expecting stopped node returning fail, resource not running
    while ($self->is_hana_resource_running(node => $args{node}) == 1) {
        if (time - $start_time > $timeout) {
            record_info('Cluster status', $self->run_cmd(cmd => CRM_MON, node => $args{node}));
            record_info('Replication status', $self->run_cmd(cmd => 'SAPHanaSR-showAttr', node => $args{node}));
            die("DB stop operation timed out ($timeout sec).");
        }
        else {
            sleep 30;
        }
    }
}

=head2 check_takeover
    check_takeover();

Checks takeover status and waits for finish until successful or reaches timeout.
=cut

sub check_takeover {
    my ($self, %args) = @_;
    my $takeover_complete = 0;
    my $fenced_hana_status = $self->is_hana_online(node => $args{node});
    die("Fenced database '$args{node}' is not offline") if ($fenced_hana_status == 1);

    record_info('Takeover check', 'Running check_takeover');
    while ($takeover_complete == 0) {
        my $topology = $self->get_hana_topology(node => $args{node});

        for my $entry (@$topology) {
            my %host_entry = %$entry;
            my $sync_state = $host_entry{sync_state};
            my $takeover_host = $host_entry{Hosts};

            if ($takeover_host ne $args{node} && $sync_state eq "PRIM") {
                $takeover_complete = 1;
                record_info('Takeover status:', "Takeover complete to node '$takeover_host'");
                last;
            }
            else {
                sleep 30;
            }
        }
    }
}

=head2 enable_replication
    enable_replication();
=cut
sub enable_replication {
    my ($self, %args) = @_;
    #my $hostname = $self->{my_instance}->{instance_id};
#    my $topology_out = get_hana_topology(hostname => $hostname);
#    my %topology = get_hana_topology(hostname => $hostname);
    #my $topology_out = $self->get_hana_topology(node => $args{node});
    #my %topology = %$topology_out;

#    record_info("Topology", Dumper($topology_out));

    record_info('Replication', "Register (PROMOTE) new primary (DEMOTED) node $args{node}");
    my $cmd = "hdbnsutil -sr_register " .
#    "--name=$topology{Hosts} " .
    "--name=$args{node} " .
#    "--remoteHost=$topology{remoteHost} " .
    "--remoteHost=$args{second_node} " .
    "--remoteInstance=00 " .
#    "--replicationMode=$topology{srmode} " .
    "--replicationMode=sync " .
#    "--operationMode=$topology{op_mode}";
    "--operationMode=logreplay";

    record_info('Register cmd', $cmd);
    $self->run_cmd(cmd => $cmd, node => $args{node}, runas => 'ha1adm');

}

=head2 wait_for_sync
    wait_for_sync();
    Wait for replica site to sync data with primary.
    Checks "SAPHanaSR-showAttr" output and ensures replica site has "sync_state" "SOK".
=cut

sub wait_for_sync {
    my ($self, %args) = @_;
    my $timeout = bmwqemu::scale_timeout($args{timeout} // 600);
    my $sok = 0;
    record_info("Sync wait", "Waiting for data sync between nodes");

    # Check sync status periodically until ok or timeout
    my $start_time = time;

    while ($sok == 0) {
#        my $topology = $self->get_hana_topology(node => $args{node});

#        for my $entry (@$topology) {
#            my %entry = %$entry;
#            $sok = 1 if $entry{sync_state} eq "SOK";
#            last if $sok == 1;
#        }

        my $cmd = 'SAPHanaSR-showAttr|grep -E "sync | logreplay"';
        $cmd = $self->run_cmd(cmd => $cmd, node => $args{node});
        last unless $cmd =~ /SFAIL/;

        if (time - $start_time > $timeout) {
            record_info("Cluster status", $self->run_cmd(cmd => CRM_MON, node => $args{node}));
            record_info("Sync FAIL", "Host replication status: " . $self->run_cmd(cmd=>'SAPHanaSR-showAttr', node => $args{node}));
            die("Replication SYNC did not finish within defined timeout. ($timeout sec).");
        }
        else {
            sleep 30;
        }
    }
    record_info("Sync OK", $self->run_cmd(cmd => 'SAPHanaSR-showAttr', node => $args{node}));
}

=head2 cleanup_resource
    cleanup_resource([timeout => 60]);
Cleanup rsource 'msl_SAPHana_HA1_HDB00', wait for DB start automaticlly.
=cut

sub cleanup_resource {
    my ($self, %args) = @_;
    my $timeout = bmwqemu::scale_timeout($args{timeout} // 300);
    my $cmd = 'crm resource refresh msl_SAPHana_HA1_HDB00';

    record_info('cleanup_resource', "$cmd");
    $self->run_cmd(cmd => $cmd, node => $args{node});

    # Wait for resource to start
    my $start_time = time;
    while ($self->is_hana_resource_running(node => $args{node}) == 0) {
        if (time - $start_time > $timeout) {
            record_info("Cluster status", $self->run_cmd(cmd => CRM_MON, node => $args{node}));
            record_soft_failure("Resource did not start within defined timeout. ($timeout sec).");
            last;
        }
        else {
            sleep 30;
        }
    }
}

sub check_sapcontrol {
    my ($self, %args) = @_;
    die('Argument <function> missing') unless $args{function};
    my $timeout = bmwqemu::scale_timeout($args{timeout} // 300);
    my $sapadm = $args{runas} // lc(get_var('INSTANCE_SID') . 'adm');
    my $instance = $args{instance} // get_var('INSTANCE_ID');
    my $cmd = qq(sapcontrol -nr $instance -function $args{function});
    #my $sapcontrol = qq(sapcontrol -nr $instance -function $args{function});
    #my $runas = $sapadm ne 'root' ? qq(su - $sapadm -c "$sapcontrol") : $sapcontrol;
    #my $cmd = "ssh $args{node} '$runas'";
    my $output;

    record_info('check_sapcontrol', "$cmd");
    my $start_time = time;
    until ($self->run_cmd(cmd => $cmd, node => $args{node}, runas => $sapadm, ignore_failure => 1)) {
        if (time - $start_time > $timeout) {
            record_info('SAPHanaSR-showAttr', $self->run_cmd(cmd => 'SAPHanaSR-showAttr', node => $args{node}));
            die("sapcontrol output didn't match within timeout ($timeout sec).");
        }
        else {
            sleep 30;
        }
    }

    return $output;
}

sub test_flags {
    return {fatal => 1};
}

1;
