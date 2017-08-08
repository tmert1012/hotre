# HotRE (Hotmail Random Engine)
# author: Nathan Garretson
# August 24, 2007
# hotre.db.pl
# hotre db functions for all to enjoy!

# create a new hotre email body, returns email_body_id
sub new_hotre_email_body {
	my $html_wrappers = &get_hotre_html_wrappers();
	my $html_wrapper = $html_wrappers->[rand @{$html_wrappers}];

	&sql_execute("insert into hotre_email_bodies (email_body_id, create_date, html_wrapper_id) values (0, now(),'$html_wrapper->{'html_wrapper_id'}');");
	my $ret = &sql_query("select max(email_body_id) as email_body_id from hotre_email_bodies;");
	if ($ret->[0]{'email_body_id'}) {
		return $ret->[0]{'email_body_id'};
	}
	else {
		&write_file('errors', "$now: new_hotre_email_body(): Insert failed.");
	}
}

# update hotre email body
sub update_hotre_email_body {
	my $data = shift;

	unless ($data->{'message_size'} && $data->{'email_body_id'}) {
		&write_file('errors', "$now: update_hotre_email_body(): No lines updated, no data to insert.");
		return 0;
	}

	&sql_execute("update hotre_email_bodies set message_size=$data->{'message_size'} where email_body_id=$data->{'email_body_id'};");
}

# insert email body lines
sub new_hotre_email_body_lines {
	my $arr = shift;

	my $inserts = '';
	foreach my $line (@{$arr}) {
		if ($line->{'email_body_id'}) {
			my $text = $dbh->quote($line->{'line_text'});
			$inserts .= "($line->{'email_body_id'},$line->{'random_id'},$line->{'wrapper_id'},$line->{'base_link_id'},$line->{'line_num'},$text,$line->{'line_size'}),\n";
		}
		else {
			&write_file('errors', "$now: new_hotre_email_body_lines(): Line not inserted, no email_body_id.");
		}
	}

	chomp $inserts;
	chop $inserts;
	if ($inserts) {
		&sql_execute("insert into hotre_email_body_lines (email_body_id,random_id,wrapper_id,base_link_id,line_num,line_text,line_size) values\n$inserts;");
	}
	else {
		&write_file('errors', "$now: new_hotre_email_body_lines(): No lines inserted, no data to insert.");
	}
}

# get lines of email body
sub get_hotre_email_body_lines {
	my $ebid = shift;
	my $ret = &sql_query("select * from hotre_email_body_lines where email_body_id=$ebid order by line_num;");
	if ($ret) {
		return $ret;
	}
	else {
		&write_file('errors', "$now: get_hotre_email_body_lines(): No email body lines to return.");
		return 0;
	}
}

# get email bodies that havent been tested yet
sub untested_email_bodies {
	my $ret = &sql_query("select * from hotre_email_bodies where email_body_id not in (select email_body_id from hotre_email_tests);");
	if ($ret) {
		return $ret;
	}
	else {
		&write_file('warnings', "$now: untested_email_bodies(): No untested email bodies.");
		return 0;
	}
}

# create new email test in database
sub new_hotre_email_test {
	my $hsh = shift;

	if ($hsh->{'email_body_id'} && $hsh->{'ironport_id'} && $hsh->{'campaign_id'} && $hsh->{'domain_id'}) {

		&sql_execute('lock table hotre_email_tests write;');
		&sql_execute(qq[insert into hotre_email_tests (email_test_id,email_body_id,test_date,ironport_id,success,campaign_id,domain_id,subject,from_name,hotmail_account_id) values
			(0,$hsh->{'email_body_id'},now(),$hsh->{'ironport_id'},0,$hsh->{'campaign_id'},$hsh->{'domain_id'},'','','$hsh->{'hotmail_account_id'}');]);
		sleep(1);
		my $ret = &sql_query("select last_insert_id() as email_test_id;");
		#my $ret = &sql_query("select max(email_test_id) as email_test_id from hotre_email_tests;");
		&sql_execute('unlock tables;');

		if ($ret->[0]{'email_test_id'}) {
			return $ret->[0]{'email_test_id'};
		}
		else {
			&write_file('errors', "$now: new_hotre_email_test(): No email_test_id to return.");
			return 0;
		}
	}
	else {
		&write_file('errors', "$now: new_hotre_email_test(): Line not inserted, missing one or more of: email_body_id, ironport_id, campaign_id, domain_id.");
		return 0;
	}
}

# update test as success
sub hotre_email_test_success {
	my $arr = shift;

	foreach my $line (@{$arr}) {
		if ($line->{'email_test_id'} && $line->{'ip_address'}) {
			&sql_execute("update hotre_email_tests set success=$line->{'success'}, ip_address='$line->{'ip_address'}', process_date=now() where email_test_id=$line->{'email_test_id'};");
		}
		else {
			&write_file('errors', "$now: hotre_email_test_success(): Line not inserted, no email_test_id.");
		}
	}
}

