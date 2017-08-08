# HotRE (Hotmail Random Engine)
# author: Nathan Garretson
# August 29, 2007
# hotre.random.utils.pl
# hotre random utility functions!

# generate random paragraph with proper english grammar!
# parameter hash with stats, size optional
sub random_paragraph {
	my $size = shift;
	
	$size = 260 unless ($size);
	
	my ($h,$m,$s) = &getTime();
	
	# get random words
	my $random_words = &randomText($size);
	
	# piece it into a "paragraph"
	my $text = '';
	my @choice = (1..30);
	my $asize = (@{$random_words} - 3);
	my $last_opt = 0;
	my $eos = 1;
	my $i = 0;
	while ($i < $asize) {
		
		# random option, cant be same option twice in a row
		my $opt = $choice[ rand @choice ];
		unless ($opt != $last_opt) {
			$opt = $choice[ rand @choice ];
		}
		
		# mid sentence punctuation
		if ($opt == 2) { 
			my $elt = $midSentence[ rand @midSentence ];
			my $word = $random_words->[$i];
			if ($eos) {
				$word = &ucFirstLetter($word);
				$eos = 0;
			}
			my $endWord = $random_words->[$i + 1];
			$text .= "$word$elt $endWord";
			$i++;
		}
		# number plus ending puct
		elsif ($opt == 5) {
			my $elt = $numEnd[ rand @numEnd ];
			my $num = (int("$h$i") + int("$m$s")) % 100;
			$text .= "$num$elt";
			$eos = 1;
		}
		# quote a word
		elsif ($opt == 7) {
			my $elt = $quotes[ rand @quotes ];
			$text .= "$elt$random_words->[$i]$elt";
			$eos = 0;
		}
		# quote a sentence
		elsif ($opt == 9) {
			my $elt = $quotes[ rand @quotes ];
			my $words = '';
			my $start = $i + 1;
			my $end = $start + int(rand(10)) + 1;
			for ($x = $start; $x < $end; $x++) { 
				$words .= "$random_words->[$x] " if ($random_words->[$x]);
			}
			chop $words;
			$nextWord = &ucFirstLetter($random_words->[$end]);
			$text .= "$random_words->[$i], $elt$words.$elt $nextWord";
			$i = $end;
			$eos = 0;
		}
		# number sign plus number
		elsif ($opt == 10) {
			my $elt = $numFront[ rand @numFront ];
			my $num = int ($i + $m - $h);
			$text .= "$elt$num";
			$eos = 0;
		}
		# start of new sentence with punc
		elsif ($opt == 12) {
			my $last = $random_words->[$i];
			my $next = &ucFirstLetter($random_words->[$i + 1]);
			my $ret = $newLines[ rand @newLines ];
			my $punc = $sentenceEnd[ rand @sentenceEnd ];
			$text .= "$last$punc$ret$next";
			$i++;
			$eos = 0;
		}
		# add in coordinating conjunctions, WITH punct
		elsif ($opt == 13 || $opt == 14 || $opt == 15) {
			my $elt = $midSentence[ rand @midSentence ];
			$text .= $coordConj[ rand @coordConj ] . $elt;
			$eos = 0;
		}
		# form a list
		elsif ($opt == 17) {
			my $list = '';
			my $end = $i + int(rand(3)) + 1;
			for ($x = $i; $x < $end; $x++) { 
				$list .= "$random_words->[$x], " if ($random_words->[$x]);
			}
			chop $list;
			chop $list;
			$nextWord = &ucFirstLetter($random_words->[$end]);
			$text .= "$list and $nextWord.";
			$i = $end;
			$eos = 1;
		}
		# most common words in english
		elsif ($opt == 18 || $opt == 19 || $opt == 20) {
			my $word = $MostComm[ rand @MostComm ];
			if ($eos) {
				$word = &ucFirstLetter($word);
				$eos = 0;
			}
			$text .= $word;
			$eos = 0;
		}
		# just print regular word
		else {
			my $word = $random_words->[$i];
			if ($eos) {
				$word = &ucFirstLetter($word);
				$eos = 0;
			}
			$text .= $word;
			$eos = 0;
		}
		# space between each word
		$text .= ' ';
		$last_opt = $opt;
		$i++
	}
	
	chop $text;
	chomp $text;
	my $punc = $sentenceEnd[ rand @sentenceEnd ];
	if ($text) {
		return "$text$punc";
	}
	else {
		return $text;
	}
}

# remove unsub keywords so soft bounces arent auto unsubed by accident
sub remove_unsub_keywords {
	my $hsh = shift;
	$hsh->{'line_text'} =~ s/unsub|remov|your list|delete|discontinue|opt-out|opt out|stop//iog;
}

