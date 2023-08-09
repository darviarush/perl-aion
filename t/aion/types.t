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
    subtype "SpeakOfKitty", as StrMatch[qr/\bkitty\b/i],
        message { "Speak not of kitty!" };
}

is scalar do {"Kitty!" ~~ SpeakOfKitty}, "1", '"Kitty!" ~~ SpeakOfKitty # => 1';

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
# .
# 
done_testing; }; subtest 'Tel' => sub { 
is scalar do {~~ Tel}, scalar do{1}, ' ~~ Tel    # -> 1';
is scalar do {~~ Tel}, scalar do{""}, ' ~~ Tel    # -> ""';

# 
# ## Url
# 
# .
# 
done_testing; }; subtest 'Url' => sub { 
is scalar do {~~ Url}, scalar do{1}, ' ~~ Url    # -> 1';
is scalar do {~~ Url}, scalar do{""}, ' ~~ Url    # -> ""';

# 
# ## Path
# 
# .
# 
done_testing; }; subtest 'Path' => sub { 
is scalar do {~~ Path}, scalar do{1}, ' ~~ Path    # -> 1';
is scalar do {~~ Path}, scalar do{""}, ' ~~ Path    # -> ""';

# 
# ## Html
# 
# .
# 
done_testing; }; subtest 'Html' => sub { 
is scalar do {~~ Html}, scalar do{1}, ' ~~ Html    # -> 1';
is scalar do {~~ Html}, scalar do{""}, ' ~~ Html    # -> ""';

# 
# ## StrDate
# 
# .
# 
done_testing; }; subtest 'StrDate' => sub { 
is scalar do {~~ StrDate}, scalar do{1}, ' ~~ StrDate    # -> 1';
is scalar do {~~ StrDate}, scalar do{""}, ' ~~ StrDate    # -> ""';

# 
# ## StrDateTime
# 
# .
# 
done_testing; }; subtest 'StrDateTime' => sub { 
is scalar do {~~ StrDateTime}, scalar do{1}, ' ~~ StrDateTime    # -> 1';
is scalar do {~~ StrDateTime}, scalar do{""}, ' ~~ StrDateTime    # -> ""';

# 
# ## StrMatch[qr/.../]
# 
# .
# 
done_testing; }; subtest 'StrMatch[qr/.../]' => sub { 
is scalar do {~~ StrMatch[qr/.../]}, scalar do{1}, ' ~~ StrMatch[qr/.../]    # -> 1';
is scalar do {~~ StrMatch[qr/.../]}, scalar do{""}, ' ~~ StrMatch[qr/.../]    # -> ""';

# 
# ## ClassName[A]
# 
# .
# 
done_testing; }; subtest 'ClassName[A]' => sub { 
is scalar do {~~ ClassName[A]}, scalar do{1}, ' ~~ ClassName[A]    # -> 1';
is scalar do {~~ ClassName[A]}, scalar do{""}, ' ~~ ClassName[A]    # -> ""';

# 
# ## RoleName[A]
# 
# .
# 
done_testing; }; subtest 'RoleName[A]' => sub { 
is scalar do {~~ RoleName[A]}, scalar do{1}, ' ~~ RoleName[A]    # -> 1';
is scalar do {~~ RoleName[A]}, scalar do{""}, ' ~~ RoleName[A]    # -> ""';

# 
# ## Numeric
# 
# .
# 
done_testing; }; subtest 'Numeric' => sub { 
is scalar do {~~ Numeric}, scalar do{1}, ' ~~ Numeric    # -> 1';
is scalar do {~~ Numeric}, scalar do{""}, ' ~~ Numeric    # -> ""';

# 
# ## Num
# 
# .
# 
done_testing; }; subtest 'Num' => sub { 
is scalar do {~~ Num}, scalar do{1}, ' ~~ Num    # -> 1';
is scalar do {~~ Num}, scalar do{""}, ' ~~ Num    # -> ""';

# 
# ## PositiveNum
# 
# .
# 
done_testing; }; subtest 'PositiveNum' => sub { 
is scalar do {~~ PositiveNum}, scalar do{1}, ' ~~ PositiveNum    # -> 1';
is scalar do {~~ PositiveNum}, scalar do{""}, ' ~~ PositiveNum    # -> ""';

# 
# ## Float
# 
# .
# 
done_testing; }; subtest 'Float' => sub { 
is scalar do {~~ Float}, scalar do{1}, ' ~~ Float    # -> 1';
is scalar do {~~ Float}, scalar do{""}, ' ~~ Float    # -> ""';

# 
# ## Range[from, to]
# 
# .
# 
done_testing; }; subtest 'Range[from, to]' => sub { 
is scalar do {~~ Range[from, to]}, scalar do{1}, ' ~~ Range[from, to]    # -> 1';
is scalar do {~~ Range[from, to]}, scalar do{""}, ' ~~ Range[from, to]    # -> ""';

# 
# ## Int`[N]
# 
# .
# 
done_testing; }; subtest 'Int`[N]' => sub { 
is scalar do {~~ Int`[N]}, scalar do{1}, ' ~~ Int`[N]    # -> 1';
is scalar do {~~ Int`[N]}, scalar do{""}, ' ~~ Int`[N]    # -> ""';

# 
# ## PositiveInt`[N]
# 
# .
# 
done_testing; }; subtest 'PositiveInt`[N]' => sub { 
is scalar do {~~ PositiveInt`[N]}, scalar do{1}, ' ~~ PositiveInt`[N]    # -> 1';
is scalar do {~~ PositiveInt`[N]}, scalar do{""}, ' ~~ PositiveInt`[N]    # -> ""';

# 
# ## Nat`[N]
# 
# .
# 
done_testing; }; subtest 'Nat`[N]' => sub { 
is scalar do {~~ Nat`[N]}, scalar do{1}, ' ~~ Nat`[N]    # -> 1';
is scalar do {~~ Nat`[N]}, scalar do{""}, ' ~~ Nat`[N]    # -> ""';

# 
# ## Ref
# 
# .
# 
done_testing; }; subtest 'Ref' => sub { 
is scalar do {~~ Ref}, scalar do{1}, ' ~~ Ref    # -> 1';
is scalar do {~~ Ref}, scalar do{""}, ' ~~ Ref    # -> ""';

# 
# ## Tied`[A]
# 
# .
# 
done_testing; }; subtest 'Tied`[A]' => sub { 
is scalar do {~~ Tied`[A]}, scalar do{1}, ' ~~ Tied`[A]    # -> 1';
is scalar do {~~ Tied`[A]}, scalar do{""}, ' ~~ Tied`[A]    # -> ""';

# 
# ## LValueRef
# 
# .
# 
done_testing; }; subtest 'LValueRef' => sub { 
is scalar do {~~ LValueRef}, scalar do{1}, ' ~~ LValueRef    # -> 1';
is scalar do {~~ LValueRef}, scalar do{""}, ' ~~ LValueRef    # -> ""';

# 
# ## FormatRef
# 
# .
# 
done_testing; }; subtest 'FormatRef' => sub { 
is scalar do {~~ FormatRef}, scalar do{1}, ' ~~ FormatRef    # -> 1';
is scalar do {~~ FormatRef}, scalar do{""}, ' ~~ FormatRef    # -> ""';

# 
# ## CodeRef
# 
# .
# 
done_testing; }; subtest 'CodeRef' => sub { 
is scalar do {~~ CodeRef}, scalar do{1}, ' ~~ CodeRef    # -> 1';
is scalar do {~~ CodeRef}, scalar do{""}, ' ~~ CodeRef    # -> ""';

# 
# ## RegexpRef
# 
# .
# 
done_testing; }; subtest 'RegexpRef' => sub { 
is scalar do {~~ RegexpRef}, scalar do{1}, ' ~~ RegexpRef    # -> 1';
is scalar do {~~ RegexpRef}, scalar do{""}, ' ~~ RegexpRef    # -> ""';

# 
# ## ScalarRef`[A]
# 
# .
# 
done_testing; }; subtest 'ScalarRef`[A]' => sub { 
is scalar do {~~ ScalarRef`[A]}, scalar do{1}, ' ~~ ScalarRef`[A]    # -> 1';
is scalar do {~~ ScalarRef`[A]}, scalar do{""}, ' ~~ ScalarRef`[A]    # -> ""';

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
is scalar do {~~ GlobRef`[A]}, scalar do{1}, ' ~~ GlobRef`[A]    # -> 1';
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
# .
# 
done_testing; }; subtest 'HashRef`[H]' => sub { 
is scalar do {~~ HashRef`[H]}, scalar do{1}, ' ~~ HashRef`[H]    # -> 1';
is scalar do {~~ HashRef`[H]}, scalar do{""}, ' ~~ HashRef`[H]    # -> ""';

# 
# ## Object`[O]
# 
# .
# 
done_testing; }; subtest 'Object`[O]' => sub { 
is scalar do {~~ Object`[O]}, scalar do{1}, ' ~~ Object`[O]    # -> 1';
is scalar do {~~ Object`[O]}, scalar do{""}, ' ~~ Object`[O]    # -> ""';

# 
# ## Map[K, V]
# 
# .
# 
done_testing; }; subtest 'Map[K, V]' => sub { 
is scalar do {~~ Map[K, V]}, scalar do{1}, ' ~~ Map[K, V]    # -> 1';
is scalar do {~~ Map[K, V]}, scalar do{""}, ' ~~ Map[K, V]    # -> ""';

# 
# ## Tuple[A...]
# 
# .
# 
done_testing; }; subtest 'Tuple[A...]' => sub { 
is scalar do {~~ Tuple[A...]}, scalar do{1}, ' ~~ Tuple[A...]    # -> 1';
is scalar do {~~ Tuple[A...]}, scalar do{""}, ' ~~ Tuple[A...]    # -> ""';

# 
# ## CycleTuple[A...]
# 
# .
# 
done_testing; }; subtest 'CycleTuple[A...]' => sub { 
is scalar do {~~ CycleTuple[A...]}, scalar do{1}, ' ~~ CycleTuple[A...]    # -> 1';
is scalar do {~~ CycleTuple[A...]}, scalar do{""}, ' ~~ CycleTuple[A...]    # -> ""';

# 
# ## Dict[k => A, ...]
# 
# .
# 
done_testing; }; subtest 'Dict[k => A, ...]' => sub { 
is scalar do {~~ Dict[k => A, ...]}, scalar do{1}, ' ~~ Dict[k => A, ...]    # -> 1';
is scalar do {~~ Dict[k => A, ...]}, scalar do{""}, ' ~~ Dict[k => A, ...]    # -> ""';

# 
# ## Like
# 
# .
# 
done_testing; }; subtest 'Like' => sub { 
is scalar do {~~ Like}, scalar do{1}, ' ~~ Like    # -> 1';
is scalar do {~~ Like}, scalar do{""}, ' ~~ Like    # -> ""';

# 
# ## HasMethods[m...]
# 
# .
# 
done_testing; }; subtest 'HasMethods[m...]' => sub { 
is scalar do {~~ HasMethods[m...]}, scalar do{1}, ' ~~ HasMethods[m...]    # -> 1';
is scalar do {~~ HasMethods[m...]}, scalar do{""}, ' ~~ HasMethods[m...]    # -> ""';

# 
# ## Overload`[m...]
# 
# .
# 
done_testing; }; subtest 'Overload`[m...]' => sub { 
is scalar do {~~ Overload`[m...]}, scalar do{1}, ' ~~ Overload`[m...]    # -> 1';
is scalar do {~~ Overload`[m...]}, scalar do{""}, ' ~~ Overload`[m...]    # -> ""';

# 
# ## InstanceOf[A...]
# 
# .
# 
done_testing; }; subtest 'InstanceOf[A...]' => sub { 
is scalar do {~~ InstanceOf[A...]}, scalar do{1}, ' ~~ InstanceOf[A...]    # -> 1';
is scalar do {~~ InstanceOf[A...]}, scalar do{""}, ' ~~ InstanceOf[A...]    # -> ""';

# 
# ## ConsumerOf[A...]
# 
# .
# 
done_testing; }; subtest 'ConsumerOf[A...]' => sub { 
is scalar do {~~ ConsumerOf[A...]}, scalar do{1}, ' ~~ ConsumerOf[A...]    # -> 1';
is scalar do {~~ ConsumerOf[A...]}, scalar do{""}, ' ~~ ConsumerOf[A...]    # -> ""';

# 
# ## StrLike
# 
# .
# 
done_testing; }; subtest 'StrLike' => sub { 
is scalar do {~~ StrLike}, scalar do{1}, ' ~~ StrLike    # -> 1';
is scalar do {~~ StrLike}, scalar do{""}, ' ~~ StrLike    # -> ""';

# 
# ## RegexpLike
# 
# .
# 
done_testing; }; subtest 'RegexpLike' => sub { 
is scalar do {~~ RegexpLike}, scalar do{1}, ' ~~ RegexpLike    # -> 1';
is scalar do {~~ RegexpLike}, scalar do{""}, ' ~~ RegexpLike    # -> ""';

# 
# ## CodeLike
# 
# .
# 
done_testing; }; subtest 'CodeLike' => sub { 
is scalar do {~~ CodeLike}, scalar do{1}, ' ~~ CodeLike    # -> 1';
is scalar do {~~ CodeLike}, scalar do{""}, ' ~~ CodeLike    # -> ""';

# 
# ## ArrayLike`[A]
# 
# .
# 
done_testing; }; subtest 'ArrayLike`[A]' => sub { 
is scalar do {~~ ArrayLike`[A]}, scalar do{1}, ' ~~ ArrayLike`[A]    # -> 1';
is scalar do {~~ ArrayLike`[A]}, scalar do{""}, ' ~~ ArrayLike`[A]    # -> ""';

# 
# ## HashLike`[A]
# 
# .
# 
done_testing; }; subtest 'HashLike`[A]' => sub { 
is scalar do {~~ HashLike`[A]}, scalar do{1}, ' ~~ HashLike`[A]    # -> 1';
is scalar do {~~ HashLike`[A]}, scalar do{""}, ' ~~ HashLike`[A]    # -> ""';

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
