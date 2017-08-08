#!/usr/bin/perl

# HotRE (Hotmail Random Engine)
# author: Nathan Garretson
# August 24, 2007
# hotre.email.send.pl
# sends test emails to hotmail accnt(s)

# paths
our $path = '/hotre';
our $vqto_path = '/scripts';
our $scriptname = 'sender';

# includes
require ("$path/hotre.common.pl");
require ("$path/hotre.db.pl");
require ("$path/hotre.email.send.func.pl");

# run time stamp
my ($y, $m, $d) = &getDate();
my ($h, $min, $sec) = &getTime();
our $now = "$y-$m-$d $h:$min:$sec";

# database
use DBI;
$dbh = &db_connect();
$dbh->{RaiseError} = 0;

# test email
our $gmail_to = '';

# debug prints basic info, safe_mode test with no writing to database
our $debug = 1;
my $safe_mode = 0;

# BIG LOOP ############################################
# handle multiple instances of hotre.email.send.pl
my $run = &start_status();
while ($run) {

# touch log files
open SQL, ">$path/$scriptname.sql";
close SQL;
open MSGS, ">$path/$scriptname.messages";
close MSGS;
open CMDS, ">$path/$scriptname.commands";
close CMDS;

## MAIN #################
our $config = &get_hotre_config();
my $dhs = &get_hotre_dhs($config);
my $bodies = &untested_email_bodies();
my $camps = &prepare_hotre_campaigns();
my $html_wrappers = &prepare_hotre_html_wrappers();
# get inbox related success, dhs
my $successes = &get_hotre_test_success();
my $working_dhs = &prepare_working_hotre_dhs($successes);
my $working_domains = &prepare_working_domains($config->{'domains_to_send'});

# hotmail account method
my $hotmail_accts = '';
if ($config->{'send_to_oldest'}) {
	$hotmail_accts = &get_oldest_hotmail();
}
else {
	$hotmail_accts = &get_hotre_hotmail_accounts();
}

# require these to continue
unless ($config && $dhs && $camps && $html_wrappers && $hotmail_accts) {
	&write_file('errors', "$now: $scriptname: Script ending....");
	&end_status();
	&db_close();
	exit;
}

# for each email body, send to all hotmail dhs
foreach my $body (@{$bodies}) {

	my $lines = &get_hotre_email_body_lines($body->{'email_body_id'});

	# check if email body is a probe test
	my $probe = 0;
	foreach my $line (@{$lines}) {
		$probe = 1 if ($line->{'random_id'} == 1);
	}

	# (probe) send test body to each dh
	if ($probe && $ARGV[0] eq 'probe') {
		foreach my $dh (@{$dhs}) {
			my $camp = $camps->[rand @{$camps}];
			my $html_wrapper = $html_wrappers->{$body->{'html_wrapper_id'}};
			my $ip = &get_ips($dh, 'active') if ($config->{'use_dhip_rdns'});
			my $doms = &prep_get_domains($dh->{'dh_id'});
			&write_email_file($lines, $camp, $html_wrapper, $dh, $ip);
			&send_emails($config, $body->{'email_body_id'}, $camp, $dh, $hotmail_accts, $doms, $ip);
		}
	}
	# (test) regular email body, send to a random dh
	elsif (!$probe && $ARGV[0] ne 'probe') {
		my $camp = $camps->[rand @{$camps}];
		my $html_wrapper = $html_wrappers->{$body->{'html_wrapper_id'}};
		my $dh = $working_dhs->[rand @{$working_dhs}];
		#my $dh = $dhs->[rand @{$dhs}];
		my $ip = &get_ips($dh, 'active') if ($config->{'use_dhip_rdns'});
		my $doms = $working_domains->{$dh->{'dh_id'}};
		#my $doms = &prep_get_domains($dh->{'dh_id'});
		&write_email_file($lines, $camp, $html_wrapper, $dh, $ip);
		&send_emails($config, $body->{'email_body_id'}, $camp, $dh, $hotmail_accts, $doms, $ip);
	}

}
## END MAIN ##############

$run = &end_status();
}
######################### end BIG WHILE #################
&db_close();
