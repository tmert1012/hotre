# HotRE (Hotmail Random Engine)
# author: Nathan Garretson
# August 24, 2007
# hotre.common.pl
# common functions for all to enjoy

# function for writing to log files
sub write_file {
	my $type = shift;
	my $msg = shift;
	open FILE, ">>$path/$scriptname.$type";
	print FILE "$msg\n";
	close FILE;
}

# script control
sub start_status {
	if ($debug) { &write_file('messages', 'inside start_status()...'); }
	my $status = &get_status();
	
	if ($status eq 'not running') {
		&write_status('in process');
		return 1;
	}
	elsif ($status eq 'in process') {
		return 0;
	}
	elsif ($status eq 'in queue') {
		return 0;
	}
	else {
		&write_file('errors', "$now: start_status(): Unknown status: $status");
		&write_status('not running');
		return 0;
	}
}

# script control
sub end_status {
	if ($debug) { &write_file('messages', 'inside end_status()...'); }
	my $status = &get_status();
	
	if ($status eq 'not running') {
		return 0;
	}
	elsif ($status eq 'in process') {
		&write_status('not running');
		return 0;
	}
	elsif ($status eq 'in queue') {
		&write_status('in process');
		return 1;
	}
	else {
		&write_file('errors', "$now: end_status(): Unknown status: $status");
		&write_status('not running');
		return 0;
	}
}

# write status of script
sub write_status {
	if ($debug) { &write_file('messages', 'inside write_status()...'); }
	my $param = shift;
	open FILE, ">$path/$scriptname.status";
	print FILE $param;
	close FILE;
}

# get the script status
sub get_status {
	if ($debug) { &write_file('messages', 'inside get_status()...'); }
	
	if (-r "$path/$scriptname.status") {
		open FILE, "$path/$scriptname.status";
		@lines = <FILE>;
		chomp $lines[0];
		close FILE;
		return $lines[0];
	}
	return 'not running';
}

# no return
sub sql_execute {
	my $data = shift;
	if ($debug) { &write_file('messages', 'inside sql_execute()...'); }
	my $error = 0;
	
	# write to file
	&write_file('sql', $data);
	$dbh->{'mysql_error'} = '';
	my $sth0 = '';
	
	eval { $sth0 = $dbh->prepare($data); };
	eval { $sth0->execute if (!$safe_mode); };
	
	if ($dbh->{'mysql_error'}) {
		&write_file('errors', "$now: sql_execute(): SQL Bad. Check last SQL statement in sql file.");
		&db_close();
		exit 0;
	}

}

# returns array of hashes
sub sql_query {
	my $data = shift;
	if ($debug) { &write_file('messages', 'inside sql_query()...'); }
	
	&write_file('sql', $data);
	$dbh->{'mysql_error'} = '';
	my $sth0 = '';
	
	eval { $sth0 = $dbh->prepare($data); };
	eval { $sth0->execute if (!$safe_mode); };
	
	if (!$dbh->{'mysql_error'}) {
		 return $sth0->fetchall_arrayref({});
	}
	else {
		&write_file('errors', "$now: sql_query(): SQL Bad. Check last SQL statement in sql file.");
		&db_close();
		exit 0;
	}
}

# get the current date - seconds
sub getDate {
	my (undef, undef,$hour,$mday,$mon,$year,undef,undef,undef) = localtime(time - $_[0]);
	$year += 1900;
	$mon++;
	my $m = sprintf("%2.2d",$mon);
	my $d = sprintf("%2.2d",$mday);
	my $h = sprintf("%2.2d",$hour);
	return($year, $m, $d, $h);
}

# get the current time - seconds
sub getTime {
	my ($sec,$min,$hour,undef,undef,undef,undef,undef,undef) = localtime(time - $_[0]);
	my $s = sprintf("%2.2d",$sec);
	my $m = sprintf("%2.2d",$min);
	my $h = sprintf("%2.2d",$hour);
	return($h, $m, $s);
}

# open db connection
sub db_connect {
	my $DB_USER = '';
	my $DB_PASS = '';
	my $DB_HOST = '';
	my $DB_NAME = '';
	return DBI->connect("DBI:mysql:database=$DB_NAME;host=$DB_HOST",
			$DB_USER,$DB_PASS, { RaiseError => 1, AutoCommit => 1 });
}

# close db connection
sub db_close {
	$dbh->disconnect();
    return '';
}

return 1;
