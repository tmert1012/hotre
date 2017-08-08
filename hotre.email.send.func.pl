#!/usr/bin/perl

# HotRE (Hotmail Random Engine)
# author: Nathan Garretson
# October 3, 2007
# hotre.email.send.func.pl
# functions for the sender

# get things together to test send emails
sub send_emails {
	my ($config,$ebid,$camp,$dh, $hotmail_accts, $doms, $ip) = @_;

	foreach my $dom (@{$doms}) {
		my $hotmail_acct = $hotmail_accts->[rand @{$hotmail_accts}];
		my $test_id = &prep_new_hotre_email_test($dh, $dom, $camp, $ebid, $hotmail_acct->{'hotmail_account_id'});
		&write_addr_file($dh, $dom, $camp, $test_id, $hotmail_acct);
		&prep_update_hotre_email_test($camp, $test_id);
	}
	my $dom = $doms->[rand @{$doms}];
	&vqtolist($dh, $dom, $camp, $ip);
	&update_hotmail_account($hotmail_acct) if ($config->{'send_to_oldest'});
}

# preper hotre email test update
sub prep_update_hotre_email_test {
	my ($camp,$test_id) = @_;

	my %test = (
		'email_test_id' => $test_id,
		'subject' => $camp->{'random_subject'},
		'from_name' => $camp->{'random_from'},
	);
	my @arr = ();
	push @arr, \%test;
	return &update_hotre_email_test(\@arr);
}

# prepare hotre email test for insertion
sub prep_new_hotre_email_test {
	my ($dh,$dom,$camp,$ebid,$hmaid) = @_;

	$hmaid = '' unless ($config->{'send_to_hotmail'});

	my %test = (
		'email_body_id' => $ebid,
		'ironport_id' => $dh->{'ironport_id'},
		'campaign_id' => $camp->{'campaign_id'},
		'domain_id' => $dom->{'domain_id'},
		'hotmail_account_id' => $hmaid,
	);

	return &new_hotre_email_test(\%test);
}

# get campaigns and prepare links
sub prepare_hotre_campaigns {

	my $before = &get_hotre_campaigns();
	my @after = ();

	foreach my $camp (@{$before}) {
		# map type
		if ($camp->{'email_body'} =~ /\<map/iogs) {
			&parse_map_email_body($camp);
			&write_file('errors', "$now: prepare_hotre_campaign(map): Could not parse IMG_LINK_1. campaign_id: $camp->{'campaign_id'}.") unless ($camp->{'IMG_LINK_1'});
			&write_file('errors', "$now: prepare_hotre_campaign(map): Could not parse IMG_LINK_3. campaign_id: $camp->{'campaign_id'}.") unless ($camp->{'IMG_LINK_3'} || $camp->{'UNSUB_IMG'});
			&write_file('errors', "$now: prepare_hotre_campaign(map): Could not parse UNSUB_IMG. campaign_id: $camp->{'campaign_id'}.") unless ($camp->{'IMG_LINK_3'} || $camp->{'UNSUB_IMG'});
		}
		# regular type
		else {
			&parse_regular_email_body($camp);
			&write_file('errors', "$now: prepare_hotre_campaign(regular): Could not parse IMG_LINK_1. campaign_id: $camp->{'campaign_id'}.") unless ($camp->{'IMG_LINK_1'});
			&write_file('errors', "$now: prepare_hotre_campaign(regular): Could not parse IMG_LINK_3. campaign_id: $camp->{'campaign_id'}.") unless ($camp->{'IMG_LINK_3'} || $camp->{'UNSUB_IMG'});
			&write_file('errors', "$now: prepare_hotre_campaign(regular): Could not parse UNSUB_IMG. campaign_id: $camp->{'campaign_id'}.") unless ($camp->{'IMG_LINK_3'} || $camp->{'UNSUB_IMG'});
		}

		if ($camp->{'IMG_LINK_1'} && ($camp->{'UNSUB_IMG'} || $camp->{'IMG_LINK_3'})) {
			push @after, $camp;
		}
	}

	return \@after;
}

