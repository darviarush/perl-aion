use common::sense; use open qw/:std :utf8/; use Test::More 0.98; use Carp::Always::Color; sub _mkpath_ { my ($p) = @_; length($`) && !-e $`? mkdir($`, 0755) || die "mkdir $`: $!": () while $p =~ m!/!g; $p } BEGIN { my $t = `pwd`; chop $t; $t .= '/' . __FILE__; my $s = '/tmp/.liveman/perl-aion/aion/type/'; `rm -fr $s` if -e $s; chdir _mkpath_($s) or die "chdir $s: $!"; open my $__f__, "<:utf8", $t or die "Read $t: $!"; $s = join "", <$__f__>; close $__f__; while($s =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { my ($file, $code) = ($1, $2); $code =~ s/^#>> //mg; open my $__f__, ">:utf8", _mkpath_($file) or die "Write $file: $!"; print $__f__ $code; close $__f__; } } # # NAME
# 
# Aion::Type - class of validators.
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Type;

my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
is scalar do {12   ~~ $Int}, "1", '12   ~~ $Int # => 1';
is scalar do {12.1 ~~ $Int}, scalar do{""}, '12.1 ~~ $Int # -> ""';

my $Char = Aion::Type->new(name => "Char", test => sub { /^.\z/ });
is scalar do {$Char->include("a")}, "1", '$Char->include("a")     # => 1';
is scalar do {$Char->exclude("ab")}, "1", '$Char->exclude("ab")    # => 1';

my $IntOrChar = $Int | $Char;
is scalar do {77   ~~ $IntOrChar}, "1", '77   ~~ $IntOrChar # => 1';
is scalar do {"a"  ~~ $IntOrChar}, "1", '"a"  ~~ $IntOrChar # => 1';
is scalar do {"ab" ~~ $IntOrChar}, scalar do{""}, '"ab" ~~ $IntOrChar # -> ""';

my $Digit = $Int & $Char;
is scalar do {7  ~~ $Digit}, "1", '7  ~~ $Digit # => 1';
is scalar do {77 ~~ $Digit}, scalar do{""}, '77 ~~ $Digit # -> ""';

is scalar do {"a" ~~ ~$Int;}, "1", '"a" ~~ ~$Int; # => 1';
is scalar do {5   ~~ ~$Int;}, scalar do{""}, '5   ~~ ~$Int; # -> ""';

# 
# ## 
# 
# # METHODS
# 
# ## new (%ARGUMENTS)
# 
# Constructor.
# 
# ### ARGUMENTS
# 
# #### name
# 
# Name of type.
# 
# #### args
# 
# List of type arguments.
# 
# #### test
# 
# Subroutine for check value.
# 
# ## stringify
# 
# Stringify of object (name with arguments):
# 
done_testing; }; subtest 'stringify' => sub { 
my $Int = Aion::Type->new(
    name => "Int",
    args => [3, 5],
);

is scalar do {$Int->stringify}, "Int[3, 5]", '$Int->stringify  #=> Int[3, 5]';

# 
# ## test
# 
# Testing the `$_` belongs to the class.
# 
done_testing; }; subtest 'test' => sub { 
my $PositiveInt = Aion::Type->new(
    name => "PositiveInt",
    test => sub { /^\d+$/ },
);

local $_ = 5;
is scalar do {$PositiveInt->test}, scalar do{1}, '$PositiveInt->test  # -> 1';
local $_ = -6;
is scalar do {$PositiveInt->test}, scalar do{""}, '$PositiveInt->test  # -> ""';

# 
# ## init
# 
# Initial the validator.
# 
done_testing; }; subtest 'init' => sub { 
use DDP;
my $Range = Aion::Type->new(
    name => "Range",
    args => [3, 5],
    init => sub {
        p my $x=$Aion::Type::SELF->{args};
        @{$Aion::Type::SELF}{qw/min max/} = @{$Aion::Type::SELF->{args}};
        my %x=%$Aion::Type::SELF;
        p %x;
    },
    test => sub { p $Aion::Type::SELF->{min}; $Aion::Type::SELF->{min} <= $_ <= $Aion::Type::SELF->{max} },
);

$Range->init;

is scalar do {3 ~~ $Range}, scalar do{1}, '3 ~~ $Range  # -> 1';
is scalar do {4 ~~ $Range}, scalar do{1}, '4 ~~ $Range  # -> 1';
is scalar do {5 ~~ $Range}, scalar do{1}, '5 ~~ $Range  # -> 1';

is scalar do {2 ~~ $Range}, scalar do{""}, '2 ~~ $Range  # -> ""';
is scalar do {6 ~~ $Range}, scalar do{""}, '6 ~~ $Range  # -> ""';

# 
# 
# ## include ($element)
# 
# checks whether the argument belongs to the class.
# 
done_testing; }; subtest 'include ($element)' => sub { 
my $PositiveInt = Aion::Type->new(
    name => "PositiveInt",
    test => sub { /^\d+$/ },
);

is scalar do {$PositiveInt->include(5)}, scalar do{1}, '$PositiveInt->include(5) # -> 1';
is scalar do {$PositiveInt->include(-6)}, scalar do{""}, '$PositiveInt->include(-6) # -> ""';

# 
# ## exclude ($element)
# 
# Checks that the argument does not belong to the class.
# 
done_testing; }; subtest 'exclude ($element)' => sub { 
my $PositiveInt = Aion::Type->new(
    name => "PositiveInt",
    test => sub { /^\d+$/ },
);

is scalar do {$PositiveInt->exclude(5)}, scalar do{""}, '$PositiveInt->exclude(5)  # -> ""';
is scalar do {$PositiveInt->exclude(-6)}, scalar do{1}, '$PositiveInt->exclude(-6) # -> 1';

# 
# 
# # OPERATORS
# 
# ## &{}
# 
# It make the object is callable.
# 
# ## ""
# 
# Stringify object.
# 
# ## $a | $b
# 
# It make new type as union of `$a` and `$b`.
# 
# ## $a & $b
# 
# It make new type as intersection of `$a` and `$b`.
# 
# ## ~ $a
# 
# It make exclude type from `$a`.
# 

	done_testing;
};

done_testing;
