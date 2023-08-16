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
# * name (Str) — Name of type.
# * args (ArrayRef) — List of type arguments.
# * init (CodeRef) — Initializer for type.
# * test (CodeRef) — Values cheker.
# * a_test (CodeRef) — Values cheker for types with optional arguments.
# * coerce (ArrayRef[Tuple[Aion::Type, CodeRef]]) — Array of pairs: type and via.
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
my $Range = Aion::Type->new(
    name => "Range",
    args => [3, 5],
    init => sub {
        @{$Aion::Type::SELF}{qw/min max/} = @{$Aion::Type::SELF->{args}};
    },
    test => sub { $Aion::Type::SELF->{min} <= $_ <= $Aion::Type::SELF->{max} },
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
# ## detail ($element, $feature)
# 
# Return message belongs to error.
# 
done_testing; }; subtest 'detail ($element, $feature)' => sub { 
my $Int = Aion::Type->new(name => "Int");

is scalar do {$Int->detail(-5, "Feature car")}, "Feature car must have the type Int. The it is -5", '$Int->detail(-5, "Feature car") # => Feature car must have the type Int. The it is -5';

my $Num = Aion::Type->new(name => "Num", detail => sub {
    my ($val, $name) = @_;
    "Error: $val is'nt $name!"
});

is scalar do {$Num->detail("x", "car")}, "Error: x is'nt car!", '$Num->detail("x", "car")  # => Error: x is\'nt car!';

# 
# ## validate ($element, $feature)
# 
# It tested `$element` and throw `detail` if element is exclude from class.
# 
done_testing; }; subtest 'validate ($element, $feature)' => sub { 
my $PositiveInt = Aion::Type->new(
    name => "PositiveInt",
    test => sub { /^\d+$/ },
);

eval {
    $PositiveInt->validate(-1, "Neg")
};
like scalar do {$@}, qr!Neg must have the type PositiveInt. The it is -1!, '$@   # ~> Neg must have the type PositiveInt. The it is -1';

# 
# ## val_to_str ($element)
# 
# Translate `$val` to string.
# 
done_testing; }; subtest 'val_to_str ($element)' => sub { 
is scalar do {Aion::Type->val_to_str([1,2,{x=>6}])}, "[\n    [0] 1,\n    [1] 2,\n    [2] {\n            x   6\n        }\n]", 'Aion::Type->val_to_str([1,2,{x=>6}])   # => [\n    [0] 1,\n    [1] 2,\n    [2] {\n            x   6\n        }\n]';

# 
# ## make ($pkg)
# 
# It make subroutine without arguments, who return type.
# 
done_testing; }; subtest 'make ($pkg)' => sub { 
BEGIN {
    Aion::Type->new(name=>"Rim", test => sub { /^[IVXLCDM]+$/i })->make;
}

is scalar do {"IX" ~~ Rim}, "1", '"IX" ~~ Rim     # => 1';

# 
# ## make_arg ($pkg)
# 
# It make subroutine with arguments, who return type.
# 
done_testing; }; subtest 'make_arg ($pkg)' => sub { 
BEGIN {
    Aion::Type->new(name=>"Len", test => sub {
        $Aion::Type::SELF->{args}[0] <= length($_) <= $Aion::Type::SELF->{args}[1]
    })->make_arg;
}

is scalar do {"IX" ~~ Len[2,2]}, "1", '"IX" ~~ Len[2,2]    # => 1';

# 
# ## make_maybe_arg ($pkg)
# 
# It make subroutine with or without arguments, who return type.
# 
done_testing; }; subtest 'make_maybe_arg ($pkg)' => sub { 
BEGIN {
    Aion::Type->new(
        name=>"Enum123",
        test => sub { $_ ~~ [1,2,3] },
        a_test => sub { $_ ~~ $Aion::Type::SELF->{args} },
    )->make_maybe_arg;
}

is scalar do {3 ~~ Enum123}, scalar do{1}, '3 ~~ Enum123            # -> 1';
is scalar do {3 ~~ Enum123[4,5,6]}, scalar do{""}, '3 ~~ Enum123[4,5,6]     # -> ""';
is scalar do {5 ~~ Enum123[4,5,6]}, scalar do{1}, '5 ~~ Enum123[4,5,6]     # -> 1';

# 
# # OPERATORS
# 
# ## &{}
# 
# It make the object is callable.
# 
done_testing; }; subtest '&{}' => sub { 
my $PositiveInt = Aion::Type->new(
    name => "PositiveInt",
    test => sub { /^\d+$/ },
);

local $_ = 10;
is scalar do {$PositiveInt->()}, scalar do{1}, '$PositiveInt->()    # -> 1';

$_ = -1;
is scalar do {$PositiveInt->()}, scalar do{""}, '$PositiveInt->()    # -> ""';

# 
# ## ""
# 
# Stringify object.
# 
done_testing; }; subtest '""' => sub { 
is scalar do {Aion::Type->new(name => "Int") . ""}, "Int", 'Aion::Type->new(name => "Int") . ""   # => Int';

my $Enum = Aion::Type->new(name => "Enum", args => [qw/A B C/]);

is scalar do {"$Enum"}, "Enum['A', 'B', 'C']", '"$Enum" # => Enum[\'A\', \'B\', \'C\']';

# 
# ## $a | $b
# 
# It make new type as union of `$a` and `$b`.
# 
done_testing; }; subtest '$a | $b' => sub { 
my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
my $Char = Aion::Type->new(name => "Char", test => sub { /^.\z/ });

my $IntOrChar = $Int | $Char;

is scalar do {77   ~~ $IntOrChar}, "1", '77   ~~ $IntOrChar # => 1';
is scalar do {"a"  ~~ $IntOrChar}, "1", '"a"  ~~ $IntOrChar # => 1';
is scalar do {"ab" ~~ $IntOrChar}, scalar do{""}, '"ab" ~~ $IntOrChar # -> ""';

# 
# ## $a & $b
# 
# It make new type as intersection of `$a` and `$b`.
# 
done_testing; }; subtest '$a & $b' => sub { 
my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
my $Char = Aion::Type->new(name => "Char", test => sub { /^.\z/ });

my $Digit = $Int & $Char;

is scalar do {7  ~~ $Digit}, "1", '7  ~~ $Digit # => 1';
is scalar do {77 ~~ $Digit}, scalar do{""}, '77 ~~ $Digit # -> ""';

# 
# ## ~ $a
# 
# It make exclude type from `$a`.
# 
done_testing; }; subtest '~ $a' => sub { 
my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });

is scalar do {"a" ~~ ~$Int;}, "1", '"a" ~~ ~$Int; # => 1';
is scalar do {5   ~~ ~$Int;}, scalar do{""}, '5   ~~ ~$Int; # -> ""';

# 
# # AUTHOR
# 
# Yaroslav O. Kosmina [dart@cpan.org](mailto:dart@cpan.org)
# 
# # LICENSE
# 
# ⚖ **GPLv3**
	done_testing;
};

done_testing;
