use common::sense; use open qw/:std :utf8/; use Test::More 0.98; use Carp::Always::Color; sub _mkpath_ { my ($p) = @_; length($`) && !-e $`? mkdir($`, 0755) || die "mkdir $`: $!": () while $p =~ m!/!g; $p } BEGIN { my $t = `pwd`; chop $t; $t .= '/' . __FILE__; my $s = '/tmp/.liveman/perl-aion/aion/types/'; `rm -fr $s` if -e $s; chdir _mkpath_($s) or die "chdir $s: $!"; open my $__f__, "<:utf8", $t or die "Read $t: $!"; $s = join "", <$__f__>; close $__f__; while($s =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { my ($file, $code) = ($1, $2); $code =~ s/^#>> //mg; open my $__f__, ">:utf8", _mkpath_($file) or die "Write $file: $!"; print $__f__ $code; close $__f__; } } # # NAME
# 
# Aion::Types is library of validators. And it makes new validators.
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Types;

BEGIN {
    subtype SpeakOfKitty => as StrMatch[qr/\bkitty\b/i],
        message { "Speak is'nt included kitty!" };
}

is scalar do {"Kitty!" ~~ SpeakOfKitty}, scalar do{1}, '"Kitty!" ~~ SpeakOfKitty # -> 1';
is scalar do {"abc" ~~ SpeakOfKitty}, scalar do{""}, '"abc" ~~ SpeakOfKitty 	 # -> ""';

like scalar do {eval { SpeakOfKitty->validate("abc", "This") }; "$@"}, qr!Speak is'nt included kitty\!!, 'eval { SpeakOfKitty->validate("abc", "This") }; "$@" # ~> Speak is\'nt included kitty!';


BEGIN {
	subtype IntOrArrayRef => as (Int | ArrayRef);
}

is scalar do {[] ~~ IntOrArrayRef}, scalar do{1}, '[] ~~ IntOrArrayRef  # -> 1';
is scalar do {35 ~~ IntOrArrayRef}, scalar do{1}, '35 ~~ IntOrArrayRef  # -> 1';
is scalar do {"" ~~ IntOrArrayRef}, scalar do{""}, '"" ~~ IntOrArrayRef  # -> ""';


coerce IntOrArrayRef, from Num, via { int($_ + .5) };

is scalar do {IntOrArrayRef->coerce(5.5)}, "6", 'IntOrArrayRef->coerce(5.5) # => 6';

# 
# # DESCRIPTION
# 
# This modile export subroutines:
# 
# * `subtype`, `as`, `init_where`, `where`, `awhere`, `message` — for create validators.
# * `SELF`, `ARGS`, `A`, `B`, `C`, `D` — for use in validators has arguments.
# * `coerce`, `from`, `via` — for create coerce, using for translate values from one class to other class.
# 
# Hierarhy of validators:
# 

# Any
# 	Control
# 		Union[A, B...]
# 		Intersection[A, B...]
# 		Exclude[A, B...]
# 		Option[A]
# 		Wantarray[A, S]
# 	Array`[A]
# 		ATuple[A...]
# 		ACycleTuple[A...]
# 	Hash`[A]
# 		HMap[K, V]
# 	Item
# 		Bool
# 		Enum[A...]
# 		Maybe[A]
# 		Undef
# 		Defined
# 			Value
# 				Version
# 				Str`[A, B?]
# 					Uni
# 					Bin`[A, B?]
# 					NonEmptyStr`[A, B?]
# 					Email
# 					Tel
# 					Url
# 					Path
# 					Html
# 					StrDate
# 					StrDateTime
# 					StrMatch[qr/.../]
# 					ClassName[A]
# 					RoleName[A]
# 					Numeric
# 						Num
# 							PositiveNum
# 							Float
# 							Range[from, to]
# 							Int`[N]
# 								PositiveInt`[N]
# 								Nat`[N]
# 			Ref
# 				Tied`[A]
# 				LValueRef
# 				FormatRef
# 				CodeRef
# 				RegexpRef
# 				ScalarRef`[A]
# 				RefRef`[A]
# 				GlobRef`[A]
# 				ArrayRef`[A]
# 				HashRef`[H]
# 				Object`[O]
# 				Map[K, V]
# 				Tuple[A...]
# 				CycleTuple[A...]
# 				Dict[k => A, ...]
# 			Like
# 				HasMethods[m...]
# 				Overload`[m...]
# 				InstanceOf[A...]
# 				ConsumerOf[A...]
# 			StrLike
# 			RegexpLike
# 			CodeLike
# 			ArrayLike`[A]
# 			HashLike`[A]

# 
# # SUBROUTINES
# 
# ## subtype ($name, @paraphernalia)
# 
# Make new type.
# 
done_testing; }; subtest 'subtype ($name, @paraphernalia)' => sub { 
BEGIN {
	subtype One => where { $_ == 1 } message { "Actual 1 only!" };
}

is scalar do {1 ~~ One}, scalar do{1}, '1 ~~ One 	# -> 1';
is scalar do {0 ~~ One}, scalar do{""}, '0 ~~ One 	# -> ""';
like scalar do {eval { One->validate(0) }; $@}, qr!Actual 1 only\!!, 'eval { One->validate(0) }; $@ # ~> Actual 1 only!';

# 
# ## as ($parenttype)
# 
# Use with `subtype` for extended create type of `$parenttype`.
# 
# ## init_where ($code)
# 
# Initialize type with new arguments. Use with `subtype`.
# 
done_testing; }; subtest 'init_where ($code)' => sub { 
BEGIN {
	subtype 'LessThen[A]',
		init_where { Num->validate(A, "Argument LessThen[A]") }
		where { $_ < A };
}

like scalar do {eval { LessThen["string"] }; $@}, qr!Argument LessThen\[A\]!, 'eval { LessThen["string"] }; $@  # ~> Argument LessThen\[A\]';

is scalar do {5 ~~ LessThen[5]}, scalar do{""}, '5 ~~ LessThen[5]  # -> ""';

# 
# ## where ($code)
# 
# Set in type `$code` as test. Value for test set in `$_`.
# 
done_testing; }; subtest 'where ($code)' => sub { 
BEGIN {
	subtype 'Two',
		where { $_ == 2 };
}

is scalar do {2 ~~ Two}, scalar do{1}, '2 ~~ Two # -> 1';
is scalar do {3 ~~ Two}, scalar do{""}, '3 ~~ Two # -> ""';

# 
# Use with `subtype`. Need if is the required arguments.
# 

like scalar do {eval { subtype 'Ex[A]' }; $@}, qr!subtype Ex\[A\]: needs a where!, 'eval { subtype \'Ex[A]\' }; $@  # ~> subtype Ex\[A\]: needs a where';

# 
# ## awhere ($code)
# 
# If type maybe with and without arguments, then use for set test with arguments, and `where` - without.
# 
done_testing; }; subtest 'awhere ($code)' => sub { 
BEGIN {
	subtype 'GreatThen`[A]',
		where { $_ > 0 }
		awhere { $_ > A }
	;
}

is scalar do {0 ~~ GreatThen}, scalar do{""}, '0 ~~ GreatThen    # -> ""';
is scalar do {1 ~~ GreatThen}, scalar do{1}, '1 ~~ GreatThen    # -> 1';

is scalar do {3 ~~ GreatThen[3]}, scalar do{""}, '3 ~~ GreatThen[3] # -> ""';
is scalar do {4 ~~ GreatThen[3]}, scalar do{1}, '4 ~~ GreatThen[3] # -> 1';

# 
# Use with `subtype`. Need if arguments is optional.
# 

like scalar do {eval { subtype 'Ex`[A]', where {} }; $@}, qr!subtype Ex`\[A\]: needs a awhere!, 'eval { subtype \'Ex`[A]\', where {} }; $@  # ~> subtype Ex`\[A\]: needs a awhere';
like scalar do {eval { subtype 'Ex', awhere {} }; $@}, qr!subtype Ex: awhere is excess!, 'eval { subtype \'Ex\', awhere {} }; $@  # ~> subtype Ex: awhere is excess';

# 
# ## SELF
# 
# The current type. `SELF` use in `init_where`, `where` and `awhere`.
# 
# ## ARGS
# 
# Arguments of the current type. In scalar context returns array ref on the its. And in array context returns its. Use in `init_where`, `where` and `awhere`.
# 
# ## A, B, C, D
# 
# First, second, third and fifth argument of the type.
# 
done_testing; }; subtest 'A, B, C, D' => sub { 
BEGIN {
	subtype "Seria[A,B,C,D]", where { A < B < $_ < C < D };
}

is scalar do {2.5 ~~ Seria[1,2,3,4]}, scalar do{1}, '2.5 ~~ Seria[1,2,3,4]   # -> 1';

# 
# Use in `init_where`, `where` and `awhere`.
# 
# ## message ($code)
# 
# Use with `subtype` for make the message on error, if the value excluded the type. In `$code` use subroutine: `SELF` - the current type, `ARGS`, `A`, `B`, `C`, `D` - arguments of type (if is), and the testing value in `$_`. It can be stringified using `SELF->val_to_str($_)`.
# 
# ## coerce ($type, from => $from, via => $via)
# 
# It add new coerce ($via) to `$type` from `$from`-type.
# 
# ## from ($type)
# 
# Syntax sugar for `coerce`.
# 
# ## via ($code)
# 
# Syntax sugar for `coerce`.
# 
# # ATTRIBUTES
# 
# ## Isa (@signature)
# 
# Check the subroutine signature: arguments and returns.
# 
done_testing; }; subtest 'Isa (@signature)' => sub { 
sub minint($$) : Isa(Int => Int => Int) {
	my ($x, $y) = @_;
	$x < $y? $x : $y
}

is scalar do {minint 6, 5;}, scalar do{5}, 'minint 6, 5; # -> 5';
like scalar do {eval {minint 5.5, 2}; $@}, qr!Arguments of method `minint` must have the type Tuple\[Int, Int\]\.!, 'eval {minint 5.5, 2}; $@ # ~> Arguments of method `minint` must have the type Tuple\[Int, Int\]\.';

# 
# # TYPES
# 
# ## Any
# 
# Top-level type in the hierarchy. Match all.
# 
# ## Control
# 
# Top-level type in the hierarchy constructors new types from any types.
# 
# ## Union[A, B...]
# 
# Union many types. It analog operator `$type1 | $type2`.
# 
done_testing; }; subtest 'Union[A, B...]' => sub { 
is scalar do {33  ~~ Union[Int, Ref]}, scalar do{1}, '33  ~~ Union[Int, Ref]    # -> 1';
is scalar do {[]  ~~ Union[Int, Ref]}, scalar do{1}, '[]  ~~ Union[Int, Ref]    # -> 1';
is scalar do {"a" ~~ Union[Int, Ref]}, scalar do{""}, '"a" ~~ Union[Int, Ref]    # -> ""';

# 
# ## Intersection[A, B...]
# 
# Intersection many types. It analog operator `$type1 & $type2`.
# 
done_testing; }; subtest 'Intersection[A, B...]' => sub { 
is scalar do {15 ~~ Intersection[Int, StrMatch[/5/]]}, scalar do{1}, '15 ~~ Intersection[Int, StrMatch[/5/]]    # -> 1';

# 
# ## Exclude[A, B...]
# 
# Exclude many types. It analog operator `~ $type`.
# 
done_testing; }; subtest 'Exclude[A, B...]' => sub { 
is scalar do {-5  ~~ Exclude[PositiveInt]}, scalar do{1}, '-5  ~~ Exclude[PositiveInt]    # -> 1';
is scalar do {"a" ~~ Exclude[PositiveInt]}, scalar do{1}, '"a" ~~ Exclude[PositiveInt]    # -> 1';
is scalar do {5   ~~ Exclude[PositiveInt]}, scalar do{""}, '5   ~~ Exclude[PositiveInt]    # -> ""';
is scalar do {5.5 ~~ Exclude[PositiveInt]}, scalar do{1}, '5.5 ~~ Exclude[PositiveInt]    # -> 1';

# 
# If `Exclude` has many arguments, then this analog `~ ($type1 | $type2 ...)`.
# 

is scalar do {-5  ~~ Exclude[PositiveInt, Enum[-2]]}, scalar do{1}, '-5  ~~ Exclude[PositiveInt, Enum[-2]]    # -> 1';
is scalar do {-2  ~~ Exclude[PositiveInt, Enum[-2]]}, scalar do{""}, '-2  ~~ Exclude[PositiveInt, Enum[-2]]    # -> ""';
is scalar do {0   ~~ Exclude[PositiveInt, Enum[-2]]}, scalar do{""}, '0   ~~ Exclude[PositiveInt, Enum[-2]]    # -> ""';

# 
# ## Option[A]
# 
# The optional keys in the `Dict`.
# 
done_testing; }; subtest 'Option[A]' => sub { 
is scalar do {{a=>55} ~~ Dict[a=>Int, b => Option[Int]]}, scalar do{1}, '{a=>55} ~~ Dict[a=>Int, b => Option[Int]] # -> 1';
is scalar do {{a=>55, b=>31} ~~ Dict[a=>Int, b => Option[Int]]}, scalar do{1}, '{a=>55, b=>31} ~~ Dict[a=>Int, b => Option[Int]] # -> 1';

# 
# ## Wantarray[A, S]
# 
# if the subroutine returns different values in the context of an array and a scalar, then using type `Wantarray` with type `A` for array context and type `S` for scalar context.
# 
done_testing; }; subtest 'Wantarray[A, S]' => sub { 
sub arr : Isa(PositiveInt => Wantarray[ArrayRef[PositiveInt], PositiveInt]) {
	my ($n) = @_;
	wantarray? 1 .. $n: $n
}

my @a = arr(3);
my $s = arr(3);

is_deeply scalar do {\@a}, scalar do {[1,2,3]}, '\@a  # --> [1,2,3]';
is scalar do {$s}, scalar do{3}, '$s	 # -> 3';

# 
# ## Item
# 
# Top-level type in the hierarchy scalar types.
# 
# ## Bool
# 
# `1` is true. `0`, `""` or `undef` is false.
# 
done_testing; }; subtest 'Bool' => sub { 
is scalar do {1 ~~ Bool}, scalar do{1}, '1 ~~ Bool     # -> 1';
is scalar do {0 ~~ Bool}, scalar do{1}, '0 ~~ Bool     # -> 1';
is scalar do {undef ~~ Bool}, scalar do{1}, 'undef ~~ Bool # -> 1';
is scalar do {"" ~~ Bool}, scalar do{1}, '"" ~~ Bool    # -> 1';

is scalar do {2 ~~ Bool}, scalar do{""}, '2 ~~ Bool     # -> ""';

# 
# ## Enum[A...]
# 
# Enumerate values.
# 
done_testing; }; subtest 'Enum[A...]' => sub { 
is scalar do {3 ~~ Enum[1,2,3]}, scalar do{1}, '3 ~~ Enum[1,2,3]        	# -> 1';
is scalar do {"cat" ~~ Enum["cat", "dog"]}, scalar do{1}, '"cat" ~~ Enum["cat", "dog"] # -> 1';
is scalar do {4 ~~ Enum[1,2,3]}, scalar do{""}, '4 ~~ Enum[1,2,3]        	# -> ""';

# 
# ## Maybe[A]
# 
# `undef` or type in `[]`.
# 
done_testing; }; subtest 'Maybe[A]' => sub { 
is scalar do {undef ~~ Maybe[Int]}, scalar do{1}, 'undef ~~ Maybe[Int]    # -> 1';
is scalar do {4 ~~ Maybe[Int]}, scalar do{1}, '4 ~~ Maybe[Int]        # -> 1';
is scalar do {"" ~~ Maybe[Int]}, scalar do{""}, '"" ~~ Maybe[Int]       # -> ""';

# 
# ## Undef
# 
# `undef` only.
# 
done_testing; }; subtest 'Undef' => sub { 
is scalar do {undef ~~ Undef}, scalar do{1}, 'undef ~~ Undef    # -> 1';
is scalar do {0 ~~ Undef}, scalar do{""}, '0 ~~ Undef        # -> ""';

# 
# ## Defined
# 
# All exclude `undef`.
# 
done_testing; }; subtest 'Defined' => sub { 
is scalar do {\0 ~~ Defined}, scalar do{1}, '\0 ~~ Defined       # -> 1';
is scalar do {undef ~~ Defined}, scalar do{""}, 'undef ~~ Defined    # -> ""';

# 
# ## Value
# 
# Defined unreference values.
# 
done_testing; }; subtest 'Value' => sub { 
is scalar do {3 ~~ Value}, scalar do{1}, '3 ~~ Value        # -> 1';
is scalar do {\3 ~~ Value}, scalar do{""}, '\3 ~~ Value       # -> ""';
is scalar do {undef ~~ Value}, scalar do{""}, 'undef ~~ Value    # -> ""';

# 
# ## Version
# 
# Perl versions.
# 
done_testing; }; subtest 'Version' => sub { 
is scalar do {1.1.0 ~~ Version}, scalar do{1}, '1.1.0 ~~ Version    # -> 1';
is scalar do {v1.1.0 ~~ Version}, scalar do{1}, 'v1.1.0 ~~ Version   # -> 1';
is scalar do {1.1 ~~ Version}, scalar do{""}, '1.1 ~~ Version      # -> ""';
is scalar do {"1.1.0" ~~ Version}, scalar do{""}, '"1.1.0" ~~ Version  # -> ""';

# 
# ## Str`[A, B?]
# 
# Strings, include numbers.
# It maybe define maximal, or minimal and maximal length.
# 
done_testing; }; subtest 'Str`[A, B?]' => sub { 
is scalar do {1.1 ~~ Str}, scalar do{1}, '1.1 ~~ Str         # -> 1';
is scalar do {"" ~~ Str}, scalar do{1}, '"" ~~ Str          # -> 1';
is scalar do {1.1.0 ~~ Str}, scalar do{""}, '1.1.0 ~~ Str       # -> ""';
is scalar do {"1234" ~~ Str[3]}, scalar do{""}, '"1234" ~~ Str[3]   # -> ""';
is scalar do {"123" ~~ Str[3]}, scalar do{1}, '"123" ~~ Str[3]    # -> 1';
is scalar do {"12" ~~ Str[3]}, scalar do{1}, '"12" ~~ Str[3]     # -> 1';
is scalar do {"" ~~ Str[1, 2]}, scalar do{""}, '"" ~~ Str[1, 2]    # -> ""';
is scalar do {"1" ~~ Str[1, 2]}, scalar do{1}, '"1" ~~ Str[1, 2]   # -> 1';
is scalar do {"12" ~~ Str[1, 2]}, scalar do{1}, '"12" ~~ Str[1, 2]   # -> 1';
is scalar do {"123" ~~ Str[1, 2]}, scalar do{""}, '"123" ~~ Str[1, 2]   # -> ""';

# 
# ## Uni
# 
# Unicode strings: with utf8-flag or characters with numbers less then 128.
# 
done_testing; }; subtest 'Uni' => sub { 
is scalar do {"↭" ~~ Uni}, scalar do{1}, '"↭" ~~ Uni    # -> 1';
is scalar do {123 ~~ Uni}, scalar do{1}, '123 ~~ Uni    # -> 1';
is scalar do {do {no utf8; "↭" ~~ Uni}}, scalar do{""}, 'do {no utf8; "↭" ~~ Uni}    # -> ""';

# 
# ## Bin`[A, B?]
# 
# Binary strings: without utf8-flag.
# It maybe define maximal, or minimal and maximal length.
# 
done_testing; }; subtest 'Bin`[A, B?]' => sub { 
is scalar do {123 ~~ Bin}, scalar do{1}, '123 ~~ Bin    # -> 1';
is scalar do {"z" ~~ Bin}, scalar do{1}, '"z" ~~ Bin    # -> 1';
is scalar do {do {no utf8; "↭" ~~ Bin }}, scalar do{1}, 'do {no utf8; "↭" ~~ Bin }   # -> 1';

# 
# ## NonEmptyStr`[A, B?]
# 
# String with one or many non-space characters.
# 
done_testing; }; subtest 'NonEmptyStr`[A, B?]' => sub { 
is scalar do {" " ~~ NonEmptyStr}, scalar do{""}, '" " ~~ NonEmptyStr        # -> ""';
is scalar do {" S " ~~ NonEmptyStr}, scalar do{1}, '" S " ~~ NonEmptyStr      # -> 1';
is scalar do {" S " ~~ NonEmptyStr[2]}, scalar do{""}, '" S " ~~ NonEmptyStr[2]   # -> ""';
is scalar do {" S" ~~ NonEmptyStr[2]}, scalar do{1}, '" S" ~~ NonEmptyStr[2]    # -> 1';
is scalar do {" S" ~~ NonEmptyStr[1,2]}, scalar do{1}, '" S" ~~ NonEmptyStr[1,2]  # -> 1';
is scalar do {" S " ~~ NonEmptyStr[1,2]}, scalar do{""}, '" S " ~~ NonEmptyStr[1,2] # -> ""';
is scalar do {"S" ~~ NonEmptyStr[2,3]}, scalar do{""}, '"S" ~~ NonEmptyStr[2,3]   # -> ""';

# 
# ## Email
# 
# Strings with `@`.
# 
done_testing; }; subtest 'Email' => sub { 
is scalar do {'@' ~~ Email}, scalar do{1}, '\'@\' ~~ Email      # -> 1';
is scalar do {'a@a.a' ~~ Email}, scalar do{1}, '\'a@a.a\' ~~ Email  # -> 1';
is scalar do {'a.a' ~~ Email}, scalar do{""}, '\'a.a\' ~~ Email    # -> ""';

# 
# ## Tel
# 
# Format phones is plus sign and seven or great digits.
# 
done_testing; }; subtest 'Tel' => sub { 
is scalar do {"+1234567" ~~ Tel}, scalar do{1}, '"+1234567" ~~ Tel    # -> 1';
is scalar do {"+1234568" ~~ Tel}, scalar do{1}, '"+1234568" ~~ Tel    # -> 1';
is scalar do {"+ 1234567" ~~ Tel}, scalar do{""}, '"+ 1234567" ~~ Tel    # -> ""';
is scalar do {"+1234567 " ~~ Tel}, scalar do{""}, '"+1234567 " ~~ Tel    # -> ""';

# 
# ## Url
# 
# Web urls is string with prefix http:// or https://.
# 
done_testing; }; subtest 'Url' => sub { 
is scalar do {"http://" ~~ Url}, scalar do{1}, '"http://" ~~ Url    # -> 1';
is scalar do {"http:/" ~~ Url}, scalar do{""}, '"http:/" ~~ Url    # -> ""';

# 
# ## Path
# 
# The paths starts with a slash.
# 
done_testing; }; subtest 'Path' => sub { 
is scalar do {"/" ~~ Path}, scalar do{1}, '"/" ~~ Path     # -> 1';
is scalar do {"/a/b" ~~ Path}, scalar do{1}, '"/a/b" ~~ Path  # -> 1';
is scalar do {"a/b" ~~ Path}, scalar do{""}, '"a/b" ~~ Path   # -> ""';

# 
# ## Html
# 
# The html starts with a `<!doctype` or `<html`.
# 
done_testing; }; subtest 'Html' => sub { 
is scalar do {"<HTML" ~~ Html}, scalar do{1}, '"<HTML" ~~ Html            # -> 1';
is scalar do {" <html" ~~ Html}, scalar do{1}, '" <html" ~~ Html           # -> 1';
is scalar do {" <!doctype html>" ~~ Html}, scalar do{1}, '" <!doctype html>" ~~ Html # -> 1';
is scalar do {" <html1>" ~~ Html}, scalar do{""}, '" <html1>" ~~ Html         # -> ""';

# 
# ## StrDate
# 
# The date is format `yyyy-mm-dd`.
# 
done_testing; }; subtest 'StrDate' => sub { 
is scalar do {"2001-01-12" ~~ StrDate}, scalar do{1}, '"2001-01-12" ~~ StrDate    # -> 1';
is scalar do {"01-01-01" ~~ StrDate}, scalar do{""}, '"01-01-01" ~~ StrDate    # -> ""';

# 
# ## StrDateTime
# 
# The dateTime is format `yyyy-mm-dd HH:MM:SS`.
# 
done_testing; }; subtest 'StrDateTime' => sub { 
is scalar do {"2012-12-01 00:00:00" ~~ StrDateTime}, scalar do{1}, '"2012-12-01 00:00:00" ~~ StrDateTime     # -> 1';
is scalar do {"2012-12-01 00:00:00 " ~~ StrDateTime}, scalar do{""}, '"2012-12-01 00:00:00 " ~~ StrDateTime    # -> ""';

# 
# ## StrMatch[qr/.../]
# 
# Match value with regular expression.
# 
done_testing; }; subtest 'StrMatch[qr/.../]' => sub { 
is scalar do {' abc ' ~~ StrMatch[qr/abc/]}, scalar do{1}, '\' abc \' ~~ StrMatch[qr/abc/]    # -> 1';
is scalar do {' abbc ' ~~ StrMatch[qr/abc/]}, scalar do{""}, '\' abbc \' ~~ StrMatch[qr/abc/]   # -> ""';

# 
# ## ClassName
# 
# Classname is the package with method `new`.
# 
done_testing; }; subtest 'ClassName' => sub { 
is scalar do {'Aion::Type' ~~ ClassName}, scalar do{1}, '\'Aion::Type\' ~~ ClassName     # -> 1';
is scalar do {'Aion::Types' ~~ ClassName}, scalar do{""}, '\'Aion::Types\' ~~ ClassName    # -> ""';

# 
# ## RoleName
# 
# Rolename is the package with subroutine `requires`.
# 
done_testing; }; subtest 'RoleName' => sub { 
package ExRole {
	sub requires {}
}

is scalar do {'ExRole' ~~ RoleName}, scalar do{1}, '\'ExRole\' ~~ RoleName    	# -> 1';
is scalar do {'Aion::Type' ~~ RoleName}, scalar do{""}, '\'Aion::Type\' ~~ RoleName    # -> ""';

# 
# ## Numeric
# 
# Test scalar with `Scalar::Util::looks_like_number`. Maybe spaces on end.
# 
done_testing; }; subtest 'Numeric' => sub { 
is scalar do {6.5 ~~ Numeric}, scalar do{1}, '6.5 ~~ Numeric       # -> 1';
is scalar do {6.5e-7 ~~ Numeric}, scalar do{1}, '6.5e-7 ~~ Numeric    # -> 1';
is scalar do {"6.5 " ~~ Numeric}, scalar do{1}, '"6.5 " ~~ Numeric    # -> 1';
is scalar do {"v6.5" ~~ Numeric}, scalar do{""}, '"v6.5" ~~ Numeric    # -> ""';

# 
# ## Num
# 
# The numbers.
# 
done_testing; }; subtest 'Num' => sub { 
is scalar do {-6.5 ~~ Num}, scalar do{1}, '-6.5 ~~ Num      # -> 1';
is scalar do {6.5e-7 ~~ Num}, scalar do{1}, '6.5e-7 ~~ Num    # -> 1';
is scalar do {"6.5 " ~~ Num}, scalar do{""}, '"6.5 " ~~ Num    # -> ""';

# 
# ## PositiveNum
# 
# The positive numbers.
# 
done_testing; }; subtest 'PositiveNum' => sub { 
is scalar do {0 ~~ PositiveNum}, scalar do{1}, '0 ~~ PositiveNum     # -> 1';
is scalar do {0.1 ~~ PositiveNum}, scalar do{1}, '0.1 ~~ PositiveNum   # -> 1';
is scalar do {-0.1 ~~ PositiveNum}, scalar do{""}, '-0.1 ~~ PositiveNum  # -> ""';
is scalar do {-0 ~~ PositiveNum}, scalar do{1}, '-0 ~~ PositiveNum    # -> 1';

# 
# ## Float
# 
# The machine float number is 4 bytes.
# 
done_testing; }; subtest 'Float' => sub { 
is scalar do {-4.8 ~~ Float}, scalar do{1}, '-4.8 ~~ Float    				# -> 1';
is scalar do {-3.402823466E+38 ~~ Float}, scalar do{1}, '-3.402823466E+38 ~~ Float    	# -> 1';
is scalar do {+3.402823466E+38 ~~ Float}, scalar do{1}, '+3.402823466E+38 ~~ Float    	# -> 1';
is scalar do {-3.402823467E+38 ~~ Float}, scalar do{""}, '-3.402823467E+38 ~~ Float       # -> ""';

# 
# ## Double
# 
# The machine float number is 8 bytes.
# 
done_testing; }; subtest 'Double' => sub { 
is scalar do {-4.8 ~~ Double}, scalar do{1}, '-4.8 ~~ Double    					# -> 1';
is scalar do {-1.7976931348623158e+308 ~~ Double}, scalar do{1}, '-1.7976931348623158e+308 ~~ Double  # -> 1';
is scalar do {+1.7976931348623158e+308 ~~ Double}, scalar do{1}, '+1.7976931348623158e+308 ~~ Double  # -> 1';
is scalar do {-1.7976931348623159e+308 ~~ Double}, scalar do{""}, '-1.7976931348623159e+308 ~~ Double # -> ""';

# 
# ## Range[from, to]
# 
# Numbers between `from` and `to`.
# 
done_testing; }; subtest 'Range[from, to]' => sub { 
is scalar do {1 ~~ Range[1, 3]}, scalar do{1}, '1 ~~ Range[1, 3]    # -> 1';
is scalar do {2.5 ~~ Range[1, 3]}, scalar do{1}, '2.5 ~~ Range[1, 3]  # -> 1';
is scalar do {3 ~~ Range[1, 3]}, scalar do{1}, '3 ~~ Range[1, 3]    # -> 1';
is scalar do {3.1 ~~ Range[1, 3]}, scalar do{""}, '3.1 ~~ Range[1, 3]  # -> ""';
is scalar do {0.9 ~~ Range[1, 3]}, scalar do{""}, '0.9 ~~ Range[1, 3]  # -> ""';

# 
# ## Int`[N]
# 
# Integers.
# 
done_testing; }; subtest 'Int`[N]' => sub { 
is scalar do {123 ~~ Int}, scalar do{1}, '123 ~~ Int    # -> 1';
is scalar do {-12 ~~ Int}, scalar do{1}, '-12 ~~ Int    # -> 1';
is scalar do {5.5 ~~ Int}, scalar do{""}, '5.5 ~~ Int    # -> ""';

# 
# `N` - the number of bytes for limit.
# 

is scalar do {127 ~~ Int[1]}, scalar do{1}, '127 ~~ Int[1]    # -> 1';
is scalar do {128 ~~ Int[1]}, scalar do{""}, '128 ~~ Int[1]    # -> ""';

is scalar do {-128 ~~ Int[1]}, scalar do{1}, '-128 ~~ Int[1]    # -> 1';
is scalar do {-129 ~~ Int[1]}, scalar do{""}, '-129 ~~ Int[1]    # -> ""';

# 
# ## PositiveInt`[N]
# 
# Positive integers.
# 
done_testing; }; subtest 'PositiveInt`[N]' => sub { 
is scalar do {+0 ~~ PositiveInt}, scalar do{1}, '+0 ~~ PositiveInt    # -> 1';
is scalar do {-0 ~~ PositiveInt}, scalar do{1}, '-0 ~~ PositiveInt    # -> 1';
is scalar do {55 ~~ PositiveInt}, scalar do{1}, '55 ~~ PositiveInt    # -> 1';
is scalar do {-1 ~~ PositiveInt}, scalar do{""}, '-1 ~~ PositiveInt    # -> ""';

# 
# `N` - the number of bytes for limit.
# 

is scalar do {255 ~~ PositiveInt[1]}, scalar do{1}, '255 ~~ PositiveInt[1]    # -> 1';
is scalar do {256 ~~ PositiveInt[1]}, scalar do{""}, '256 ~~ PositiveInt[1]    # -> ""';

# 
# ## Nat`[N]
# 
# Integers 1+.
# 
done_testing; }; subtest 'Nat`[N]' => sub { 
is scalar do {0 ~~ Nat}, scalar do{""}, '0 ~~ Nat    # -> ""';
is scalar do {1 ~~ Nat}, scalar do{1}, '1 ~~ Nat    # -> 1';

# 

is scalar do {255 ~~ Nat[1]}, scalar do{1}, '255 ~~ Nat[1]    # -> 1';
is scalar do {256 ~~ Nat[1]}, scalar do{""}, '256 ~~ Nat[1]    # -> ""';

# 
# ## Ref
# 
# The value is reference.
# 
done_testing; }; subtest 'Ref' => sub { 
is scalar do {\1 ~~ Ref}, scalar do{1}, '\1 ~~ Ref    # -> 1';
is scalar do {1 ~~ Ref}, scalar do{""}, '1 ~~ Ref     # -> ""';

# 
# ## Tied`[A]
# 
# The reference on the tied variable.
# 
done_testing; }; subtest 'Tied`[A]' => sub { 
package TiedExample {
	sub TIEHASH { bless {@_}, shift }
}

tie my %a, "TiedExample";
my %b;

is scalar do {\%a ~~ Tied}, scalar do{1}, '\%a ~~ Tied    # -> 1';
is scalar do {\%b ~~ Tied}, scalar do{""}, '\%b ~~ Tied    # -> ""';

is scalar do {ref tied %a}, "TiedExample", 'ref tied %a  # => TiedExample';
is scalar do {ref tied %{\%a}}, "TiedExample", 'ref tied %{\%a}  # => TiedExample';

is scalar do {\%a ~~ Tied["TiedExample"]}, scalar do{1}, '\%a ~~ Tied["TiedExample"]    # -> 1';
is scalar do {\%a ~~ Tied["TiedExample2"]}, scalar do{""}, '\%a ~~ Tied["TiedExample2"]   # -> ""';

# 
# ## LValueRef
# 
# The function allows assignment.
# 
done_testing; }; subtest 'LValueRef' => sub { 
is scalar do {ref \substr("abc", 1, 2)}, "LVALUE", 'ref \substr("abc", 1, 2) # => LVALUE';
is scalar do {ref \vec(42, 1, 2)}, "LVALUE", 'ref \vec(42, 1, 2) # => LVALUE';

is scalar do {\substr("abc", 1, 2) ~~ LValueRef}, scalar do{1}, '\substr("abc", 1, 2) ~~ LValueRef # -> 1';
is scalar do {\vec(42, 1, 2) ~~ LValueRef}, scalar do{1}, '\vec(42, 1, 2) ~~ LValueRef # -> 1';

# 
# But it with `: lvalue` do'nt working.
# 

sub abc: lvalue { $_ }

abc() = 12;
is scalar do {$_}, "12", '$_ # => 12';
is scalar do {ref \abc()}, "SCALAR", 'ref \abc()  # => SCALAR';
is scalar do {\abc() ~~ LValueRef}, scalar do{""}, '\abc() ~~ LValueRef	# -> ""';


package As {
	sub x : lvalue {
		shift->{x};
	}
}

my $x = bless {}, "As";
$x->x = 10;

is scalar do {$x->x}, "10", '$x->x # => 10';
is_deeply scalar do {$x}, scalar do {bless {x=>10}, "As"}, '$x    # --> bless {x=>10}, "As"';

is scalar do {ref \$x->x}, "SCALAR", 'ref \$x->x 			# => SCALAR';
is scalar do {\$x->x ~~ LValueRef}, scalar do{""}, '\$x->x ~~ LValueRef # -> ""';

# 
# And on the end:
# 

is scalar do {\1 ~~ LValueRef}, scalar do{""}, '\1 ~~ LValueRef	# -> ""';

my $x = "abc";
substr($x, 1, 1) = 10;

is scalar do {$x}, "a10c", '$x # => a10c';

is scalar do {LValueRef->include(\substr($x, 1, 1))}, "1", 'LValueRef->include(\substr($x, 1, 1))	# => 1';

# 
# ## FormatRef
# 
# The format.
# 
done_testing; }; subtest 'FormatRef' => sub { 
format EXAMPLE_FMT =
@<<<<<<   @||||||   @>>>>>>
"left",   "middle", "right"
.

is scalar do {*EXAMPLE_FMT{FORMAT} ~~ FormatRef}, scalar do{1}, '*EXAMPLE_FMT{FORMAT} ~~ FormatRef   # -> 1';
is scalar do {\1 ~~ FormatRef}, scalar do{""}, '\1 ~~ FormatRef    			# -> ""';

# 
# ## CodeRef
# 
# Subroutine.
# 
done_testing; }; subtest 'CodeRef' => sub { 
is scalar do {sub {} ~~ CodeRef}, scalar do{1}, 'sub {} ~~ CodeRef    # -> 1';
is scalar do {\1 ~~ CodeRef}, scalar do{""}, '\1 ~~ CodeRef        # -> ""';

# 
# ## RegexpRef
# 
# The regular expression.
# 
done_testing; }; subtest 'RegexpRef' => sub { 
is scalar do {qr// ~~ RegexpRef}, scalar do{1}, 'qr// ~~ RegexpRef    # -> 1';
is scalar do {\1 ~~ RegexpRef}, scalar do{""}, '\1 ~~ RegexpRef    	 # -> ""';

# 
# ## ScalarRef`[A]
# 
# The scalar.
# 
done_testing; }; subtest 'ScalarRef`[A]' => sub { 
is scalar do {\12 ~~ ScalarRef}, scalar do{1}, '\12 ~~ ScalarRef     		# -> 1';
is scalar do {\\12 ~~ ScalarRef}, scalar do{""}, '\\12 ~~ ScalarRef    		# -> ""';
is scalar do {\-1.2 ~~ ScalarRef[Num]}, scalar do{1}, '\-1.2 ~~ ScalarRef[Num]     # -> 1';

# 
# ## RefRef`[A]
# 
# The ref as ref.
# 
done_testing; }; subtest 'RefRef`[A]' => sub { 
is scalar do {\\1 ~~ RefRef}, scalar do{1}, '\\1 ~~ RefRef    # -> 1';
is scalar do {\1 ~~ RefRef}, scalar do{""}, '\1 ~~ RefRef     # -> ""';
is scalar do {\\1.3 ~~ RefRef[ScalarRef[Num]]}, scalar do{1}, '\\1.3 ~~ RefRef[ScalarRef[Num]]    # -> 1';

# 
# ## GlobRef
# 
# The global.
# 
done_testing; }; subtest 'GlobRef' => sub { 
is scalar do {\*A::a ~~ GlobRef}, scalar do{1}, '\*A::a ~~ GlobRef    # -> 1';
is scalar do {*A::a ~~ GlobRef}, scalar do{""}, '*A::a ~~ GlobRef     # -> ""';

# 
# ## ArrayRef`[A]
# 
# The arrays.
# 
done_testing; }; subtest 'ArrayRef`[A]' => sub { 
is scalar do {[] ~~ ArrayRef}, scalar do{1}, '[] ~~ ArrayRef    # -> 1';
is scalar do {{} ~~ ArrayRef}, scalar do{""}, '{} ~~ ArrayRef    # -> ""';
is scalar do {[] ~~ ArrayRef[Num]}, scalar do{1}, '[] ~~ ArrayRef[Num]    # -> 1';
is scalar do {[1, 1.1] ~~ ArrayRef[Num]}, scalar do{1}, '[1, 1.1] ~~ ArrayRef[Num]    # -> 1';
is scalar do {[1, undef] ~~ ArrayRef[Num]}, scalar do{""}, '[1, undef] ~~ ArrayRef[Num]    # -> ""';

# 
# ## HashRef`[H]
# 
# The hashes.
# 
done_testing; }; subtest 'HashRef`[H]' => sub { 
is scalar do {{} ~~ HashRef}, scalar do{1}, '{} ~~ HashRef    # -> 1';
is scalar do {\1 ~~ HashRef}, scalar do{""}, '\1 ~~ HashRef    # -> ""';

is scalar do {{x=>1, y=>2}  ~~ HashRef[Int]}, scalar do{1}, '{x=>1, y=>2}  ~~ HashRef[Int]    # -> 1';
is scalar do {{x=>1, y=>""} ~~ HashRef[Int]}, scalar do{""}, '{x=>1, y=>""} ~~ HashRef[Int]    # -> ""';

# 
# ## Object`[O]
# 
# The blessed values.
# 
done_testing; }; subtest 'Object`[O]' => sub { 
is scalar do {bless(\(my $val=10), "A1") ~~ Object}, scalar do{1}, 'bless(\(my $val=10), "A1") ~~ Object    # -> 1';
is scalar do {\(my $val=10) ~~ Object}, scalar do{""}, '\(my $val=10) ~~ Object			    	# -> ""';

is scalar do {bless(\(my $val=10), "A1") ~~ Object["A1"]}, scalar do{1}, 'bless(\(my $val=10), "A1") ~~ Object["A1"]   # -> 1';
is scalar do {bless(\(my $val=10), "A1") ~~ Object["B1"]}, scalar do{""}, 'bless(\(my $val=10), "A1") ~~ Object["B1"]   # -> ""';

# 
# ## Map[K, V]
# 
# As `HashRef`, but has type for keys also.
# 
done_testing; }; subtest 'Map[K, V]' => sub { 
is scalar do {{} ~~ Map[Int, Int]}, scalar do{1}, '{} ~~ Map[Int, Int]    		 # -> 1';
is scalar do {{5 => 3} ~~ Map[Int, Int]}, scalar do{1}, '{5 => 3} ~~ Map[Int, Int]    # -> 1';
is scalar do {+{5.5 => 3} ~~ Map[Int, Int]}, scalar do{""}, '+{5.5 => 3} ~~ Map[Int, Int] # -> ""';
is scalar do {{5 => 3.3} ~~ Map[Int, Int]}, scalar do{""}, '{5 => 3.3} ~~ Map[Int, Int]  # -> ""';
is scalar do {{5 => 3, 6 => 7} ~~ Map[Int, Int]}, scalar do{1}, '{5 => 3, 6 => 7} ~~ Map[Int, Int]  # -> 1';

# 
# ## Tuple[A...]
# 
# The tuple.
# 
done_testing; }; subtest 'Tuple[A...]' => sub { 
is scalar do {["a", 12] ~~ Tuple[Str, Int]}, scalar do{1}, '["a", 12] ~~ Tuple[Str, Int]    # -> 1';
is scalar do {["a", 12, 1] ~~ Tuple[Str, Int]}, scalar do{""}, '["a", 12, 1] ~~ Tuple[Str, Int]    # -> ""';
is scalar do {["a", 12.1] ~~ Tuple[Str, Int]}, scalar do{""}, '["a", 12.1] ~~ Tuple[Str, Int]    # -> ""';

# 
# ## CycleTuple[A...]
# 
# The tuple one or more times.
# 
done_testing; }; subtest 'CycleTuple[A...]' => sub { 
is scalar do {["a", -5] ~~ CycleTuple[Str, Int]}, scalar do{1}, '["a", -5] ~~ CycleTuple[Str, Int]    # -> 1';
is scalar do {["a", -5, "x"] ~~ CycleTuple[Str, Int]}, scalar do{""}, '["a", -5, "x"] ~~ CycleTuple[Str, Int]    # -> ""';
is scalar do {["a", -5, "x", -6] ~~ CycleTuple[Str, Int]}, scalar do{1}, '["a", -5, "x", -6] ~~ CycleTuple[Str, Int]    # -> 1';
is scalar do {["a", -5, "x", -6.2] ~~ CycleTuple[Str, Int]}, scalar do{""}, '["a", -5, "x", -6.2] ~~ CycleTuple[Str, Int]    # -> ""';

# 
# ## Dict[k => A, ...]
# 
# The dictionary.
# 
done_testing; }; subtest 'Dict[k => A, ...]' => sub { 
is scalar do {{a => -1.6, b => "abc"} ~~ Dict[a => Num, b => Str]}, scalar do{1}, '{a => -1.6, b => "abc"} ~~ Dict[a => Num, b => Str]    # -> 1';

is scalar do {{a => -1.6, b => "abc", c => 3} ~~ Dict[a => Num, b => Str]}, scalar do{""}, '{a => -1.6, b => "abc", c => 3} ~~ Dict[a => Num, b => Str]    # -> ""';
is scalar do {{a => -1.6} ~~ Dict[a => Num, b => Str]}, scalar do{""}, '{a => -1.6} ~~ Dict[a => Num, b => Str]    # -> ""';

is scalar do {{a => -1.6} ~~ Dict[a => Num, b => Option[Str]]}, scalar do{1}, '{a => -1.6} ~~ Dict[a => Num, b => Option[Str]]    # -> 1';

# 
# ## HasProp[p...]
# 
# The hash has properties.
# 
done_testing; }; subtest 'HasProp[p...]' => sub { 
is scalar do {{a => 1, b => 2, c => 3} ~~ HasProp[qw/a b/]}, scalar do{1}, '{a => 1, b => 2, c => 3} ~~ HasProp[qw/a b/]    # -> 1';
is scalar do {{a => 1, b => 2} ~~ HasProp[qw/a b/]}, scalar do{1}, '{a => 1, b => 2} ~~ HasProp[qw/a b/]    # -> 1';
is scalar do {{a => 1, c => 3} ~~ HasProp[qw/a b/]}, scalar do{""}, '{a => 1, c => 3} ~~ HasProp[qw/a b/]    # -> ""';

is scalar do {bless({a => 1, b => 3}, "A") ~~ HasProp[qw/a b/]}, scalar do{1}, 'bless({a => 1, b => 3}, "A") ~~ HasProp[qw/a b/]    # -> 1';

# 
# ## Like
# 
# The object or string.
# 
done_testing; }; subtest 'Like' => sub { 
is scalar do {"" ~~ Like}, scalar do{1}, '"" ~~ Like    	# -> 1';
is scalar do {1 ~~ Like}, scalar do{1}, '1 ~~ Like    	# -> 1';
is scalar do {bless({}, "A") ~~ Like}, scalar do{1}, 'bless({}, "A") ~~ Like    # -> 1';
is scalar do {bless([], "A") ~~ Like}, scalar do{1}, 'bless([], "A") ~~ Like    # -> 1';
is scalar do {bless(\(my $str = ""), "A") ~~ Like}, scalar do{1}, 'bless(\(my $str = ""), "A") ~~ Like    # -> 1';
is scalar do {\1 ~~ Like}, scalar do{""}, '\1 ~~ Like    	# -> ""';

# 
# ## HasMethods[m...]
# 
# The object or the class has the methods.
# 
done_testing; }; subtest 'HasMethods[m...]' => sub { 
package HasMethodsExample {
	sub x1 {}
	sub x2 {}
}

is scalar do {"HasMethodsExample" ~~ HasMethods[qw/x1 x2/]}, scalar do{1}, '"HasMethodsExample" ~~ HasMethods[qw/x1 x2/]    		# -> 1';
is scalar do {bless({}, "HasMethodsExample") ~~ HasMethods[qw/x1 x2/]}, scalar do{1}, 'bless({}, "HasMethodsExample") ~~ HasMethods[qw/x1 x2/] # -> 1';
is scalar do {bless({}, "HasMethodsExample") ~~ HasMethods[qw/x1/]}, scalar do{1}, 'bless({}, "HasMethodsExample") ~~ HasMethods[qw/x1/]    # -> 1';
is scalar do {"HasMethodsExample" ~~ HasMethods[qw/x3/]}, scalar do{""}, '"HasMethodsExample" ~~ HasMethods[qw/x3/]    			# -> ""';
is scalar do {"HasMethodsExample" ~~ HasMethods[qw/x1 x2 x3/]}, scalar do{""}, '"HasMethodsExample" ~~ HasMethods[qw/x1 x2 x3/]    		# -> ""';
is scalar do {"HasMethodsExample" ~~ HasMethods[qw/x1 x3/]}, scalar do{""}, '"HasMethodsExample" ~~ HasMethods[qw/x1 x3/]    		# -> ""';

# 
# ## Overload`[op...]
# 
# The object or the class is overloaded.
# 
done_testing; }; subtest 'Overload`[op...]' => sub { 
package OverloadExample {
	use overload '""' => sub { "abc" };
}

is scalar do {"OverloadExample" ~~ Overload}, scalar do{1}, '"OverloadExample" ~~ Overload    # -> 1';
is scalar do {bless({}, "OverloadExample") ~~ Overload}, scalar do{1}, 'bless({}, "OverloadExample") ~~ Overload    # -> 1';
is scalar do {"A" ~~ Overload}, scalar do{""}, '"A" ~~ Overload    				# -> ""';
is scalar do {bless({}, "A") ~~ Overload}, scalar do{""}, 'bless({}, "A") ~~ Overload    	# -> ""';

# 
# And it has the operators if arguments are specified.
# 

is scalar do {"OverloadExample" ~~ Overload['""']}, scalar do{1}, '"OverloadExample" ~~ Overload[\'""\']   # -> 1';
is scalar do {"OverloadExample" ~~ Overload['|']}, scalar do{""}, '"OverloadExample" ~~ Overload[\'|\']    # -> ""';

# 
# ## InstanceOf[A...]
# 
# The class or the object inherits the list of classes.
# 
done_testing; }; subtest 'InstanceOf[A...]' => sub { 
package Animal {}
package Cat { our @ISA = qw/Animal/ }
package Tiger { our @ISA = qw/Cat/ }


is scalar do {"Tiger" ~~ InstanceOf['Animal', 'Cat']}, scalar do{1}, '"Tiger" ~~ InstanceOf[\'Animal\', \'Cat\']  # -> 1';
is scalar do {"Tiger" ~~ InstanceOf['Tiger']}, scalar do{1}, '"Tiger" ~~ InstanceOf[\'Tiger\']    		# -> 1';
is scalar do {"Tiger" ~~ InstanceOf['Cat', 'Dog']}, scalar do{""}, '"Tiger" ~~ InstanceOf[\'Cat\', \'Dog\']    	# -> ""';

# 
# ## ConsumerOf[A...]
# 
# The class or the object has the roles.
# 
# ## StrLike
# 
# String or object with overloaded operator `""`.
# 
done_testing; }; subtest 'StrLike' => sub { 
is scalar do {"" ~~ StrLike}, scalar do{1}, '"" ~~ StrLike    							# -> 1';

package StrLikeExample {
	use overload '""' => sub { "abc" };
}

is scalar do {bless({}, "StrLikeExample") ~~ StrLike}, scalar do{1}, 'bless({}, "StrLikeExample") ~~ StrLike    	# -> 1';

is scalar do {{} ~~ StrLike}, scalar do{""}, '{} ~~ StrLike    							# -> ""';

# 
# ## RegexpLike
# 
# The regular expression or the object with overloaded operator `qr`.
# 
done_testing; }; subtest 'RegexpLike' => sub { 
is scalar do {qr// ~~ RegexpLike}, scalar do{1}, 'qr// ~~ RegexpLike    	# -> 1';
is scalar do {"" ~~ RegexpLike}, scalar do{""}, '"" ~~ RegexpLike    	# -> ""';

package RegexpLikeExample {
	use overload 'qr' => sub { qr/abc/ };
}

is scalar do {"RegexpLikeExample" ~~ RegexpLike}, scalar do{1}, '"RegexpLikeExample" ~~ RegexpLike    # -> 1';

# 
# ## CodeLike
# 
# The subroutines.
# 
done_testing; }; subtest 'CodeLike' => sub { 
is scalar do {sub {} ~~ CodeLike}, scalar do{1}, 'sub {} ~~ CodeLike    	# -> 1';
is scalar do {\&CodeLike ~~ CodeLike}, scalar do{1}, '\&CodeLike ~~ CodeLike  # -> 1';
is scalar do {{} ~~ CodeLike}, scalar do{""}, '{} ~~ CodeLike  		# -> ""';

# 
# ## ArrayLike`[A]
# 
# The arrays or objects with overloaded operator `@{}`.
# 
done_testing; }; subtest 'ArrayLike`[A]' => sub { 
is scalar do {[] ~~ ArrayLike}, scalar do{1}, '[] ~~ ArrayLike    	# -> 1';
is scalar do {{} ~~ ArrayLike}, scalar do{""}, '{} ~~ ArrayLike    	# -> ""';


package ArrayLikeExample {
	use overload '@{}' => sub {
		shift->{array} //= []
	};
}

my $x = bless {}, 'ArrayLikeExample';
$x->[1] = 12;
is_deeply scalar do {$x->{array}}, scalar do {[undef, 12]}, '$x->{array}  # --> [undef, 12]';

is scalar do {$x ~~ ArrayLike}, scalar do{1}, '$x ~~ ArrayLike    # -> 1';

# 
# ## HashLike`[A]
# 
# The hashes or objects with overloaded operator `%{}`.
# 
done_testing; }; subtest 'HashLike`[A]' => sub { 
is scalar do {{} ~~ HashLike}, scalar do{1}, '{} ~~ HashLike    	# -> 1';
is scalar do {[] ~~ HashLike}, scalar do{""}, '[] ~~ HashLike    	# -> ""';

package HashLikeExample {
	use overload '%{}' => sub {
		shift->[0] //= {}
	};
}

my $x = bless [], 'HashLikeExample';
$x->{key} = 12;
is_deeply scalar do {$x->[0]}, scalar do {{key => 12}}, '$x->[0]  # --> {key => 12}';

is scalar do {$x ~~ HashLike}, scalar do{1}, '$x ~~ HashLike    # -> 1';

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
