#!/usr/bin/perl

# HotRE (Hotmail Random Engine)
# author: Nathan Garretson
# August 24, 2007

# paths
our $path = '/hotre';
our $scriptname = 'creator';

# touch log files
open SQL, ">$path/$scriptname.sql";
close SQL;
open MSGS, ">$path/$scriptname.messages";
close MSGS;
open CMDS, ">$path/$scriptname.commands";
close CMDS;

# debug prints basic info, safe_mode test with no writing to database
our $debug = 1;
our $safe_mode = 0;

# database
use DBI;
require ("$path/hotre.common.pl");
our $dbh = &db_connect();
$dbh->{RaiseError} = 0;

# includes
require ("$path/hotre.db.pl");
require ("$path/hotre.email.create.body.pl");

# run time stamp
my ($y, $m, $d) = &getDate();
my ($h, $min, $sec) = &getTime();
our $now = "$y-$m-$d $h:$min:$sec";

# config
my $config = &get_hotre_config();

# main
for (my $i = 1; $i <= $config->{'email_bodies_to_create'}; $i++) {
	&build_email_body($config);
}
&db_close();
