#!/usr/bin/perl

# HotRE (Hotmail Random Engine)
# author: Nathan Garretson
# September 26, 2007
# hotre.iron.log.process.pl
# parse out stuff in ironport logs

# paths
our $path = '/hotre';
my $logPath = '/logs';
our $scriptname = 'log.process';

# includes
require ("$path/hotre.common.pl");
require ("$path/hotre.db.pl");

# run time stamp
my ($y, $m, $d) = &getDate();
my ($h, $min, $sec) = &getTime();
our $now = "$y-$m-$d $h:$min:$sec";

# database
use DBI;
$dbh = &db_connect();
$dbh->{RaiseError} = 0;

# debug prints basic info, safe_mode test with no writing to database
our $debug = 1;
my $safe_mode = 0;

# touch log files
open SQL, ">$path/$scriptname.sql";
close SQL;
open MSGS, ">$path/$scriptname.messages";
close MSGS;
open CMDS, ">$path/$scriptname.commands";
close CMDS;

## MAIN #################
our $config = &get_hotre_config();
my $hotmail_accts = &get_hotre_hotmail_accounts();
my $emailStr = &create_regex($hotmail_accts);
&db_close();

open OUT, ">>$path/ironLogs/ironport.$y$m$d.log";

my $logs = &get_logs();
foreach my $log (@{$logs}) {
	open LOG, "$logPath/$log";
	&write_file('messages', "processing $log...");

	# PARSE LINE ########
	while (<LOG>) {
		my $line = $_;
		if ($line =~ /$emailStr/) {
			print OUT "$line\n";
		}
	}
	close (LOG);
}

close (OUT);
## END MAIN ##############

# FUNCTIONS
sub create_regex {
	my $accts = shift;
	my $str = '';
	foreach my $acct (@{$accts}) {
		my $email = $acct->{'email'};
		$email =~ s/\@/\\\@/g;
		$email =~ s/\./\\\./g;
		$str .= "$email|";
	}
	chop $str;

	return $str;
}

sub get_logs {
	my ($y, $m, $d) = &getDate(300);
	my ($h, $min, $sec) = &getTime(300);

	$m = "0$m" if (length($m) == 1);
	$d = "0$d" if (length($d) == 1);
	$h = "0$h" if (length($h) == 1);
	$min = "0$min" if (length($min) == 1);
	$sec = "0$sec" if (length($sec) == 1);

	my $fivedate = "$y$m$d$h$min$sec";

	opendir(LOGDIR, $logPath) || die &write_file('errors', "$now: get_logs(): Unable to open directory: $logPath");
	my @dirListing = grep(/^iron\d+\.bounces\.\@/, readdir(LOGDIR));
	closedir(LOGDIR);

	my @outGoing = ();
	foreach my $log (@dirListing) {
		$log =~ /\.\@(\d+T\d+)\.s$/;
		my $tlog = $1;
		$tlog =~ s/T//g;
		if (int($tlog) >= int($fivedate)) {
			push @outGoing, $log;
		}
	}

	return \@outGoing;
}
