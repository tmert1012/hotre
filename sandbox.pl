#!/usr/bin/perl

# HotRE (Hotmail Random Engine - Sandbox)
# author: Nathan Garretson
# August 24, 2007

# paths
our $path = '/hotre';
our $scriptname = 'sandbox';

# touch log files
open SQL, ">$path/$scriptname.sql";
close SQL;
open MSGS, ">$path/$scriptname.messages";
close MSGS;
open CMDS, ">$path/$scriptname.commands";
close CMDS;

# database
use DBI;
require ("$path/hotre.common.pl");
our $dbh = &db_connect();
$dbh->{RaiseError} = 0;

# includes
require ("$path/hotre.db.pl");
require ("$path/hotre.email.create.body.pl");
#require ("$path/hotre.email.send.func.pl");

# run time stamp
my ($y, $m, $d) = &getDate();
my ($h, $min, $sec) = &getTime();
our $now = "$y-$m-$d $h:$min:$sec";

# main
#open FILE, "<$path/spam_words";
#my @phrases = <FILE>;
#close FILE;
#my $inserts = "insert ignore into hotre_spam_phrases (phrase,add_date) values \n";
#foreach my $phrase (@phrases) {
#	chomp $phrase;
#	$inserts .= "('$phrase', now()),\n";
#}
#chomp $inserts;
#chop $inserts;
#&sql_execute($inserts);
#&db_close();
#exit;

my $kb = 20;
my $numWords = int(($kb * 1024) / (5+2.9));
print "words: $numWords\n";
#our $config = &get_hotre_config();
my %hsh = ('line_text' => '', 'wrapper_id' => 0, 'random_id' => 0, 'base_link_id' => 0, 'line_num' => 0, 'line_size' => 0);
#&get_random_random($config, \%hsh, $kb);
#&random_128(\%hsh, $numWords);
# get line size
#use bytes;
#my $bytes = length($hsh{'line_text'});
#$hsh{'line_size'} = $bytes if ($bytes);
#no bytes;
#print "random_id: $hsh{'random_id'}, expected: $kb k, actual: $hsh{'line_size'} b\n";
#print "$hsh{'line_text'}\n";
my $returns = &get_20_returns();
print $returns->[rand @{$returns}];


#my $working_domains = &prepare_working_domains(10);

#foreach my $iron (keys %{$working_domains}) {
#	print "$iron\n";
#	foreach my $dom (@{$working_domains->{$iron}}) {
#		print "\t$dom->{'domain_name'}, $dom->{'random_domain'}\n";
#	}
#	print "\n\n";
#}

&db_close();
