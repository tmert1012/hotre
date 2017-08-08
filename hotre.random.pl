# HotRE (Hotmail Random Engine)
# author: Nathan Garretson
# August 24, 2007
# hotre.random.pl
# generate randoms for email body

use Data::Random qw(:all);

# includes
require ("$path/hotre.wrappers.pl");
require ("$path/hotre.random.utils.pl");

# globals
our @quotes = ('"', '\'', '');
our @sentenceEnd = ('!', '?', '.');
our @midSentence = (';', ',', '...', '');
our @numFront = ('#', '~', '$', '+', '-', '*','');
our @numEnd = ('%', '.', '');
our @newLines = ("\n","\n\n","\n\n\t");
our @coordConj = ('for','and','nor','but','or','yet','so');
our @MostComm = ('the', 'of', 'to', 'a' ,'in', 'is', 'it', 'you', 'that', 'he', 'she', 'was', 'on', 'are', 'with', 'as', 'I', 'his');
our @joiners = (':',' ','.','-',')(','#');
our $URLFile = 'wget_links';
our $wget = '/usr/bin/wget';
our $CSSFile = 'css_hash';
our $HTMLFile = 'html_hash';
our $ascCodes = &get_odd_chars();
our $returns = &get_20_returns();
our $phrases = &get_hotre_spam_phrases();

# get active randoms from database
my $ret = &get_hotre_randoms();
my @randomChoices = ();
foreach my $line (@{$ret}) {
	push @randomChoices, $line->{'random_id'} unless ($line->{'random_id'} == 1);
}


# MAIN FUNCTION called from hotre.create.email.body
# generate hotmail random
sub get_randoms {
	my $config = shift;

	# number of randoms from config
	my $limit = 0;
	if ($config->{'exact_randoms'}) {
		$limit = $config->{'exact_randoms'};
	}
	else {
		my @choices = ($config->{'min_randoms'}..$config->{'max_randoms'});
		$limit = $choices[rand @choices];
	}

	# approx size in KB from config
	my $subRanSizeKB = 0;
	if ($limit) {
		if ($config->{'approx_message_size'}) {
			$subRanSizeKB = ($config->{'approx_message_size'} / $limit);
		}
		else {
			my @choices = ($config->{'min_message_size'}..$config->{'max_message_size'});
			my $choice = $choices[rand @choices];
			$subRanSizeKB = ($choice / $limit);
		}
	}

	&write_file('errors', "$now: get_randoms(): Number of randoms (to generate) is invalid.") unless ($limit);
	&write_file('errors', "$now: get_randoms(): No usuable sub random size.") unless ($subRanSizeKB);

	my @randoms = ();

	# get randoms
	for (my $i = 1; $i <= $limit; $i++) {

		# new random hash
		my %hsh = ('line_text' => '', 'wrapper_id' => 0, 'random_id' => 0, 'base_link_id' => 0, 'line_num' => 0, 'line_size' => 0);

		# pick random
		&get_random_random($config, \%hsh, $subRanSizeKB);

		# remove misc things....
		&remove_unsub_keywords(\%hsh);
		&strip_unusual_characters(\%hsh) if ($hsh{'random_id'} == 102 || $hsh{'random_id'} == 103);
		&remove_spam_phrases(\%hsh, $phrases);
		&strip_extra_breaks(\%hsh) if ($hsh{'random_id'} == 102 || $hsh{'random_id'} == 103);

		# prewrap with extra random return spacing
		my $return = $returns->[rand @{$returns}];
		$hsh{'line_text'} = "$return$hsh{'line_text'}$return";

		# pick wrapper
		if ($hsh{'random_id'} == 106) { &wrapText(\%hsh, 'none'); }
		elsif ($hsh{'random_id'} == 104) { &wrapText(\%hsh, 'none'); }
		elsif ($hsh{'random_id'} == 107) { &wrapText(\%hsh, 'none'); }
		elsif ($hsh{'random_id'} == 108) { &wrapText(\%hsh, 'none'); }
		elsif ($hsh{'random_id'} == 110) { &wrapText(\%hsh, 'none'); }
		elsif ($hsh{'random_id'} == 111) { &wrapText(\%hsh, 'none'); }
		elsif ($hsh{'random_id'} == 112) { &wrapText(\%hsh, 'none'); }
		elsif ($hsh{'random_id'} == 114) { &wrapText(\%hsh, 'none'); }
		elsif ($hsh{'random_id'} == 115) { &wrapText(\%hsh, 'none'); }
		elsif ($hsh{'random_id'} == 116) { &wrapText(\%hsh, 'none'); }
		elsif ($hsh{'random_id'} == 117) { &wrapText(\%hsh, 'none'); }
		elsif ($hsh{'random_id'} == 118) { &wrapText(\%hsh, 'none'); }
		elsif ($hsh{'random_id'} == 119) { &wrapText(\%hsh, 'none'); }
		elsif ($hsh{'random_id'} == 120) { &wrapText(\%hsh, 'none'); }
		elsif ($hsh{'random_id'} == 121) { &wrapText(\%hsh, 'none'); }
		elsif ($hsh{'random_id'} == 123) { &wrapText(\%hsh, 'none'); }
		elsif ($hsh{'random_id'} == 124) { &wrapText(\%hsh, 'none'); }
		elsif ($hsh{'random_id'} == 125) { &wrapText(\%hsh, 207); }
		else { &wrapText(\%hsh); }

		# get line size
		use bytes;
		my $bytes = length($hsh{'line_text'});
		$hsh{'line_size'} = $bytes if ($bytes);
		no bytes;

		# save random
		push @randoms,  \%hsh;
	}

	# shuffle em
	&fisher_yates_shuffle(\@randoms);
	return \@randoms;
}

