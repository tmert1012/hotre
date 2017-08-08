# HotRE (Hotmail Random Engine)
# author: Nathan Garretson
# August 24, 2007
# hotre.wrappers.pl
# hotre wrapper functions!
# wraps text in random hiding technique

# get active wrappers from database, put into list
my $ret = &get_hotre_wrappers();
our @wrapperChoices = ();
foreach my $line (@{$ret}) {
	push @wrapperChoices, $line->{'wrapper_id'};
}

# pass in wrapper id, will use that wrapper
sub wrapText {
	my $hsh = shift;
	my $wrapper = shift;
	
	# if a wrapper_id is passed, use that one wrapper.
	my @opts = ();
	my $opt = 0;
	if ($wrapper eq 'none') {
		$opt = 0;
	}
	elsif ($wrapper > 0) {
		$opt = $wrapper;
	}
	else {
		$opt = $wrapperChoices[rand @wrapperChoices];
	}
	
	# no wrapper
	if ($opt == 0) {
		$hsh->{'wrapper_id'} = 0;
	}
	
	&wrapper_200($hsh) if ($opt == 200);
	&wrapper_201($hsh) if ($opt == 201);
	&wrapper_202($hsh) if ($opt == 202);
	&wrapper_203($hsh) if ($opt == 203);
	&wrapper_204($hsh) if ($opt == 204);
	&wrapper_205($hsh) if ($opt == 205);
	&wrapper_206($hsh) if ($opt == 206);
	&wrapper_207($hsh) if ($opt == 207);
	&wrapper_208($hsh) if ($opt == 208);
	&wrapper_209($hsh) if ($opt == 209);
	&wrapper_210($hsh) if ($opt == 210);
	&wrapper_211($hsh) if ($opt == 211);
	&wrapper_212($hsh) if ($opt == 212);
}

# html comment
sub wrapper_200 {
	my $hsh = shift;
	
	$hsh->{'wrapper_id'} = 200;
	$hsh->{'line_text'} = "<!-- $hsh->{'line_text'} -->";
}

# html close/bad tag
sub wrapper_201 {
	my $hsh = shift;
	
	$hsh->{'wrapper_id'} = 201;
	my $char = join('', &rand_chars(set => 'alphanumeric', min => 1, max => 1));
	$hsh->{'line_text'} =~ s/\s/$char/g;
	$hsh->{'line_text'} = "</$hsh->{'line_text'}>";
}

# javascript comment
sub wrapper_202 {
	my $hsh = shift;
	
	$hsh->{'wrapper_id'} = 202;
	$hsh->{'line_text'} = "<script language=\"JavaScript\" type=\"text/javascript\"><!-- $hsh->{'line_text'} //--></script>";
}

# html display style
sub wrapper_203 {
	my $hsh = shift;
	
	$hsh->{'wrapper_id'} = 203;
	$hsh->{'line_text'} = "<div style=\"display:none\">$hsh->{'line_text'}</div>";
}

# html visible style
sub wrapper_204 {
	my $hsh = shift;
	
	$hsh->{'wrapper_id'} = 204;
	$hsh->{'line_text'} =  "<div style=\"visibility:hidden\">$hsh->{'line_text'}</div>";
}

# vb script
sub wrapper_205 {
	my $hsh = shift;
	
	$hsh->{'wrapper_id'} = 205;
	$hsh->{'line_text'} = "<script language=\"VBScript\" type=\"text/vbscript\"><!-- $hsh->{'line_text'} //--></script>";
}

# no script
sub wrapper_206 {
	my $hsh = shift;
	
	$hsh->{'wrapper_id'} = 206;
	$hsh->{'line_text'} = "<noscript>$hsh->{'line_text'}</noscript>";
}

# style tags
sub wrapper_207 {
	my $hsh = shift;
	
	$hsh->{'wrapper_id'} = 207;
	$hsh->{'line_text'} = "<style>$hsh->{'line_text'}</style>";
}

# head tag
sub wrapper_208 {
	my $hsh = shift;
	
	$hsh->{'wrapper_id'} = 208;
	$hsh->{'line_text'} = "<head>$hsh->{'line_text'}</head>";
}

# title tag
sub wrapper_209 {
	my $hsh = shift;
	
	$hsh->{'wrapper_id'} = 209;
	$hsh->{'line_text'} = "<title>$hsh->{'line_text'}</title>";
}

# broken html comment
sub wrapper_210 {
	my $hsh = shift;
	
	$hsh->{'wrapper_id'} = 210;
	$hsh->{'line_text'} = "<!\n$hsh->{'line_text'}\n>";
}

# font color white
sub wrapper_211 {
	my $hsh = shift;
	
	$hsh->{'wrapper_id'} = 211;
	$hsh->{'line_text'} = "<font color=white>$hsh->{'line_text'}</font>";
}

# font color #ffffff
sub wrapper_212 {
	my $hsh = shift;
	
	$hsh->{'wrapper_id'} = 212;
	$hsh->{'line_text'} = "<font color=\"#ffffff\">$hsh->{'line_text'}</font>";
}

return 1;