# parse images and links out of the regular style email body
sub parse_regular_email_body {
	my $camp = shift;

	if ($camp->{'email_body'} =~ /RANDLET(\d\/.+)\?EID_CAMPID/ios) {
		$camp->{'IMG_LINK_1'} = "<a href=\"CLICK1\"><img src=\"http://IMAGE/RANDLET$1\?EID_CAMPID\" border=\"0\"\></a>";
	}
	if ($camp->{'email_body'} =~ /(<a href=\"CLICK3\"><img src=\"http:\/\/IMAGE\/RANDLET\d\/\w+\"\s+border=\"0\">)/ios) {
		$camp->{'IMG_LINK_3'} = "$1</a>";
	}
	if ($camp->{'email_body'} =~ /(<img src=\"http:\/\/IMAGE\/RANDLET\d\/\w+\"\s+border=\"0\">)\s?$/iosm) {
		$camp->{'UNSUB_IMG'} = $1;
	}
}

# parse images and links out of map style email body
sub parse_map_email_body {
	my $camp = shift;

	if ($camp->{'email_body'} =~ /(<img.+EID_CAMPID.+>).+<map/ios) {
		$camp->{'IMG_LINK_1'} = $1;
	}
	if ($camp->{'email_body'} =~ /(<map.+<\/map>)/ios) {
		$camp->{'IMG_LINK_3'} = $1;
	}
	if ($camp->{'email_body'} =~ /<\/map>.+(<img.+>)/ios) {
		$camp->{'UNSUB_IMG'} = $1;
	}
}

# call vqtolist
sub vqtolist {
	my ($dh,$dom,$camp, $ip) = @_;

	# check to see if vqtolist exists
	unless (-e "$vqto_path/vqtolist$dh->{'ironport_id'}") {
		my $cmd = "cp /bin/vqtolist$dh->{'ironport_id'} $vqto_path";
		my @junk = split(/\n/, `$cmd`) unless ($safe_mode);
		&write_file('commands', $cmd);
	}

	# send emails (per ironport)
	my $addr_file = "$scriptname.iron$dh->{'ironport_id'}.dh$dh->{'dh_id'}.addr";
	my $chars = $ip->{'rdns'};
	$chars = lc(rand_char('letters',3)) unless ($ip->{'rdns'});

	# return path domain name
	my $return_path_domain = $dom->{'domain_name'};
	$return_path_domain = $dom->{'random_domain'} if ($config->{'return_path_random_domain'} && $dom->{'random_domain'});

	my $cmd = "$vqto_path/vqtolist$dh->{'ironport_id'} -t $path/$addr_file -b $path/hotre.email -r $camp->{'random_from'}\@$chars.$return_path_domain -l $path/$scriptname.log";
	&write_file('commands', $cmd);
	my @error = split(/\n/, `$cmd`) unless ($safe_mode);

	if ($error[0]) {
		&write_file('errors', "$now: main(): Email send for ironport $dh->{'ironport_id'} returned: $error[0]");
		unlink("$path/$scriptname.log");
		unlink("$path/$addr_file");
		return 0;
	}
	unlink("$path/$scriptname.log");
	unlink("$path/$addr_file");
	return 1;
}

# create addr file
sub write_addr_file {
	my ($dh,$dom,$camp,$test_id,$acct) = @_;

	# create addr file
	my $addr_file = "$scriptname.iron$dh->{'ironport_id'}.dh$dh->{'dh_id'}.addr";
	eval { open ADDR, ">>$path/$addr_file"; };
	if ($@) {
		&write_file('errors', "$now: write_addr_file(): Create addr file failed for ironport $dh->{'ironport_id'}.");
		return 0;
	}

	# pick subject and from
	$camp->{'random_from'} = $camp->{'from_name'};
	if ($camp->{'random_from'} =~ /\|/o) {
		my @froms = split(/\|/, $camp->{'random_from'});
		$camp->{'random_from'} = $froms[rand @froms];
	}
	my $nospace = $camp->{'random_from'};
	$camp->{'random_from'} =~ s/\s//iog;

	$camp->{'random_subject'} = $camp->{'email_subject'};
	if ($camp->{'random_subject'} =~ /\|/o) {
		my @subs = split(/\|/, $camp->{'random_subject'});
		$camp->{'random_subject'} = $subs[rand @subs];
	}

	# sub out FNAME in subject
	my ($user,$dn) = split(/\@/, $acct->{'email'});
	if ($camp->{'random_subject'} =~ /FNAME/iog) {
		$camp->{'random_subject'} =~ s/FNAME/$user/g;
	}

	# remove some weirdo char
	$camp->{'random_subject'} =~ s/&#39;/'/g;

	# fix message id
	my $message_id = &padTestID($test_id);

	print ADDR "$acct->{'email'}|$dh->{'ironport_id'}|$dom->{'domain_name'}|$camp->{'campaign_id'}|$camp->{'random_subject'}|$camp->{'random_from'}|1|$message_id|$nospace\n" if ($config->{'send_to_hotmail'});
	print ADDR "$gmail_to|$dh->{'ironport_id'}|$dom->{'domain_name'}|$camp->{'campaign_id'}|$camp->{'random_subject'}|$camp->{'random_from'}|2|$message_id|$nospace\n" if ($config->{'send_to_gmail'});
	close ADDR;
	return 1;
}

sub padTestID {
	my $id = shift;
	my $len = length($id);
	my $char = lc(rand_char('letters',1));
	my $pad = lc(rand_char('allletters',(31-$len)));
	return "$id$char$pad";
}

# creates .email file. copied create_email_body from deploy.pl to ensure similarity between test and real emails
sub write_email_file {
	my ($lines,$camp,$html_wrapper,$dh,$ip) = @_;

	# prepare creative
	my $creative = '';
	foreach my $line (@{$lines}) {
		$creative .= $line->{'line_text'};
	}
	$creative = "$html_wrapper->{'header_text'}\n$creative\n$html_wrapper->{'footer_text'}\n";

	# put in links from campaign_list's email_body
	$creative =~ s/IMG_LINK_1/<br>$camp->{'IMG_LINK_1'}<br>/g;
	$creative =~ s/IMG_LINK_3/<br>$camp->{'IMG_LINK_3'}<br>/g;
	$creative =~ s/UNSUB_IMG/<br>$camp->{'UNSUB_IMG'}<br>/g;

    my $one_letter = uc(rand_char('letters',1));
	my ($randnum,$randlet,$ck,%clickparse);

    for ($i=1;$i<=9;$i++) {
        $randnum  = rand_char('numbers',$i);
        $randlet  = rand_char('letters',$i);
        $creative =~ s/RANDNUM$i/$randnum/g;
        $creative =~ s/RANDLET$i/$randlet/g;
    }

    for ($ck=1;$ck<=5;$ck++) {
        $randlet = rand_char('letters',6);
        my $randlet1 =  rand_char('allletters',13);
        my $randlet2 =  rand_char('allletters',13);
        my $randlet3 =  rand_char('allletters',13);

		if ($ck == 3) {
			$clickparse{$ck} = "http://$randlet.{{03}}/$camp->{campaign_id}/{{02}}/$ck";
		}
        else {
			$clickparse{$ck} = "http://$randlet1.{{03}}/$camp->{campaign_id}/{{02}}";
		}
        $creative =~ s/CLICK$ck/$clickparse{$ck}/g;
    }

    for ($ck=1;$ck<=5;$ck++) {
        $randlet = rand_char('letters',7);
        $clickparse{$ck} = "http://$randlet.{{03}}/{{02}}.cgi?camp_id=$camp->{campaign_id}";
        $creative =~ s/UNSUB$ck/$clickparse{$ck}/g;
    }

    my $image = rand_char('letters',3);
    my $footer = get_hotre_email_footer($camp);

    my $rand_1 = $rand->{random};
    my $rand_2 = $rand->{random1};
    my $rand_t;
    if ( length($rand_1) > 50 && length($rand_2) > 50) {
        $rand_t = int(rand(2)) ? $rand_1 : $rand_2;
    }
    elsif( length($rand_1) > 50 ) {
        $rand_t = $rand_1;
    }
    elsif( length($rand_2) > 50 ) {
        $rand_t = $rand_2;
    }

    $creative =~ s/RANDTEXT/$rand_t/g;
    $creative =~ s/FOOTER/$footer/g;
    $creative =~ s/DOMAIN/{{03}}/g;
    $creative =~ s/IMAGE/$image.{{03}}/g;
    $creative =~ s/EMAIL/{{01}}/g;
    $creative =~ s/EID/{{02}}/g;
    $creative =~ s/CAMPID/$camp->{campaign_id}/g;
    $creative =~ s/^M//g;

	# get sub domain
	my $sub = $ip->{'rdns'};
	$sub = rand_char('letters',5) unless ($sub);

	my $boundary = rand_char('numbers',3);
	my $boundary1= uc(rand_char('letters',18));
	$boundary = $boundary1.'_'.$boundary;
	eval { open(EMAIL,">$path/hotre.email"); }; &write_file('errors', "$now: write_email_file(): Cannot open the email file.") if $@;

	print EMAIL qq[From: {{09}} <{{06}}\@$sub.{{03}}>
Subject: {{05}}
Message-Id: <{{08}}\@$sub.{{03}}>];

	if ($camp->{ eid_header}) {
		print EMAIL qq[
$camp->{ eid_header}: {{08}}];
	}

	my $random = $rand->{random1};
	my $somenum = rand_char('numbers',3);

	print EMAIL qq[
MIME-Version: 1.0
Content-type: text/html; charset=us-ascii
References:

$creative];

	close(EMAIL);

    return '';
}

# random character from deploy.pl (used to ensure similarity)
sub rand_char {
    my (@chars,$char_length);

    my $rand = q{};

    if ($_[0] eq 'letters') {
        @chars = ('a'..'z');
        $char_length = $_[1];
    }
    elsif ($_[0] eq 'numbers') {
        @chars = (0..9);
        $char_length = $_[1];
    }
    elsif ($_[0] eq 'allletters') {
        @chars = (0..9,'a'..'z','A'..'Z');
        $char_length = $_[1];
    }

    while (length $rand < $char_length) {
        $rand .= $chars[rand @chars]
    }

    return $rand;

} # end rand_char

# get domains, include another random domain name
sub prep_get_domains {
	my ($dh_id, $dom_num) = @_;

	my $all = &get_domains($dh_id);

	# get only number asked
	unless ($dom_num) {
		$dom_num = scalar(@{$all});
	}
	my @doms = ();
	for (my $i = 1; $i <= $dom_num; $i++) {
		my $dom = $all->[rand @{$all}];
		push @doms, $dom;
	}

	# push a random domain for return-path
	foreach my $dom (@doms) {
		my $ran = $all->[rand @{$all}];
		$dom->{'random_domain'} = $ran->{'domain_name'};
	}

	return \@doms;
}

# get html wrappers, put in wrapper_id keyed hash
sub prepare_hotre_html_wrappers {
	my $html_wrappers = &get_hotre_html_wrappers();

	my %hsh = ();
	foreach my $wrap (@{$html_wrappers}) {
		$hsh{$wrap->{'html_wrapper_id'}} = $wrap;
	}

	return \%hsh;
}

sub get_oldest_hotmail {
	my $hotmail_accts = &get_hotre_hotmail_accounts();

	foreach my $r1 (@{$hotmail_accts}) {
	foreach my $r2 (@{$hotmail_accts}) {
		if ($r1->{'last_used'} le $r2->{'last_used'}) {
			my $tmp = $r1;
			$r1 = $r2;
			$r2 = $tmp;
		}
	}}

	my @arr = ();
	push @arr, $hotmail_accts->[0];
	return \@arr;

}

# get all domains (within str) into array
sub prepare_all_domains {
	my ($dhs) = @_;

	my $dh_str = '';
	foreach my $dh (@{$dhs}) {
		$dh_str .= "$dh->{'dh_id'},";
	}
	chop $dh_str;

	return &get_domains($dh_str);
}

# get working dhs
sub prepare_working_hotre_dhs {
	my $tests = shift;

	my %iron = ();
	foreach my $test (@{$tests}) {
		$iron{$test->{'ironport_id'}} = 1;
	}

	my $ironstr = '';
	foreach my $id (keys %iron) {
		$ironstr .= "$id,";
	}
	chop $ironstr;

	my $dhs = &get_dhs({'ironports_to_send' => $ironstr});
	return $dhs;
}

# get domains that worked during success, for that iron/dh
# returns dh_id keyed hash, each contaning array of domain hashes
# hsh{dh_id} = @arr (%dom1, %dom2... etc);
sub prepare_working_domains {
	my ($dom_num) = @_;

	# get array of all working domains, then group them into hash by dh_id
	my $all_arr = &get_hotre_test_success_domains();
	my %all_hsh = ();
	foreach my $dom (@{$all_arr}) { my @arr = (); $all_hsh{$dom->{'dh_id'}} = \@arr; }
	foreach my $dom (@{$all_arr}) {
		push @{$all_hsh{$dom->{'dh_id'}}}, $dom;
	}

	# get only number asked, return all as default
	unless ($dom_num) {
		return \%all_hsh;
	}

	# rebuild content of all_hsh to contain only the number of domains asked
	my %doms_hsh = ();
	foreach my $dh_id (keys %all_hsh) {
		for (my $i = 1; $i <= $dom_num; $i++) {
			my $dom = $all_hsh{$dh_id}->[rand @{$all_hsh{$dh_id}}];
			push @{$doms_hsh{$dom->{'dh_id'}}}, $dom;
		}
	}

	# push a random domain for return-path
	foreach my $dh_id (keys %doms_hsh) {
		foreach my $dom (@{$doms_hsh{$dh_id}}) {
			my $ran = $all_hsh{$dh_id}->[rand @{$all_hsh{$dh_id}}];
			$dom->{'random_domain'} = $ran->{'domain_name'};
		}
	}

	return \%doms_hsh;
}

return 1;