# pick one random randomly
sub get_random_random {
	my ($config, $hsh, $kb) = @_;

	# number of words to get within random
	my $numWords = 0;
	if ($kb) {
		# words = bytes / (average size of word is X bytes + filler bytes)
		$numWords = int(($kb * 1024) / (5+2.9));
	}
	else {
		# pick something at random
		my @choices = (20..500);
		$numWords = $choices[rand @choices];
	}

	# pick random!
	my $choice = '';
	if ($config->{'random_types'}) {
		my @choices = split(',', $config->{'random_types'});
		$choice = $choices[rand @choices];
	}
	else {
		$choice = $randomChoices[rand @randomChoices];
	}

	&random_100($hsh, $numWords) if ($choice == 100);
	&random_101($hsh, $numWords) if ($choice == 101);
	&random_102($hsh) if ($choice == 102);
	&random_103($hsh) if ($choice == 103);
	&random_104($hsh, $numWords) if ($choice == 104);
	&random_105($hsh, $numWords) if ($choice == 105);
	&random_106($hsh, $numWords) if ($choice == 106);
	&random_107($hsh, $numWords) if ($choice == 107);
	&random_108($hsh, $numWords) if ($choice == 108);
	&random_109($hsh, $numWords) if ($choice == 109);
	&random_110($hsh, $numWords) if ($choice == 110);
	&random_111($hsh, $numWords) if ($choice == 111);
	&random_112($hsh, $numWords) if ($choice == 112);
	&random_113($hsh, $numWords) if ($choice == 113);
	&random_114($hsh, $numWords) if ($choice == 114);
	&random_115($hsh, $numWords) if ($choice == 115);
	&random_116($hsh, $numWords) if ($choice == 116);
	&random_117($hsh, $numWords) if ($choice == 117);
	&random_118($hsh, $numWords) if ($choice == 118);
	&random_119($hsh, $numWords) if ($choice == 119);
	&random_120($hsh, $numWords) if ($choice == 120);
	&random_121($hsh, $numWords) if ($choice == 121);
	&random_122($hsh, $numWords) if ($choice == 122);
	&random_123($hsh, $numWords) if ($choice == 123);
	&random_124($hsh, $numWords) if ($choice == 124);
	&random_125($hsh, $numWords) if ($choice == 125);
	&random_126($hsh, $numWords) if ($choice == 126);
	&random_127($hsh, $numWords) if ($choice == 127);
	&random_128($hsh, $numWords) if ($choice == 128);
}