# update test
sub update_hotre_email_test {
	my $arr = shift;

	foreach my $line (@{$arr}) {
		my $str = '';
		$str .= "success=$line->{'success'}" if ($line->{'success'});
		$str .= ', ' if ($line->{'success'} && $line->{'subject'});

		my $text = $dbh->quote($line->{'subject'});
		$str .= "subject=$text" if ($line->{'subject'});
		$str .= ', ' if ($line->{'subject'} && $line->{'from_name'});

		my $text = $dbh->quote($line->{'from_name'});
		$str .= "from_name=$text" if ($line->{'from_name'});
		if ($line->{'email_test_id'} && $str) {
			&sql_execute("update hotre_email_tests set $str where email_test_id=$line->{'email_test_id'};");
		}
		else {
			&write_file('errors', "$now: update_hotre_email_test(): Line not inserted, no email_test_id.");
		}
	}
}

# get successfull inbox hotre tests
sub get_hotre_test_success {
	# today
	my ($y, $m, $d) = &getDate();
	my $today = "$y-$m-$d";

	my $ret = &sql_query(qq[select * from hotre_email_tests where
		success in (1,2) and
		test_date >= '$today 00:00:00' and test_date <= '$today 23:23:59'
		]);

	if ($ret) {
		return $ret;
	}
	else {
		&write_file('errors', "$now: get_hotre_tests_success(): No dhs found.");
		return 0;
	}
}

# get domains that worked during probe testing
sub get_hotre_test_success_domains {

	# today
	my ($y, $m, $d) = &getDate();
	my $today = "$y-$m-$d";

	my $ret = &sql_query(qq[select * from domain_names where domain_id in (
		select domain_id from hotre_email_tests where
		success in (1,2) and
		test_date >= '$today 00:00:00' and test_date <= '$today 23:23:59'
		)
		]);

	if ($ret) {
		return $ret;
	}
	else {
		&write_file('errors', "$now: get_hotre_test_success_domains(): No dhs found.");
		return 0;
	}
}

# get campaign
sub get_hotre_campaigns {
	my $dhs = shift;

	my $iron_str = '';
	if ($dhs) {
		foreach my $dh (@{$dhs}) {
			$iron_str .= "'$dh->{'ironport_id'}',";
		}
		chop $iron_str;
		$iron_str = "and ironport_id in ($iron_str)";
	}

	# run time stamp
	my ($y, $m, $d) = &getDate(86400);
	my $yest = "$y-$m-$d 00:00:00";

	my $sql = qq[
		select * from campaign_list where
		campaign_status='delivered' and
		sent_date >= '$yest' and sent_date <= now()
		$iron_str
	];
	my $ret = &sql_query($sql);

	# if something is returned
	if ($ret->[0]) {
		return $ret;
	}
	else {
		&write_file('errors', "$now: get_hotre_campaigns(): No hotmail campaigns found.");
		return 0;
	}
}

# get the footer
sub get_hotre_email_footer {
	my $camp = shift;
    my $ret = &sql_query("SELECT email_footer FROM iron_ports WHERE ironport_id='$camp->{ironport_id}' LIMIT  1;");
	if ($ret->[0]{'email_footer'}) {
		return $ret->[0]{'email_footer'};
	}
}

# returns hotre dhs
sub get_hotre_dhs {
	my $config = shift;

	# ironports to send
	my $irons = '';
	if ($config->{'ironports_to_send'}) {
		$irons = "and i.ironport_id in ($config->{'ironports_to_send'})" if ($config->{'ironports_to_send'});
	}

	my $ret = &sql_query(qq[select d.dh_name, d.dh_id, d.domain, i.ironport_id from DH_info d, iron_ports i
		where d.dh_status='hotre'
		and d.dh_id=i.dh_id
		and d.dh_name not regexp '^TACTARA'
		$irons
		]);
	if ($ret) {
		return $ret;
	}
	else {
		&write_file('errors', "$now: get_hotre_dhs(): No hotre dhs found.");
		return 0;
	}
}

# returns  dhs
sub get_dhs {
	my $config = shift;
	my $dh_str = shift;

	# pass in dh str
	if ($dh_str) {
		$dh_str = "and d.dh_id in ($dh_str)";
	}
	# ironports to send
	my $irons = '';
	if ($config->{'ironports_to_send'}) {
		$irons = "and i.ironport_id in ($config->{'ironports_to_send'})" if ($config->{'ironports_to_send'});
	}
	# ironport types to send
	my $ir_dom = '';
	if ($config->{'ironport_domain_type_to_send'}) {
		$ir_dom = "and i.domain='$config->{'ironport_domain_type_to_send'}'" if ($config->{'ironport_domain_type_to_send'});
	}

	my $ret = &sql_query(qq[select d.dh_name, d.dh_id, d.domain, i.ironport_id from DH_info d, iron_ports i
		where d.dh_id=i.dh_id
		$ir_dom
		$irons
		$str
		]);
	if ($ret) {
		return $ret;
	}
	else {
		&write_file('errors', "$now: get_dhs(): No dhs found.");
		return 0;
	}
}

