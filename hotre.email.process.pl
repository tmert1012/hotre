#!/usr/bin/perl

# HotRE (Hotmail Random Engine)
# author: Nathan Garretson
# August 24, 2007
# hotre.email.process.pl
# get all emails from hotmail account(s), process them

# paths
our $path = '/hotre';
our $scriptname = 'processor';

# debug prints basic info, safe_mode test with no writing to database
our $debug = 1;
my $safe_mode = 0;

# includes
require ("$path/hotre.common.pl");
require ("$path/hotre.db.pl");

# run time stamp
my ($y, $m, $d) = &getDate();
my ($h, $min, $sec) = &getTime();
our $now = "$y-$m-$d $h:$min:$sec";

# touch log files
open SQL, ">$path/$scriptname.sql";
close SQL;
open MSGS, ">$path/$scriptname.messages";
close MSGS;
open CMDS, ">$path/$scriptname.commands";
close CMDS;

# database
use DBI;
$dbh = &db_connect();
$dbh->{RaiseError} = 0;

# mbox/email modules
use Email::Folder::Mbox;
use Email::Simple;

## main
my $accts = &get_hotre_hotmail_accounts();
my $downloaded = 0;
foreach my $acct (@{$accts}) {
	&create_config('inbox', $acct);
	$downloaded = &getLive();
	&process_emails('inbox') if ($downloaded);

	&create_config('junk', $acct);
	$downloaded = &getLive();
	&process_emails('junk') if ($downloaded);
}
&db_close();
## end main

# run getlive
sub create_config {
	my ($folder, $acct) = @_;
	my ($user,$dom) = split(/\@/, $acct->{'email'});

	unlink("$path/GetLive/getlive.conf");
	unlink("$path/GetLive/$folder");
	`/bin/touch $path/GetLive/$folder`;

my $conf = qq[# getlive config for hotre tests
UserName = $user
Password = $acct->{'pass'}
Domain = $dom
Processor = /bin/cat >> $path/GetLive/$folder
FetchOnlyUnread = yes
RetryLimit = 2
Folder = $folder
MarkRead = Yes
];
	open(FILE, ">$path/GetLive/getlive.conf");
	print FILE $conf;
	close(FILE);
}

# download email box
sub getLive {
	my $cmd = "/usr/bin/perl $path/GetLive/GetLive.pl --config-file $path/GetLive/getlive.conf";
	my @error = split(/\n/, `$cmd`) unless ($safe_mode);
	foreach my $err (@error) {
		if ($err =~ /getlive\s+died/iog) {
			chomp $err;
			&write_file('getLive.errors', "$now: getLive(): $err");
			return 0;
		}
	}
	return 1;
}

# process email
sub process_emails {
	my $folder = shift;

	# each message in log (mbox)
	my $box = Email::Folder::Mbox->new("$path/GetLive/$folder");
	while ( my $full_email = $box->next_message ) {
		# parts of each message
		my $email = Email::Simple->new($full_email);
		my %parts = (
			'message_id' => $email->header('Message-Id'),
			'received' => $email->header("Received"),
		);

		# parse out parts of message
		&parse_ip(\%parts);
		&parse_email_test_id(\%parts);
		if ($parts{'ip_address'} && $parts{'email_test_id'}) {
			if ($folder eq 'junk') { $parts{'success'} = 1; }
			elsif ($folder eq 'inbox') { $parts{'success'} = 2; }
			my @arr = ();
			push @arr, \%parts;
			&hotre_email_test_success(\@arr);
		}

	}
	unlink("$path/GetLive/$folder");
	`/bin/touch $path/GetLive/$folder`;
}

sub parse_email_test_id {
	my $data = shift;

	if ($data->{'message_id'} =~ /^\<(\d+)[a-zA-Z]\w+\@\w+\.\w+\.com\>/) {
		$data->{'email_test_id'} = $1;
		return 1;
	}
	&write_file('errors', "$now: parse_email_test_id(): Could not parse email_test_id, skipping msg: $data->{'message_id'}");
	return 0;
}

sub parse_ip {
	my $data = shift;

	if ($data->{'received'} =~ /\(\[(\d+\.\d+\.\d+\.\d+)\]\)/iogm) {
		$data->{'ip_address'} = $1;
		return 1;
	}
	&write_file('errors', "$now: parse_ip(): Could not parse ip_address, skipping msg: $data->{'received'}");
	return 0;
}

sub parse_ip_old {
	my $data = shift;
	my $success = 0;

	# ip
	foreach my $received (@{$data->{'received'}}) {
		if ($received =~ /10\.16\./iog) {
			&write_file('errors', "$now: parse_ip(): Dropped IP address: $received");
			$success = 1;
		}
		elsif ($received =~ /\(\[(\d+\.\d+\.\d+\.\d+)\]\)/iog) {
			$data->{'ip_address'} = $1;
			$success = 1;
		}
	}

	unless ($success) {
		foreach my $received (@{$data->{'received'}}) {
			&write_file('errors', "$now: parse_ip(): Could not get IP address: $received");
		}
	}
}