##### RANDOM FUNCTIONS - IN ORDER ##########
####################################

# call this for random paragraph with random id
sub random_100 {
	my $hsh = shift;
	my $size = shift;

	$hsh->{'random_id'} = 100;
	$size = 260 unless ($size);

	$hsh->{'line_text'} = &random_paragraph($size);
}

# returns string of random numbers
sub random_101 {
	my $hsh = shift;
	my $limit = shift;

	$hsh->{'random_id'} = 101;

	my ($h,$m,$s) = &getTime();
	$limit = int($s) unless ($limit);
	my $text = '';
	my @choice = (1..10);

	while ($limit > 0) {
		my $opt = $choice[ rand @choice ];
		my $num = (int("$h$limit") + int("$m$s"));
		my $elt = '';

		if ($opt == 1) {
			my $elt = $numEnd[ rand @numEnd ];
			my $ret = $newLines[ rand @newLines ];
			$text .= "$num$elt$ret";
		}
		elsif ($opt == 2) {
			my $elt = $numFront[ rand @numFront ];
			my $ret = $newLines[ rand @newLines ];
			$text .= "$elt$num$ret";
		}
		else {
			$text .= "$num ";
		}
		$limit--;
	}
	$hsh->{'line_text'} = $text;
}

# get a random page in text
sub random_102 {
	my $hsh = shift;
	$hsh->{'random_id'} = 102;
	my $clean_text = '';
	my $page = &wget_url();

	if ($page) {
		use HTML::Strip;
		my $hs = HTML::Strip->new();
		$clean_text = $hs->parse($page);
		$clean_text = &strip_email_addresses($clean_text);
		$clean_text = &strip_urls($clean_text);
		$hs->eof;
	}
	$hsh->{'line_text'} = $clean_text;
}

# get a random page in html
sub random_103 {
	my $hsh = shift;
	$hsh->{'random_id'} = 103;
	my $page = &wget_url();
	$hsh->{'line_text'} = $page;
}

# generate valid CSS
sub random_104 {
	my $hsh = shift;
	my $size = shift;

	$hsh->{'random_id'} = 104;
	if ($size) {
		# size = number of words / (average number of lines per selector block * words per line)
		$size = int($size / (8.2*2));
	}
	else {
		my @choices = (1..20);
		$size = $choices[rand @choices];
	}

	my $css = "<STYLE TYPE=\"text/css\">\n<!--\n";
	my $propVals = &load_css_hash();
	my @PVRange = (0..@{$propVals});
	my $selectors = &randomText($size);
	my @superSelectors = ('P.', 'UL.', 'OL.', 'DL.', 'PRE.', 'DIV.', 'CENTER.', 'BLOCKQUOTE.', 'FORM.', 'ISINDEX.', 'HR.', 'TABLE.', 'SPAN.', 'H1.', 'H2.', 'H3.', 'H4.', 'H5.', 'H6.', '#', '#', '#','#');
	my @SSRange = (0..50);

	# format
	# superselect.selector { property: value; }
	foreach $sel (@{$selectors}) {
		my $ssi = $SSRange[rand @SSRange];
		my $ss = $superSelectors[$ssi];
		$ss = '.' unless ($ss);
		$css .= "\n$ss$sel {\n";
		my $limit = join('', &rand_chars(set => 'numeric', min => 1, max => 1));
		for ($i = 0; $i <= $limit; $i++) {
			my $x = $PVRange[rand @PVRange];
			$css .= "\t$propVals->[$x]{'property'}: $propVals->[$x]{'value'};\n";
		}
		$css .= "}";
	}
	$hsh->{'line_text'} = $css . "\n-->\n</STYLE>\n";
}