# build a block of html
sub build_html_block {
	my $element_data = shift;
	my $elm = shift;
	my $indent = shift;
	
	my $text = '';
	my ($h,$m,$s) = &getTime();
	my $data = $element_data->{$elm};
	my $indText = &indent_text($indent);
	
	# required arributes
	my $attribs = '';
	if ($data->{'attribs'}[0] ne 'NO') {
		foreach my $attrib (@{$data->{'attribs'}}) { 
			my $junk = join('', &rand_chars(set => 'alphanumeric', min => 5, max => 10));
			$attribs .= " $attrib=\"$junk\"";
		}
	}
	
	# optional attributes
	my @optAttributes = ('id', 'class', 'title', 'style', 'dir', 'lang', '');
	my @OARange = (0..@optAttributes - 1);
	my $optAttribCnt = $OARange[rand @OARange];
	foreach ($i = 0; $i <= $optAttribCnt; $i++) {
		my $attrib = $optAttributes[rand @optAttributes];
		my $junk = join('', &rand_chars(set => 'alphanumeric', min => 2, max => 7));
		$attribs .= " $attrib=\"$junk\"" if ($attrib);
	}
	
	# if element uses end tag, leave open
	if ($data->{'end_tag'} eq 'YES') {
		my $para = &random_paragraph(int(rand($h+$m)));
		$text .= "$indText<$elm$attribs>\n$indText$para\n";
	}
	elsif ($data->{'end_tag'} eq 'NO') {
		$text .= "$indText<$elm$attribs />\n";
	}
	
	# if child elements
	if ($data->{'child_elements'}[0] ne 'NO') {
		foreach my $child (@{$data->{'child_elements'}}) { 
			$text .= &build_html_block($element_data, $child, $indent+1);
		}
	}
	
	# close parent element tag
	if ($data->{'end_tag'} eq 'YES') {
		return "$text$indText</$elm>\n";
	}
	elsif ($data->{'end_tag'} eq 'NO') {
		return "$text\n";
	}
}

# load html hash from file
sub load_html_hash {
	my $arr = shift;
	my $hsh = shift;
		
	open FILE, "$path/$HTMLFile";
	my @lines = <FILE>;
	my $line_cnt = @lines;
	close FILE;
	
	# ELEMENT ; END TAG ; REQ'D ARRTRIBS ; IS PARENT?; CHILD ELEMENTS
	foreach my $line (@lines) {
		chomp $line;
		my ($element, $endTag, $attribs, $parent, $child_elmts) = split(/;/, $line);
		my @attribs = split(/\|/, $attribs);
		my @child_elmts = split(/\|/, $child_elmts);
		$hsh->{$element} = {
			'end_tag' => $endTag,
			'attribs' => \@attribs,
			'parent' => $parent,
			'child_elements' => \@child_elmts,
		};
		push(@{$arr}, $element);
	}
}

# build tab string based on parameter
sub indent_text {
	my $num = shift;
	
	my $text = '';
	for ($i = 0; $i <= $num; $i++) {
		$text .= "\t";
	}
	return $text;
}

# strip out email addresses from text
sub strip_email_addresses {
	my $text = shift;
	$text =~ s/\w+\@\w+\.\w{3}//iog;
	return $text;
}

# strip out extra lines from text
sub strip_extra_breaks {
	my $hsh = shift;
	$hsh->{'line_text'} =~ s/\n|\r|\f|\t//g;
}

# strip out extra lines from text
sub strip_unusual_characters {
	my $hsh = shift;
	my @ascCodes = ();
	for (my $i=128; $i<=255; $i++) {
		push @ascCodes, chr($i);
	}
	my $ascStr = join('|', @ascCodes);
	$hsh->{'line_text'} =~ s/$ascStr//g;
}

# remove spam like phrases
sub remove_spam_phrases {
	my $hsh = shift;
	my $phrases = shift;
	foreach my $phrase (@{$phrases}) {
		$phrase = $phrase->{'phrase'};
	}
	my $str = join('|', @{$phrases});
	$hsh->{'line_text'} =~ s/$str//ig;
}

# strip out links, websites
sub strip_urls {
	my $text = shift;
	$text =~ s/http:\/\/[A-Za-z0-9_.]+\.\w+//iog;
	return $text;
}

# load css hash, pick properties and values ahead of time
sub load_css_hash {
	
	open FILE, "$path/$CSSFile";
	my @lines = <FILE>;
	my $line_cnt = @lines;
	close FILE;
	
	# css length options
	my @length = ('em','ex','px','in','cm','mm','pt','pc');
	my @hexset = (0,1,2,3,4,5,6,7,8,9,a,b,c,d,e,f);
	
	my @arry = ();
	foreach my $line (@lines) {
		chomp $line;
		my ($property, $vals) = split(/:/, $line);
		my @values = split(/\|/, $vals);
		my $value = $values[rand @values];
		if ($value eq "RANDOM_TEXT") { $value = join('', &rand_chars(set => 'alphanumeric', min => 5, max => 8)); }
		elsif ($value eq  "LENGTH") { $value = join('', &rand_chars(set => 'numeric', min => 1, max => 2)) . $length[rand @length]; }
		elsif ($value eq "PERC") { $value = join('', &rand_chars(set => 'numeric', min => 1, max => 2)) . '%'; }
		elsif ($value eq "HEX") { $value = '#' . uc(join('', &rand_set(set => \@hexset, min => 6, max => 6))); }
		elsif ($value eq "URL") { $value = 'http://www.' . join('', &rand_chars(set => 'alphanumeric', min => 4, max => 6)) . '.com'; }
		my %hsh = (
			'property' => $property,
			'value' => $value,
		);
		push @arry, \%hsh;
	}
	return \@arry;
}