# get domain on string
sub get_domains {
	my $str = shift;
	my $dom_num = shift;

	if ($str) {
		$str = "dh_id in ($str) and";
	}

	my $ret = &sql_query(qq[select * from domain_names where $str domain_status='active' and blocked='no' and expiration > '$now']);

	unless ($ret) {
		&write_file('errors', "$now: get_domains(): No domains found.");
	}

	# get domains randomly (this can get the same domain multiple times..)
	if ($dom_num) {
		my @doms = ();
		for (my $i = 1; $i <= $dom_num; $i++) {
			my $dom = $ret->[rand @{$ret}];
			push @doms, $dom;
		}
		return \@doms;
	}
	# get em all
	else {
		return $ret;
	}

}

# get the active randoms
sub get_hotre_randoms {
	my $ret = &sql_query(qq[select * from hotre_randoms where status='active']);
	if ($ret) {
		return $ret;
	}
	else {
		&write_file('errors', "$now: get_hotre_randoms(): No active hotre randoms found.");
		return 0;
	}
}

# get the active wrappers
sub get_hotre_wrappers {
	my $ret = &sql_query(qq[select * from hotre_wrappers where status='active']);
	if ($ret) {
		return $ret;
	}
	else {
		&write_file('errors', "$now: get_hotre_wrappers(): No active hotre randoms found.");
		return 0;
	}
}

# get the active base links
sub get_hotre_base_links {
	my $ret = &sql_query(qq[select * from hotre_base_links where status='active' order by base_link_id]);
	if ($ret) {
		return $ret;
	}
	else {
		&write_file('errors', "$now: get_hotre_base_links(): No active base links found.");
		return 0;
	}
}

# load up hotre config, builds hash returns that.
sub get_hotre_config {
	my $ret = &sql_query(qq[select * from hotre_config]);

	unless ($ret) {
		&write_file('errors', "$now: get_hotre_config(): Can't get hotre config.");
		return 0;
	}

	my %hsh = ();
	foreach my $line (@{$ret}) {
		$hsh{$line->{'ckey'}} = $line->{'cvalue'};
	}
	return \%hsh;
}

# get the hotre spam phrases
sub get_hotre_spam_phrases {
	my $ret = &sql_query(qq[select phrase from hotre_spam_phrases]);
	if ($ret) {
		return $ret;
	}
	else {
		&write_file('warnings', "$now: get_hotre_spam_phrases(): No spam phrases found.");
		return 0;
	}
}

# get hotre html wrappers
sub get_hotre_html_wrappers {
	my $wrapper_id = shift;

	if ($wrapper_id) {
		$wrapper_id = "and html_wrapper_id in ($wrapper_id)";
	}

	my $ret = &sql_query(qq[select * from hotre_html_wrappers where status='active' $wrapper_id order by html_wrapper_id]);
	if ($ret) {
		return $ret;
	}
	else {
		&write_file('errors', "$now: get_hotre_html_wrappers(): No active html wrappers found.");
		return 0;
	}
}

# get hotre hotmail accounts
sub get_hotre_hotmail_accounts {
	my $ret = &sql_query(qq[select * from hotre_hotmail_accounts where status='active']);
	if ($ret) {
		return $ret;
	}
	else {
		&write_file('errors', "$now: get_hotre_hotmail_accounts(): No active hotmail accounts found.");
		return 0;
	}
}

# get dh ips
sub get_ips {
	my ($dh,$status) = @_;

	my $dh_str = '';
	if ($dh) {
		$dh_str = "where dh_id=$dh->{'dh_id'}";
	}

	my $status_str = '';
	$status_str = "and ip_status='$status'" if ($status eq 'active');
	$status_str = "and ip_default='$status'" if ($status eq 'default');

	my $ret = &sql_query(qq[select * from dh_ip $dh_str $status_str]);
	if ($ret) {
		return $ret->[0];
	}
	else {
		&write_file('errors', "$now: get_ips(): No IPs found for dh_id $dh->{'dh_id'}.");
		return 0;
	}
}

# update last used field
sub update_hotmail_account {
	my $acct = shift;

	if ($acct->{'hotmail_account_id'}) {
		&sql_execute("update hotre_hotmail_accounts set last_used=now() where hotmail_account_id=$acct->{'hotmail_account_id'};");
	}
	else {
		&write_file('errors', "$now: update_hotmail_account(): No hotmail account to update.");
		return 0;
	}
}

return 1;