# master generate HTML function
sub random_105 {
	my $hsh = shift;
	my $size = shift;

	$hsh->{'random_id'} = 105;

	my @elements = ();
	my %element_data = ();
	my $html_hash = &load_html_hash(\@elements, \%element_data);

	if ($size) {
		# size = number of words / (average number of words per block)
		$size = int($size / 40);
	}
	else {
		my @choices = (1..100);
		$size = $choices[rand @choices];
	}

	my $text = '';
	my $i = 0;

	# each element
	while ($i <= $size) {
		my $elm = $elements[rand @elements];

		# if its a parent element print it
		if ($element_data{$elm}{'parent'} eq 'YES') {
			$text .= &build_html_block(\%element_data, $elm, 1);
		}

		$i++;
	} # end element loop

	$hsh->{'line_text'} = $text;
}

# creates a string out of random words
sub random_106 {
	my $hsh = shift;
	my $size = shift;

	$hsh->{'random_id'} = 106;
	$size = 260 unless ($size);

	my $items = &randomAll($size);
	my $delim = $ascCodes->[rand @{$ascCodes}];
	my $str = join($delim, @{$items});
	$hsh->{'line_text'} = "</$str>";
}

# creates a bunch of images to empty graphics
sub random_107 {
	my $hsh = shift;
	my $size = shift;

	$hsh->{'random_id'} = 107;
	my $lines = int(join('', &rand_chars(set => 'numeric', min => 1, max => 2))) + 1;
	my $words = int($size / $lines);
	$words = 1 if ($words < 1);
	my $str = '';
	my $return = $returns->[rand @{$returns}];

	for (my $i = 1; $i <= $lines; $i++) {
		my $name = join('', &rand_chars(set => 'numeric', min => 5, max => 8));
		my $dom = join('', &rand_chars(set => 'alphanumeric', min => 2, max => 8));
		my $subdom = join('', &rand_chars(set => 'alphanumeric', min => 2, max => 8));
		my $random_words = &randomText($words);
		my $delimStr = join('/', @{$random_words});
		$str .= qq[<img name="$name" src="http://$subdom.$dom./$delimStr/spacer.gif">$return];
	}

	$hsh->{'line_text'} = $str;
}

# build fake image tag
sub random_108 {
	my $hsh = shift;
	my $size = shift;

	$hsh->{'random_id'} = 108;

	my $lines = int(join('', &rand_chars(set => 'numeric', min => 1, max => 2))) + 1;
	my $words = int($size / $lines);
	$words = 1 if ($words < 1);
	my $return = $returns->[rand @{$returns}];

	my $str = '';
	foreach (my $i=1; $i <= $lines; $i++) {
		my $firstWord = &randomText(2);
		my $items = &randomAll($words);
		my $delimStr = join('/', @{$items});
		my $img = join('', &rand_chars(set => 'alphanumeric', min => 2, max => 8));
		$str .= "<$firstWord->[0]/$delimStr/$img.gif\">$return";
	}

	$hsh->{'line_text'} = $str;
}

# generates a paragraph of just words, nothing else
sub random_109 {
	my $hsh = shift;
	my $size = shift;

	$hsh->{'random_id'} = 109;

	my $lines = int(join('', &rand_chars(set => 'numeric', min => 1, max => 2))) + 1;
	my $words = int($size / $lines);
	$words = 1 if ($words < 1);
	my $return = $returns->[rand @{$returns}];

	my $str = '';
	foreach (my $i=1; $i <= $lines; $i++) {
		my $items = &randomText($words);
		my $delimStr = join(' ', @{$items});
		$str .= "$delimStr$return";
	}

	$hsh->{'line_text'} = $str;
}

# creates a string out of random words
sub random_110 {
	my $hsh = shift;
	my $size = shift;

	$hsh->{'random_id'} = 110;

	my @choices = (50..260);
	$size = $choices[rand @choices] if (!$size);
	my $delim = $ascCodes->[rand @{$ascCodes}];
	my $items = &randomText($size);
	my $str = join($delim, @{$items});
	$hsh->{'line_text'} = "<$str>";
}