# wget a URL until one is successful and return it
sub wget_url {
	
	open FILE, "$path/$URLFile";
	my @lines = <FILE>;
	my $url_cnt = @lines;
	close FILE;
	
	my $error = 1;
	my $msg_err = '';
	my $page_content = '';
	my $msgs = "$path/wget_msgs";
	my $page = "$path/wget_page";
	
	while ($error && $url_cnt) {
		my $url = $lines[ rand @lines ];
		chomp $url;
		
		my $cmd = qq[$wget -T 10 "$url" -a $msgs -O $page];
		`$cmd`;
		
		open (FILE, $msgs);
		my @ary1 = <FILE>;
		close (FILE);
		
		open (FILE, $page);
		my @ary2 = <FILE>;
		close (FILE);
		
		foreach (@ary1) { $msg_err .= $_; }
		foreach (@ary2) { $page_content .= $_; }
		
		if ($msg_err =~ /error/gio) {
			$error = 1;
		}
		elsif (!$page_content) {
			$error = 1;
		}
		else {
			$error = 0;
		}
		`/bin/rm -f $msgs $page`;
		$url_cnt--;
	}
	return $page_content;
}

# returns list of random words
sub randomText {
	my $size = shift;
	my $type = shift;
	
	my @random_words = &rand_words('size' => $size);
	
	if ($type eq 'odd') {
		my $odders = int(@random_words / 4);
		for (my $i=1; $i<=$odders; $i++) {
			$random_words[$i] = &insertOdd($random_words[$i]);
		}
		&fisher_yates_shuffle(\@random_words);
	}
	
	return \@random_words;
}

# inserts weirdo character into word
sub insertOdd {
	my $word = shift;
	
	my @ascCodes = ();
	for (my $i=128; $i<=255; $i++) {
		push @ascCodes, chr($i);
	}
	
	my @opts = (1..length($word));
	my $opt = $opts[rand @opts];
	
	my @chars = split(//, $word);
	my $odd = $ascCodes[rand @ascCodes];
	
	my $new = '';
	for (my $i=1; $i<=length($word); $i++) {
		$new .= $chars[$i];
		$new .= $odd if ($opt == $i);
	}
	
	return $new;
}

# returns list of numbers
sub randomNums {
	my $size = shift;
	
	my @random_nums = ();
	for ($i = 0; $i <= $size; $i++) {
		push @random_nums, join('', &rand_chars('set' => 'numeric', 'min' => 1, 'max' => 10));
	}
	return \@random_nums;
}

# random list of nums and words
sub randomAll {
	my $limit = shift;
	my $words = &randomText(int($limit/2));
	my $nums = &randomNums(int($limit/2));
	push(@{$words}, @{$nums});
	&fisher_yates_shuffle($words);
	return $words;
}

# $deck is a reference to an array
sub fisher_yates_shuffle {
	my $deck = shift;
	my $i = @$deck;
	while ($i--) {
		my $j = int rand ($i+1);
		@$deck[$i,$j] = @$deck[$j,$i];
	}
}

# uppercase first letter of string
sub ucFirstLetter {
	my $word = shift;
	my $let =  substr($word, 0, 1);
	my $rest = substr($word, 1);
	$word = uc($let) . $rest;
	return $word;
}

# return list of odd chars
sub get_odd_chars {
	my @ascCodes = ();
	
	for (my $i=33; $i<=47; $i++) {
		push @ascCodes, chr($i);
	}
	
	for (my $i=58; $i<=64; $i++) {
		push @ascCodes, chr($i);
	}
	
	for (my $i=91; $i<=96; $i++) {
		push @ascCodes, chr($i);
	}
	
	for (my $i=91; $i<=96; $i++) {
		push @ascCodes, chr($i);
	}
	
	for (my $i=123; $i<=126; $i++) {
		push @ascCodes, chr($i);
	}
	
	for (my $i=128; $i<=255; $i++) {
		push @ascCodes, chr($i);
	}
	
	return \@ascCodes;
}

# return list of odd chars
sub get_20_returns {
	my @returns = ();
	
	my $return = "\n";
	for (my $i=1; $i<=20; $i++) {
		push @returns, $return;
		$return .= "\n";
	}
	
	return \@returns;
}

return 1;
