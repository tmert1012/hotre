# HotRE (Hotmail Random Engine)
# author: Nathan Garretson
# August 24, 2007
# hotre.email.create.body.pl
# create email body, put in database

require ("$path/hotre.random.pl");

# build email body, mix randoms and base lines together
sub build_email_body {
	my $config = shift;
	
	my $randoms = &get_randoms($config);
	my $base = &get_base_email_body();
	my $ebid = &new_hotre_email_body();
	
	my $start = 0;
	my $limit = (@{$base}+@{$randoms}) - 1;
	my @choices = (0,1);
	my @lines = ();
	
	# put lines together in new list
	while ($start <= $limit) {
		
		my $choice = $choices[rand @choices];
		if ($choice) {
			my $line = shift(@{$randoms});
			if ($line) {
				push(@lines, $line);
				$start++;
			}
		}
		my $line = shift(@{$base});
		if ($line) {
			push(@lines, $line);
			$start++;
		}
	}
	
	# assign line nums and email body id, add up message size
	my %email_body = ('email_body_id' => $ebid, 'message_size' => 0);
	my $i = 1;
	foreach my $line (@lines) {
		$line->{'line_num'} = $i;
		$line->{'email_body_id'} = $ebid;
		$email_body{'message_size'} += $line->{'line_size'};
		$i++;
	}
	
	# convert bytes to KB for hotre_email_bodies
	my $kb = int ($email_body{'message_size'} / 1024) if ($email_body{'message_size'});
	if ($kb > 1) {
		$email_body{'message_size'} = $kb;
	}
	else {
		$email_body{'message_size'} = 1;
	}
	
	# save em to the database
	&new_hotre_email_body_lines(\@lines);
	&update_hotre_email_body(\%email_body);
}

# basic lines required for email
sub get_base_email_body {

	my $links = &get_hotre_base_links();
	my @base = ();
	
	foreach my $link (@{$links}) {
		my %hsh = ('line_text' => $link->{'base_link'}, 'wrapper_id' => 0, 'random_id' => 0, 'base_link_id' => $link->{'base_link_id'}, 'line_num' => 0, 'line_size' => 100);
		push @base,  \%hsh;
	}

	return \@base;
}

# simulate build email body, instead just returns array instead of saving it to database
sub test_build_email_body {
	my $config = shift;
	
	my $randoms = &get_randoms($config);
	my $base = &get_base_email_body();
	my $ebid = 'TESTID';
	
	my $start = 0;
	my $limit = (@{$base}+@{$randoms}) - 1;
	my @choices = (0,1);
	my @lines = ();
	
	# put lines together in new list
	while ($start <= $limit) {
		
		my $choice = $choices[rand @choices];
		if ($choice) {
			my $line = shift(@{$randoms});
			if ($line) {
				push(@lines, $line);
				$start++;
			}
		}
		my $line = shift(@{$base});
		if ($line) {
			push(@lines, $line);
			$start++;
		}
	}
	
	# assign line nums and email body id
	my $i = 1;
	foreach my $line (@lines) {
		$line->{'line_num'} = $i;
		$line->{'email_body_id'} = $ebid;
		$i++;
	}
	
	# save em to the database
	return \@lines;
}

return 1;