# creates a title tag with words in between
sub random_111 {
	my $hsh = shift;
	my $size = shift;

	$hsh->{'random_id'} = 111;

	my @choices = (50..260);
	$size = $choices[rand @choices] if (!$size);

	my $items = &randomText($size);
	my $delim = $ascCodes->[rand @{$ascCodes}];
	my $str = join($delim, @{$items});
	$hsh->{'line_text'} = "<title>$str</title>";
}

# build fake image tag 2
sub random_112 {
	my $hsh = shift;
	my $size = shift;

	$hsh->{'random_id'} = 112;

	my $lines = int(join('', &rand_chars(set => 'numeric', min => 1, max => 2))) + 1;
	my $words = int($size / $lines);
	$words = 1 if ($words < 1);
	my $return = $returns->[rand @{$returns}];

	my $str = '';
	foreach (my $i=1; $i <= $lines; $i++) {
		my $firstWord = &randomText(2);
		my $items = &randomAll($words);
		my $delimStr = join('/', @{$items});
		my $img = join('', &rand_chars(set => 'alphanumeric', min => 3, max => 8));
		$str .= "<img name=$firstWord->[0]/$delimStr/$img.gif\">$return";
	}

	$hsh->{'line_text'} = $str;
}

# build a list of broken br tags with space delimted text
sub random_113 {
	my $hsh = shift;
	my $size = shift;

	$hsh->{'random_id'} = 113;

	my $lines = int(join('', &rand_chars(set => 'numeric', min => 2, max => 3))) + 1;
	my $words = int($size / $lines) - 2;
	$words = 1 if ($words < 1);
	my $return = $returns->[rand @{$returns}];

	my $str = '';
	my @opens = ("<br ", " ", "\n<br ", "\n");
	my @closes = (" />", "<br />", " />\n", "<br />\n");
	foreach (my $i=1; $i <= $lines; $i++) {
		my $items = &randomText($words);
		my $delimStr = join(' ', @{$items});
		my $open = $opens[rand @opens];
		my $close = $closes[rand @closes];
		$str .= "$open$delimStr$close$return";
	}

	$hsh->{'line_text'} = $str;
}

