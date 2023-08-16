use common::sense; use open qw/:std :utf8/; use Test::More 0.98; use Carp::Always::Color; sub _mkpath_ { my ($p) = @_; length($`) && !-e $`? mkdir($`, 0755) || die "mkdir $`: $!": () while $p =~ m!/!g; $p } BEGIN { my $t = `pwd`; chop $t; $t .= '/' . __FILE__; my $s = '/tmp/.liveman/perl-aion/aion/types/'; `rm -fr $s` if -e $s; chdir _mkpath_($s) or die "chdir $s: $!"; open my $__f__, "<:utf8", $t or die "Read $t: $!"; $s = join "", <$__f__>; close $__f__; while($s =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { my ($file, $code) = ($1, $2); $code =~ s/^#>> //mg; open my $__f__, ">:utf8", _mkpath_($file) or die "Write $file: $!"; print $__f__ $code; close $__f__; } } # # NAME
# 
# Aion::Types is library of validators. And it makes new validators
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Types;

# Create validator SpeakOfKitty extends it from validator StrMatch.
BEGIN {
    subtype SpeakOfKitty => as StrMatch[qr/\bkitty\b/i],
        message { "Speak not of kitty!" };
}

is scalar do {"Kitty!" ~~ SpeakOfKitty}, "1", '"Kitty!" ~~ SpeakOfKitty # => 1';

eval { SpeakOfKitty->validate("Kitty!") };
like scalar do {$@}, qr!Speak not of kitty\!!, '$@ # ~> Speak not of kitty!';


BEGIN {
	subtype IntOrArrayRef => as Int | ArrayRef;
}

is scalar do {[] ~~ IntOrArrayRef}, scalar do{1}, '[] ~~ IntOrArrayRef  # -> 1';
is scalar do {5 ~~ IntOrArrayRef}, scalar do{1}, '5 ~~ IntOrArrayRef   # -> 1';
is scalar do {"" ~~ IntOrArrayRef}, scalar do{""}, '"" ~~ IntOrArrayRef  # -> ""';


coerce IntOrArrayRef, from Num, via { int($_ + .5) };

is scalar do {local $_ = 5.5; IntOrArrayRef->coerce}, "6", 'local $_ = 5.5; IntOrArrayRef->coerce # => 6';

# 
# # DESCRIPTION
# 
# This modile export subroutines:
# 
# * subtype, as, init_where, where, awhere, message — for create validators.
# * SELF, ARGS, A, B, C, D — for use in validators has arguments.
# * coerce, from, via — for create coerce, using for translate values from one class to other class.
# 
# Hierarhy of validators:
# 

# Any
# 	Control
# 		Union[A, B...]
# 		Intersection[A, B...]
# 		Exclude[A, B...]
# 		Optional[A...]
# 		Slurpy[A...]
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
# Union many types.
# 
done_testing; }; subtest 'Union[A, B...]' => sub { 
is scalar do {33  ~~ Union[Int, Ref]}, scalar do{1}, '33  ~~ Union[Int, Ref]    # -> 1';
is scalar do {[]  ~~ Union[Int, Ref]}, scalar do{1}, '[]  ~~ Union[Int, Ref]    # -> 1';
is scalar do {"a" ~~ Union[Int, Ref]}, scalar do{""}, '"a" ~~ Union[Int, Ref]    # -> ""';

# 
# ## Intersection[A, B...]
# 
# Intersection many types.
# 
done_testing; }; subtest 'Intersection[A, B...]' => sub { 
is scalar do {15 ~~ Intersection[Int, StrMatch[/5/]]}, scalar do{1}, '15 ~~ Intersection[Int, StrMatch[/5/]]    # -> 1';

# 
# ## Exclude[A, B...]
# 
# Exclude many types.
# 
done_testing; }; subtest 'Exclude[A, B...]' => sub { 
is scalar do {-5  ~~ Exclude[PositiveInt]}, scalar do{1}, '-5  ~~ Exclude[PositiveInt]    # -> 1';
is scalar do {"a" ~~ Exclude[PositiveInt]}, scalar do{1}, '"a" ~~ Exclude[PositiveInt]    # -> 1';
is scalar do {5   ~~ Exclude[PositiveInt]}, scalar do{""}, '5   ~~ Exclude[PositiveInt]    # -> ""';

# 
# ## Optional[A...]
# 
# 
# ## Slurpy[A...]
# 
# 
# ## Array`[A]
# 
# 
# ## ATuple[A...]
# 
# 
# ## ACycleTuple[A...]
# 
# 
# ## Hash`[A]
# 
# 
# ## HMap[K, V]
# 
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
is scalar do {3 ~~ Enum[1,2,3]}, scalar do{1}, '3 ~~ Enum[1,2,3]        # -> 1';
is scalar do {"a" ~~ Enum["a", "b"]}, scalar do{1}, '"a" ~~ Enum["a", "b"]   # -> 1';
is scalar do {4 ~~ Enum[1,2,3]}, scalar do{""}, '4 ~~ Enum[1,2,3]        # -> ""';

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
# Format phones is plus sign and one or many digits.
# 
done_testing; }; subtest 'Tel' => sub { 
is scalar do {"+1" ~~ Tel}, scalar do{1}, '"+1" ~~ Tel    # -> 1';
is scalar do {"+ 1" ~~ Tel}, scalar do{""}, '"+ 1" ~~ Tel    # -> ""';
is scalar do {"+1 " ~~ Tel}, scalar do{""}, '"+1 " ~~ Tel    # -> ""';

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
is scalar do {-6.5 ~~ Num}, scalar do{1}, '-6.5 ~~ Num       # -> 1';
is scalar do {6.5e-7 ~~ Num}, scalar do{1}, '6.5e-7 ~~ Num    # -> 1';
is scalar do {"6.5 " ~~ Num}, scalar do{""}, '"6.5 " ~~ Num    # -> ""';

# 
# ## PositiveNum
# 
# The positive numbers.
# 
done_testing; }; subtest 'PositiveNum' => sub { 
is scalar do {~~ PositiveNum}, scalar do{1}, ' ~~ PositiveNum    # -> 1';
is scalar do {~~ PositiveNum}, scalar do{""}, ' ~~ PositiveNum    # -> ""';

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
# Values between `from` and `to`.
# 
done_testing; }; subtest 'Range[from, to]' => sub { 
is scalar do {1 ~~ Range[1, 3]}, scalar do{1}, '1 ~~ Range[1, 3]    # -> 1';
is scalar do {2.5 ~~ Range[1, 3]}, scalar do{1}, '2.5 ~~ Range[1, 3]  # -> 1';
is scalar do {3 ~~ Range[1, 3]}, scalar do{1}, '3 ~~ Range[1, 3]    # -> 1';
is scalar do {3.1 ~~ Range[1, 3]}, scalar do{""}, '3.1 ~~ Range[1, 3]  # -> ""';
is scalar do {0.9 ~~ Range[1, 3]}, scalar do{""}, '0.9 ~~ Range[1, 3]  # -> ""';
is scalar do {"b" ~~ Range["a", "c"]}, scalar do{1}, '"b" ~~ Range["a", "c"]  # -> 1';
is scalar do {"bc" ~~ Range["a", "c"]}, scalar do{1}, '"bc" ~~ Range["a", "c"]  # -> 1';
is scalar do {"d" ~~ Range["a", "c"]}, scalar do{""}, '"d" ~~ Range["a", "c"]  # -> ""';

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

is scalar do {-127 ~~ Int[1]}, scalar do{1}, '-127 ~~ Int[1]    # -> 1';
is scalar do {-128 ~~ Int[1]}, scalar do{""}, '-128 ~~ Int[1]    # -> ""';

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
is scalar do {1 ~~ Nat}, scalar do{1}, '1 ~~ Nat    # -> 1';
is scalar do {0 ~~ Nat}, scalar do{""}, '0 ~~ Nat    # -> ""';

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
package A {

}

tie my %a, "A";
my %b;

is scalar do {\%a ~~ Tied}, scalar do{1}, '\%a ~~ Tied    # -> 1';
is scalar do {\%b ~~ Tied}, scalar do{""}, '\%b ~~ Tied    # -> ""';

# 
# ## LValueRef
# 
# The function allows assignment.
# 
done_testing; }; subtest 'LValueRef' => sub { 
package As {
	sub x : lvalue {
		shift->{x};
	}
}

my $x = bless {}, "As";
$x->x = 10;

is scalar do {$x->x}, "10", '$x->x # => 10';
is scalar do {$x->x ~~ LValueRef}, scalar do{1}, '$x->x ~~ LValueRef    # -> 1';

sub abc: lvalue { $_ }

abc() = 12;
is scalar do {$_}, "12", '$_ # => 12';
is scalar do {\(&abc) ~~ LValueRef}, scalar do{1}, '\(&abc) ~~ LValueRef	# -> 1';

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

is scalar do {\EXAMPLE_FMT ~~ FormatRef}, scalar do{1}, '\EXAMPLE_FMT ~~ FormatRef   # -> 1';
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
is scalar do {~~ ScalarRef}, scalar do{1}, ' ~~ ScalarRef    # -> 1';
is scalar do {~~ ScalarRef}, scalar do{""}, ' ~~ ScalarRef    # -> ""';

# 
# ## RefRef`[A]
# 
# .
# 
done_testing; }; subtest 'RefRef`[A]' => sub { 
is scalar do {~~ RefRef`[A]}, scalar do{1}, ' ~~ RefRef`[A]    # -> 1';
is scalar do {~~ RefRef`[A]}, scalar do{""}, ' ~~ RefRef`[A]    # -> ""';

# 
# ## GlobRef`[A]
# 
# .
# 
done_testing; }; subtest 'GlobRef`[A]' => sub { 
is scalar do {\*A::a ~~ GlobRef`[A]}, scalar do{1}, '\*A::a ~~ GlobRef`[A]    # -> 1';
is scalar do {~~ GlobRef`[A]}, scalar do{""}, ' ~~ GlobRef`[A]    # -> ""';

# 
# ## ArrayRef`[A]
# 
# .
# 
done_testing; }; subtest 'ArrayRef`[A]' => sub { 
is scalar do {~~ ArrayRef`[A]}, scalar do{1}, ' ~~ ArrayRef`[A]    # -> 1';
is scalar do {~~ ArrayRef`[A]}, scalar do{""}, ' ~~ ArrayRef`[A]    # -> ""';

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
is scalar do {bless(\1, "A") ~~ Object}, scalar do{1}, 'bless(\1, "A") ~~ Object    # -> 1';
is scalar do {\1 ~~ Object}, scalar do{""}, '\1 ~~ Object			    # -> ""';

is scalar do {bless(\1, "A") ~~ Object["A"]}, scalar do{1}, 'bless(\1, "A") ~~ Object["A"]   # -> 1';
is scalar do {bless(\1, "A") ~~ Object["B"]}, scalar do{""}, 'bless(\1, "A") ~~ Object["B"]   # -> ""';

# 
# ## Map[K, V]
# 
# As `HashRef`, but has type for keys also.
# 
done_testing; }; subtest 'Map[K, V]' => sub { 
is scalar do {{} ~~ Map[Int, Int]}, scalar do{1}, '{} ~~ Map[Int, Int]    # -> 1';
is scalar do {{5 => 3} ~~ Map[Int, Int]}, scalar do{1}, '{5 => 3} ~~ Map[Int, Int]    # -> 1';
is scalar do {{5.5 => 3} ~~ Map[Int, Int]}, scalar do{""}, '{5.5 => 3} ~~ Map[Int, Int]    # -> ""';
is scalar do {{5 => 3.3} ~~ Map[Int, Int]}, scalar do{""}, '{5 => 3.3} ~~ Map[Int, Int]    # -> ""';

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
is scalar do {~~ Dict[k => A, ...]}, scalar do{1}, ' ~~ Dict[k => A, ...]    # -> 1';
is scalar do {~~ Dict[k => A, ...]}, scalar do{""}, ' ~~ Dict[k => A, ...]    # -> ""';

# 
# ## HasProp[p...]
# 
# The hash has properties.
# 
done_testing; }; subtest 'HasProp[p...]' => sub { 
is scalar do {{a => 1, b => 2, c => 3} ~~ HasProp[qw/a b/]}, scalar do{1}, '{a => 1, b => 2, c => 3} ~~ HasProp[qw/a b/]    # -> 1';
is scalar do {{a => 1, b => 2} ~~ HasProp[qw/a b/]}, scalar do{1}, '{a => 1, b => 2} ~~ HasProp[qw/a b/]    # -> 1';
is scalar do {{a => 1, c => 3} ~~ HasProp[qw/a b/]}, scalar do{""}, '{a => 1, c => 3} ~~ HasProp[qw/a b/]    # -> ""';

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
is scalar do {bless(\"", "A") ~~ Like}, scalar do{1}, 'bless(\"", "A") ~~ Like    # -> 1';
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

is scalar do {HasMethodsExample ~~ HasMethods[qw/x1 x2/]}, scalar do{1}, 'HasMethodsExample ~~ HasMethods[qw/x1 x2/]    			# -> 1';
is scalar do {bless({}, "HasMethodsExample") ~~ HasMethods[qw/x1 x2/]}, scalar do{1}, 'bless({}, "HasMethodsExample") ~~ HasMethods[qw/x1 x2/] # -> 1';
is scalar do {bless({}, "HasMethodsExample") ~~ HasMethods[qw/x1/]}, scalar do{1}, 'bless({}, "HasMethodsExample") ~~ HasMethods[qw/x1/]    # -> 1';
is scalar do {HasMethodsExample ~~ HasMethods[qw/x3/]}, scalar do{""}, 'HasMethodsExample ~~ HasMethods[qw/x3/]    				# -> ""';
is scalar do {HasMethodsExample ~~ HasMethods[qw/x1 x2 x3/]}, scalar do{""}, 'HasMethodsExample ~~ HasMethods[qw/x1 x2 x3/]    		# -> ""';
is scalar do {HasMethodsExample ~~ HasMethods[qw/x1 x3/]}, scalar do{""}, 'HasMethodsExample ~~ HasMethods[qw/x1 x3/]    			# -> ""';

# 
# ## Overload`[op...]
# 
# The object or the class is overloaded.
# 
done_testing; }; subtest 'Overload`[op...]' => sub { 
package OverloadExample {
	overloaded
		fallback => 1,
		'""' => sub { "abc" }
	;
}

is scalar do {OverloadExample ~~ Overload}, scalar do{1}, 'OverloadExample ~~ Overload    # -> 1';
is scalar do {bless({}, "OverloadExample") ~~ Overload}, scalar do{1}, 'bless({}, "OverloadExample") ~~ Overload    # -> 1';
is scalar do {"A" ~~ Overload}, scalar do{""}, '"A" ~~ Overload    				# -> ""';
is scalar do {bless({}, "A") ~~ Overload}, scalar do{""}, 'bless({}, "A") ~~ Overload    	# -> ""';

# 
# And it has the operators if arguments are specified.
# 

is scalar do {OverloadExample ~~ Overload['""']}, scalar do{1}, 'OverloadExample ~~ Overload[\'""\']   # -> 1';
is scalar do {OverloadExample ~~ Overload['|']}, scalar do{""}, 'OverloadExample ~~ Overload[\'|\']    # -> ""';

# 
# ## InstanceOf[A...]
# 
# The class or the object inherits the list of classes.
# 
done_testing; }; subtest 'InstanceOf[A...]' => sub { 
package Animal {}
package Cat { our @ISA = qw/Animal/ }
package Tiger { our @ISA = qw/Cat/ }


is scalar do {Tiger ~~ InstanceOf['Animal', 'Cat']}, scalar do{1}, 'Tiger ~~ InstanceOf[\'Animal\', \'Cat\']    # -> 1';
is scalar do {Tiger ~~ InstanceOf['Tiger']}, scalar do{""}, 'Tiger ~~ InstanceOf[\'Tiger\']    		# -> ""';
is scalar do {Tiger ~~ InstanceOf['Cat', 'Dog']}, scalar do{""}, 'Tiger ~~ InstanceOf[\'Cat\', \'Dog\']    	# -> ""';

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
is scalar do {bless({}, "OverloadExample") ~~ StrLike}, scalar do{1}, 'bless({}, "OverloadExample") ~~ StrLike    	# -> 1';
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
	overloaded 'qr' => sub { qr/abc/ };
}

is scalar do {RegexpLikeExample ~~ RegexpLike}, scalar do{1}, 'RegexpLikeExample ~~ RegexpLike    # -> 1';

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
	overloaded '@{}' => sub: lvalue { shift->{shift()} };
}

my $x = bless {}, 'ArrayLikeExample';
$x->[1] = 12;
is_deeply scalar do {$x}, scalar do {bless {1 => 12}, 'ArrayLikeExample'}, '$x  # --> bless {1 => 12}, \'ArrayLikeExample\'';

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
	overloaded '%{}' => sub: lvalue { shift->[shift()] };
}

my $x = bless [], 'HashLikeExample';
$x->{1} = 12;
is_deeply scalar do {$x}, scalar do {bless [undef, 12], 'HashLikeExample'}, '$x  # --> bless [undef, 12], \'HashLikeExample\'';

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