# build a smaller html document with a table full of phoney links and images
sub random_114 {
	my $hsh = shift;
	my $size = shift;
	$size = ($size - 20) if ($size > 21);
	$hsh->{'random_id'} = 114;

	my $lines = int(join('', &rand_chars(set => 'numeric', min => 1, max => 2))) + 1;
	my $words = int($size / $lines);
	$words = 1 if ($words < 1);
	my $middle = '';

	foreach (my $i=1; $i <= $lines; $i++) {
		$words = ($words - 20) if ($words > 21);
		my $items = &randomText($words);
		my $delimStr = join('/', @{$items});
		my $img = join('', &rand_chars(set => 'alphanumeric', min => 2, max => 8));
		my $file1 = join('', &rand_chars(set => 'alphanumeric', min => 3, max => 8));
		my $file2 = join('', &rand_chars(set => 'alphanumeric', min => 3, max => 8));
		my $param = join('', &rand_chars(set => 'alphanumeric', min => 1, max => 8));
		my $link = join('', &rand_chars(set => 'alphanumeric', min => 3, max => 18));
		$middle .= "<tr>\n<td>\n<a href=\"http://DOMAIN/$file1.php?$param=$link\">\n<img src=\"http://DOMAIN/$delimStr/$file2.gif\" border=\"0\"></a>\n</td>\n</tr>\n";
	}

	my $title = &randomText(2);
	my $front = qq[<html>\n<head>\n<title>$title->[0] $title->[1]</title>\n\n<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">\n\n</head>\n\n<body>\n<table>\n\n];
	my $end = qq[</table>\n\n</body>\n\n</html>];

	$hsh->{'line_text'} = "$front$middle$end";
}

# style block with only period delimted strings, plus extra spacing
sub random_115 {
	my $hsh = shift;
	my $size = shift;

	$hsh->{'random_id'} = 115;

	my $lines = int(join('', &rand_chars(set => 'numeric', min => 2, max => 3))) + 1;
	my $words = int($size / $lines) - 3;
	$words = 1 if ($words < 1);
	my $return = $returns->[rand @{$returns}];

	my $txt = '';
	foreach (my $i=1; $i <= $lines; $i++) {
		my $items = &randomText($words);
		my $delimStr = join('.', @{$items});
		$txt .= "$delimStr$return";
	}

	$hsh->{'line_text'} = "<style>$return$txt</style>";
}

# style block with only period delimted strings, plus hyphen
sub random_116 {
	my $hsh = shift;
	my $size = shift;

	$hsh->{'random_id'} = 116;

	my $lines = int(join('', &rand_chars(set => 'numeric', min => 1, max => 3))) + 1;
	my $words = int($size / $lines);
	$words = 1 if ($words < 1);
	my $txt = '';
	my $return = $returns->[rand @{$returns}];

	foreach (my $i=1; $i <= $lines; $i++) {
		my $items = &randomText($words);
		my $delimStr = join('.', @{$items});
		$txt .= "$delimStr\t-$return-$return";
	}

	$hsh->{'line_text'} = "<style>\n\n\n$txt</style>";
}

# style block with only parentheses delimted strings, plus spacing
sub random_117 {
	my $hsh = shift;
	my $size = shift;

	$hsh->{'random_id'} = 117;

	my $lines = int(join('', &rand_chars(set => 'numeric', min => 1, max => 3))) + 1;
	my $words = int($size / $lines);
	$words = 1 if ($words < 1);
	my $txt = '';
	my $return = $returns->[rand @{$returns}];

	foreach (my $i=1; $i <= $lines; $i++) {
		my $items = &randomText($words);
		my $delimStr = join(')(', @{$items});
		my @opens = ('(','');
		my $open = $opens[rand @opens];
		$txt .= "$open$delimStr$return";
	}

	$hsh->{'line_text'} = "<style>$return$txt</style>";
}

# generate invalid CSS v1.0
sub random_118 {
	my $hsh = shift;
	my $size = shift;

	$hsh->{'random_id'} = 118;

	my $lines = int(join('', &rand_chars(set => 'numeric', min => 1, max => 2))) + 1;
	my @choices = (1..5);
	my $numPropVals = $choices[rand @choices];
	# size / lines - (definitions - words per definition) - "span"
	my $words = int(($size / $lines) - ($numPropVals*2.7) - 1);
	$words = 1 if ($words < 1);
	my $return = $returns->[rand @{$returns}];

	my $css = "<style>\n";
	my $propVals = &load_css_hash();

	# each definition
	foreach (my $i=1; $i <= $lines; $i++) {
		my $items = &randomText($words);
		my $delimStr = join('.', @{$items});
		$css .= "span.$delimStr\n\n\t{";

		# each property: value
		foreach (my $x=1; $x <= $numPropVals; $x++) {
			my $hsh = $propVals->[rand @{$propVals}];
			$css .= "$hsh->{'property'}:$hsh->{'value'};$return\t";
		}
		chop $css;
		chomp $css;
		chomp $css;
		$css .= "}\n\n";
	}

	$hsh->{'line_text'} = $css . "\n</style>";
}

# pick ONE random html tag, break it, fill it with forward slash crap, includes weirdo characters
sub random_119 {
	my $hsh = shift;
	my $size = shift;

	$hsh->{'random_id'} = 119;

	my @elements = ();
	my %element_data = ();
	my $html_hash = &load_html_hash(\@elements, \%element_data);

	$size = 1 if ($size < 1);
	my $element = $elements[rand @elements];
	my $items = &randomText($size, 'odd');
	my $delimStr = join('/', @{$items});

	$hsh->{'line_text'} = "<$element $delimStr>";
}

# pick MUTIPLE random html tags, break em, fill em with forward slash crap, includes weirdo characters
sub random_120 {
	my $hsh = shift;
	my $size = shift;

	$hsh->{'random_id'} = 120;

	my @elements = ();
	my %element_data = ();
	my $html_hash = &load_html_hash(\@elements, \%element_data);

	my $lines = int(join('', &rand_chars(set => 'numeric', min => 1, max => 3))) + 1;
	my $words = int($size / $lines) - 1;
	$words = 1 if ($words < 1);

	# each element
	my $str = '';
	foreach (my $i=1; $i <= $lines; $i++) {
		my $element = $elements[rand @elements];
		my $items = &randomText($words, 'odd');
		my $delimStr = join('/', @{$items});
		my $return = $returns->[rand @{$returns}];
		$str .= "<$element $delimStr>$return";
	}

	$hsh->{'line_text'} = $str;
}

# pick MUTIPLE random html end tags, break em, fill name with period slash crap, includes weirdo characters
sub random_121 {
	my $hsh = shift;
	my $size = shift;

	$hsh->{'random_id'} = 121;

	my @elements = ();
	my %element_data = ();
	my $html_hash = &load_html_hash(\@elements, \%element_data);

	my $lines = int(join('', &rand_chars(set => 'numeric', min => 1, max => 3))) + 1;
	my $words = int($size / $lines) - 1;
	$words = 1 if ($words < 1);

	# each element
	my $str = '';
	foreach (my $i=1; $i <= $lines; $i++) {
		my $element = $elements[rand @elements];
		my $items = &randomText($words, 'odd');
		my $delimStr = join('.', @{$items});
		my $return = $returns->[rand @{$returns}];
		$str .= "</$element name=\"$delimStr>$return";
	}

	$hsh->{'line_text'} = $str;
}

# creates multiple strings out of random words, plus odd characters
sub random_122 {
	my $hsh = shift;
	my $size = shift;

	$hsh->{'random_id'} = 122;
	my $lines = int(join('', &rand_chars(set => 'numeric', min => 1, max => 2))) + 1;
	my $words = int($size / $lines) - 1;
	$words = 1 if ($words < 1);

	my $joiner = $joiners[rand @joiners];

	my $str = '';
	foreach (my $i=1; $i <= $lines; $i++) {
		my $items = &randomText($words, 'odd');
		my $delimStr = join($joiner, @{$items});
		my $return = $returns->[rand @{$returns}];
		$str .= "$delimStr$return";
	}

	$hsh->{'line_text'} = $str;
}

# create multiple html links with element, attribute as random words, includes weird chars
sub random_123 {
	my $hsh = shift;
	my $size = shift;

	$hsh->{'random_id'} = 123;
	my $lines = int(join('', &rand_chars(set => 'numeric', min => 1, max => 2))) + 1;
	my $words = int($size / $lines) - 2;
	$words = 1 if ($words < 1);

	my $joiner = $joiners[rand @joiners];

	my $str = '';
	foreach (my $i=1; $i <= $lines; $i++) {
		my $items = &randomText($words, 'odd');
		my $w1 = pop(@{$items});
		my $w2 = pop(@{$items});
		my $delimStr = join($joiner, @{$items});
		my $return = $returns->[rand @{$returns}];
		$str .= "<$w1 $w2=\"$delimStr\">$return";
	}

	$hsh->{'line_text'} = $str;
}

# build a smaller html document with a table full of phoney links and images 2
sub random_124 {
	my $hsh = shift;
	my $size = shift;
	$size = ($size - 22) if ($size > 21);
	$hsh->{'random_id'} = 124;

	my $lines = int(join('', &rand_chars(set => 'numeric', min => 1, max => 3))) + 1;
	my $words = int($size / $lines);
	$words = 1 if ($words < 1);
	my $middle = '';

	foreach (my $i=1; $i <= $lines; $i++) {
		my $items = &randomText($words, 'odd');
		my $delimStr = join('/', @{$items});
		my $img = join('', &rand_chars(set => 'alphanumeric', min => 2, max => 8));
		my $file1 = join('', &rand_chars(set => 'alphanumeric', min => 3, max => 8));
		my $file2 = join('', &rand_chars(set => 'alphanumeric', min => 3, max => 8));
		my $sub = join('', &rand_chars(set => 'alphanumeric', min => 1, max => 8));
		my $param = join('', &rand_chars(set => 'alphanumeric', min => 1, max => 8));
		my $link = join('', &rand_chars(set => 'alphanumeric', min => 3, max => 18));
		my $num1 = join('', &rand_chars(set => 'numeric', min => 1, max => 2));
		my $num2 = join('', &rand_chars(set => 'numeric', min => 1, max => 2));
		$middle .= "\t<tr>\n\t\t<td>\n<a href=\"http://$sub.DOMAIN/link/$file1$param$link.html\">\n\t\t\t<img src=\"http://DOMAIN/$delimStr/$file2.gif\"width=\"0\" border=\"$num1\" height=\"$num2\"></a>\n</td>\n</tr>\n";
	}

	my $title = &randomText(2);
	my $front = qq[<html>\n<head>\n<title>$title->[0]$title->[1]</title>\n\n<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">\n\n</head>\n\n<body>\n<table>\n\n];
	my $end = qq[</table>\n\n</body>\n\n</html>];

	$hsh->{'line_text'} = "$front$middle$end";
}

# build fake image tag 3
sub random_125 {
	my $hsh = shift;
	my $size = shift;

	$hsh->{'random_id'} = 125;

	my $lines = int(join('', &rand_chars(set => 'numeric', min => 1, max => 2))) + 1;
	my $words = int($size / $lines);
	$words = 1 if ($words < 1);
	my $return = $returns->[rand @{$returns}];

	my $str = '';
	foreach (my $i=1; $i <= $lines; $i++) {
		my $firstWord = &randomText(2);
		my $items = &randomAll($words);
		my $delimStr = join('/', @{$items});
		my $img = join('', &rand_chars(set => 'alphanumeric', min => 3, max => 8));
		$str .= "<img name='$firstWord->[0]'/$delimStr/$img$return";
	}

	$hsh->{'line_text'} = $str;
}

# number strings, odd phone numbers
sub random_126 {
	my $hsh = shift;
	my $size = shift;

	$hsh->{'random_id'} = 126;

	my $lines = int(join('', &rand_chars(set => 'numeric', min => 1, max => 2))) + 1;
	my $words = int($size / $lines);
	$words = 1 if ($words < 1);

	my @opens = ('[','|','%','*','(',':',' ');
	my @closes = (']','|','%','*',')',':',' ');
	my $return = $returns->[rand @{$returns}];

	my $str = '';
	foreach (my $i=1; $i <= $lines; $i++) {
		my $items = &randomNums($words);
		foreach my $item (@{$items}) {
			my $open = $opens[rand @opens];
			my $close = $closes[rand @closes];
			$str .= "$open$item$close";
		}
		$str .= "$return";
	}

	$hsh->{'line_text'} = $str;
}

# phone numbers
sub random_127 {
	my $hsh = shift;
	my $size = shift;

	$hsh->{'random_id'} = 127;

	my $words = 2;
	my $lines = int($size / $words)+2;
	my $return = $returns->[rand @{$returns}];

	my $str = '';
	foreach (my $i=1; $i <= $lines; $i++) {
		my $area = join('', &rand_chars(set => 'numeric', min => 3, max => 3));
		my $pre = join('', &rand_chars(set => 'numeric', min => 3, max => 3));
		my $suff = join('', &rand_chars(set => 'numeric', min => 4, max => 4));
		$str .= "($area) $pre-$suff$return";
	}

	$hsh->{'line_text'} = $str;
}

# string off words and random spacing, random odd delim
sub random_128 {
	my $hsh = shift;
	my $size = shift;

	$hsh->{'random_id'} = 128;

	my $lines = int(join('', &rand_chars(set => 'numeric', min => 1, max => 2))) + 1;
	my $words = int($size / $lines);
	$words = 1 if ($words < 1);

	my $delim = $ascCodes->[rand @{$ascCodes}];
	my $return = $returns->[rand @{$returns}];

	my $str = '';
	foreach (my $i=1; $i <= $lines; $i++) {
		my $items = &randomText($words, 'odd');
		my $delimStr = join($delim, @{$items});
		$str .= "$delimStr$return";
	}

	$hsh->{'line_text'} = $str;
}

return 1;
