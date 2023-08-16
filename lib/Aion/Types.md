# NAME

Aion::Types is library of validators. And it makes new validators.

# SYNOPSIS

```perl
use Aion::Types;

BEGIN {
    subtype SpeakOfKitty => as StrMatch[qr/\bkitty\b/i],
        message { "Speak is'nt included kitty!" };
}

"Kitty!" ~~ SpeakOfKitty # -> 1
"abc" ~~ SpeakOfKitty 	 # -> ""

eval { SpeakOfKitty->validate("abc") }; "$@" # ~> Speak is'nt included kitty!


BEGIN {
	subtype IntOrArrayRef => as (Int | ArrayRef);
}

[] ~~ IntOrArrayRef  # -> 1
35 ~~ IntOrArrayRef  # -> 1
"" ~~ IntOrArrayRef  # -> ""


coerce IntOrArrayRef, from Num, via { int($_ + .5) };

IntOrArrayRef->coerce(5.5) # => 6
```

# DESCRIPTION

This modile export subroutines:

* subtype, as, init_where, where, awhere, message — for create validators.
* SELF, ARGS, A, B, C, D — for use in validators has arguments.
* coerce, from, via — for create coerce, using for translate values from one class to other class.

Hierarhy of validators:

```text
Any
	Control
		Union[A, B...]
		Intersection[A, B...]
		Exclude[A, B...]
		Optional[A...]
		Slurpy[A...]
	Array`[A]
		ATuple[A...]
		ACycleTuple[A...]
	Hash`[A]
		HMap[K, V]
	Item
		Bool
		Enum[A...]
		Maybe[A]
		Undef
		Defined
			Value
				Version
				Str`[A, B?]
					Uni
					Bin`[A, B?]
					NonEmptyStr`[A, B?]
					Email
					Tel
					Url
					Path
					Html
					StrDate
					StrDateTime
					StrMatch[qr/.../]
					ClassName[A]
					RoleName[A]
					Numeric
						Num
							PositiveNum
							Float
							Range[from, to]
							Int`[N]
								PositiveInt`[N]
								Nat`[N]
			Ref
				Tied`[A]
				LValueRef
				FormatRef
				CodeRef
				RegexpRef
				ScalarRef`[A]
				RefRef`[A]
				GlobRef`[A]
				ArrayRef`[A]
				HashRef`[H]
				Object`[O]
				Map[K, V]
				Tuple[A...]
				CycleTuple[A...]
				Dict[k => A, ...]
			Like
				HasMethods[m...]
				Overload`[m...]
				InstanceOf[A...]
				ConsumerOf[A...]
			StrLike
			RegexpLike
			CodeLike
			ArrayLike`[A]
			HashLike`[A]
```

# TYPES

## Any

Top-level type in the hierarchy. Match all.

## Control

Top-level type in the hierarchy constructors new types from any types.

## Union[A, B...]

Union many types.

```perl
33  ~~ Union[Int, Ref]    # -> 1
[]  ~~ Union[Int, Ref]    # -> 1
"a" ~~ Union[Int, Ref]    # -> ""
```

## Intersection[A, B...]

Intersection many types.

```perl
15 ~~ Intersection[Int, StrMatch[/5/]]    # -> 1
```

## Exclude[A, B...]

Exclude many types.

```perl
-5  ~~ Exclude[PositiveInt]    # -> 1
"a" ~~ Exclude[PositiveInt]    # -> 1
5   ~~ Exclude[PositiveInt]    # -> ""
```

## Option[A...]

The optional keys in the `Dict`.

```perl
{a=>55} ~~ Dict[a=>Int, b => Option[Int]] # -> 1
{a=>55, b=>31} ~~ Dict[a=>Int, b => Option[Int]] # -> 1
```

## Slurp[A...]

It extends the `Dict` other dictionaries, and `Tuple` and `CycleTuple` extends other tuples and arrays.

```perl
{a => 1, b => 3.14} ~~ Dict[a => Int, Slurp[ Dict[b => Num] ] ]  # -> 1

[3.3, 3.3] ~~ Tuple[Num, Slurp[ ArrayRef[Int] ], Num ] # -> 1
[3.3, 1,2,3, 3.3] ~~ Tuple[Num, Slurp[ ArrayRef[Int] ], Num ] # -> 1


```

## Array`[A]

It use for check what the subroutine return array.

```perl
sub array123: Isa(Int => Array[Int]) {
	my ($n) = @_;
	return $n, $n+1, $n+2;
}

[ array123(1) ]		# --> [2,3,4]

eval { array123(1.1) }; # ~> 1

```

## ATuple[A...]


## ACycleTuple[A...]


## Hash`[A]


## HMap[K, V]

`HMap[K, V]` is equivalent `ACycleTuple[K, V]`.


## Item

Top-level type in the hierarchy scalar types.

## Bool

`1` is true. `0`, `""` or `undef` is false.

```perl
1 ~~ Bool     # -> 1
0 ~~ Bool     # -> 1
undef ~~ Bool # -> 1
"" ~~ Bool    # -> 1

2 ~~ Bool     # -> ""
```

## Enum[A...]

Enumerate values.

```perl
3 ~~ Enum[1,2,3]        	# -> 1
"cat" ~~ Enum["cat", "dog"] # -> 1
4 ~~ Enum[1,2,3]        	# -> ""
```

## Maybe[A]

`undef` or type in `[]`.

```perl
undef ~~ Maybe[Int]    # -> 1
4 ~~ Maybe[Int]        # -> 1
"" ~~ Maybe[Int]       # -> ""
```

## Undef

`undef` only.

```perl
undef ~~ Undef    # -> 1
0 ~~ Undef        # -> ""
```

## Defined

All exclude `undef`.

```perl
\0 ~~ Defined       # -> 1
undef ~~ Defined    # -> ""
```

## Value

Defined unreference values.

```perl
3 ~~ Value        # -> 1
\3 ~~ Value       # -> ""
undef ~~ Value    # -> ""
```

## Version

Perl versions.

```perl
1.1.0 ~~ Version    # -> 1
v1.1.0 ~~ Version   # -> 1
1.1 ~~ Version      # -> ""
"1.1.0" ~~ Version  # -> ""
```

## Str`[A, B?]

Strings, include numbers.
It maybe define maximal, or minimal and maximal length.

```perl
1.1 ~~ Str         # -> 1
"" ~~ Str          # -> 1
1.1.0 ~~ Str       # -> ""
"1234" ~~ Str[3]   # -> ""
"123" ~~ Str[3]    # -> 1
"12" ~~ Str[3]     # -> 1
"" ~~ Str[1, 2]    # -> ""
"1" ~~ Str[1, 2]   # -> 1
"12" ~~ Str[1, 2]   # -> 1
"123" ~~ Str[1, 2]   # -> ""
```

## Uni

Unicode strings: with utf8-flag or characters with numbers less then 128.

```perl
"↭" ~~ Uni    # -> 1
123 ~~ Uni    # -> 1
do {no utf8; "↭" ~~ Uni}    # -> ""
```

## Bin`[A, B?]

Binary strings: without utf8-flag.
It maybe define maximal, or minimal and maximal length.

```perl
123 ~~ Bin    # -> 1
"z" ~~ Bin    # -> 1
do {no utf8; "↭" ~~ Bin }   # -> 1
```

## NonEmptyStr`[A, B?]

String with one or many non-space characters.

```perl
" " ~~ NonEmptyStr        # -> ""
" S " ~~ NonEmptyStr      # -> 1
" S " ~~ NonEmptyStr[2]   # -> ""
" S" ~~ NonEmptyStr[2]    # -> 1
" S" ~~ NonEmptyStr[1,2]  # -> 1
" S " ~~ NonEmptyStr[1,2] # -> ""
"S" ~~ NonEmptyStr[2,3]   # -> ""
```

## Email

Strings with `@`.

```perl
'@' ~~ Email      # -> 1
'a@a.a' ~~ Email  # -> 1
'a.a' ~~ Email    # -> ""
```

## Tel

Format phones is plus sign and one or many digits.

```perl
"+1" ~~ Tel    # -> 1
"+ 1" ~~ Tel    # -> ""
"+1 " ~~ Tel    # -> ""
```

## Url

Web urls is string with prefix http:// or https://.

```perl
"http://" ~~ Url    # -> 1
"http:/" ~~ Url    # -> ""
```

## Path

The paths starts with a slash.

```perl
"/" ~~ Path     # -> 1
"/a/b" ~~ Path  # -> 1
"a/b" ~~ Path   # -> ""
```

## Html

The html starts with a `<!doctype` or `<html`.

```perl
"<HTML" ~~ Html            # -> 1
" <html" ~~ Html           # -> 1
" <!doctype html>" ~~ Html # -> 1
" <html1>" ~~ Html         # -> ""
```

## StrDate

The date is format `yyyy-mm-dd`.

```perl
"2001-01-12" ~~ StrDate    # -> 1
"01-01-01" ~~ StrDate    # -> ""
```

## StrDateTime

The dateTime is format `yyyy-mm-dd HH:MM:SS`.

```perl
"2012-12-01 00:00:00" ~~ StrDateTime     # -> 1
"2012-12-01 00:00:00 " ~~ StrDateTime    # -> ""
```

## StrMatch[qr/.../]

Match value with regular expression.

```perl
' abc ' ~~ StrMatch[qr/abc/]    # -> 1
' abbc ' ~~ StrMatch[qr/abc/]   # -> ""
```

## ClassName

Classname is the package with method `new`.

```perl
'Aion::Type' ~~ ClassName     # -> 1
'Aion::Types' ~~ ClassName    # -> ""
```

## RoleName

Rolename is the package with subroutine `requires`.

```perl
package ExRole {
	sub requires {}
}

'ExRole' ~~ RoleName    	# -> 1
'Aion::Type' ~~ RoleName    # -> ""
```

## Numeric

Test scalar with `Scalar::Util::looks_like_number`. Maybe spaces on end.

```perl
6.5 ~~ Numeric       # -> 1
6.5e-7 ~~ Numeric    # -> 1
"6.5 " ~~ Numeric    # -> 1
"v6.5" ~~ Numeric    # -> ""
```

## Num

The numbers.

```perl
-6.5 ~~ Num       # -> 1
6.5e-7 ~~ Num    # -> 1
"6.5 " ~~ Num    # -> ""
```

## PositiveNum

The positive numbers.

```perl
 ~~ PositiveNum    # -> 1
 ~~ PositiveNum    # -> ""
```

## Float

The machine float number is 4 bytes.

```perl
-4.8 ~~ Float    				# -> 1
-3.402823466E+38 ~~ Float    	# -> 1
+3.402823466E+38 ~~ Float    	# -> 1
-3.402823467E+38 ~~ Float       # -> ""
```

## Double

The machine float number is 8 bytes.

```perl
-4.8 ~~ Double    					# -> 1
-1.7976931348623158e+308 ~~ Double  # -> 1
+1.7976931348623158e+308 ~~ Double  # -> 1
-1.7976931348623159e+308 ~~ Double # -> ""
```

## Range[from, to]

Values between `from` and `to`.

```perl
1 ~~ Range[1, 3]    # -> 1
2.5 ~~ Range[1, 3]  # -> 1
3 ~~ Range[1, 3]    # -> 1
3.1 ~~ Range[1, 3]  # -> ""
0.9 ~~ Range[1, 3]  # -> ""
"b" ~~ Range["a", "c"]  # -> 1
"bc" ~~ Range["a", "c"]  # -> 1
"d" ~~ Range["a", "c"]  # -> ""
```

## Int`[N]

Integers.

```perl
123 ~~ Int    # -> 1
-12 ~~ Int    # -> 1
5.5 ~~ Int    # -> ""
```

`N` - the number of bytes for limit.

```perl
127 ~~ Int[1]    # -> 1
128 ~~ Int[1]    # -> ""

-127 ~~ Int[1]    # -> 1
-128 ~~ Int[1]    # -> ""
```

## PositiveInt`[N]

Positive integers.

```perl
+0 ~~ PositiveInt    # -> 1
-0 ~~ PositiveInt    # -> 1
55 ~~ PositiveInt    # -> 1
-1 ~~ PositiveInt    # -> ""
```

`N` - the number of bytes for limit.

```perl
255 ~~ PositiveInt[1]    # -> 1
256 ~~ PositiveInt[1]    # -> ""
```

## Nat`[N]

Integers 1+.

```perl
1 ~~ Nat    # -> 1
0 ~~ Nat    # -> ""
```

```perl
255 ~~ Nat[1]    # -> 1
256 ~~ Nat[1]    # -> ""
```

## Ref

The value is reference.

```perl
\1 ~~ Ref    # -> 1
1 ~~ Ref     # -> ""
```

## Tied`[A]

The reference on the tied variable.

```perl
package A {

}

tie my %a, "A";
my %b;

\%a ~~ Tied    # -> 1
\%b ~~ Tied    # -> ""
```

## LValueRef

The function allows assignment.

```perl
package As {
	sub x : lvalue {
		shift->{x};
	}
}

my $x = bless {}, "As";
$x->x = 10;

$x->x # => 10
$x->x ~~ LValueRef    # -> 1

sub abc: lvalue { $_ }

abc() = 12;
$_ # => 12
\(&abc) ~~ LValueRef	# -> 1

\1 ~~ LValueRef	# -> ""

my $x = "abc";
substr($x, 1, 1) = 10;

$x # => a10c

LValueRef->include(\substr($x, 1, 1))	# => 1
```

## FormatRef

The format.

```perl
format EXAMPLE_FMT =
@<<<<<<   @||||||   @>>>>>>
"left",   "middle", "right"
.

*EXAMPLE_FMT{FORMAT} ~~ FormatRef   # -> 1
\1 ~~ FormatRef    			# -> ""
```

## CodeRef

Subroutine.

```perl
sub {} ~~ CodeRef    # -> 1
\1 ~~ CodeRef        # -> ""
```

## RegexpRef

The regular expression.

```perl
qr// ~~ RegexpRef    # -> 1
\1 ~~ RegexpRef    	 # -> ""
```

## ScalarRef`[A]

The scalar.

```perl
\12 ~~ ScalarRef     		# -> 1
\\12 ~~ ScalarRef    		# -> ""
\-1.2 ~~ ScalarRef[Num]     # -> 1
```

## RefRef`[A]

The ref as ref.

```perl
\\1 ~~ RefRef    # -> 1
\1 ~~ RefRef     # -> ""
\\1.3 ~~ RefRef[ScalarRef[Num]]    # -> 1
```

## GlobRef

The global.

```perl
\*A::a ~~ GlobRef    # -> 1
*A::a ~~ GlobRef     # -> ""
```

## ArrayRef`[A]

The arrays.

```perl
[] ~~ ArrayRef    # -> 1
{} ~~ ArrayRef    # -> ""
[] ~~ ArrayRef[Num]    # -> 1
[1, 1.1] ~~ ArrayRef[Num]    # -> 1
[1, undef] ~~ ArrayRef[Num]    # -> ""
```

## HashRef`[H]

The hashes.

```perl
{} ~~ HashRef    # -> 1
\1 ~~ HashRef    # -> ""

{x=>1, y=>2}  ~~ HashRef[Int]    # -> 1
{x=>1, y=>""} ~~ HashRef[Int]    # -> ""
```

## Object`[O]

The blessed values.

```perl
bless(\1, "A") ~~ Object    # -> 1
\1 ~~ Object			    # -> ""

bless(\1, "A") ~~ Object["A"]   # -> 1
bless(\1, "A") ~~ Object["B"]   # -> ""
```

## Map[K, V]

As `HashRef`, but has type for keys also.

```perl
{} ~~ Map[Int, Int]    # -> 1
{5 => 3} ~~ Map[Int, Int]    # -> 1
{5.5 => 3} ~~ Map[Int, Int]    # -> ""
{5 => 3.3} ~~ Map[Int, Int]    # -> ""
```

## Tuple[A...]

The tuple.

```perl
["a", 12] ~~ Tuple[Str, Int]    # -> 1
["a", 12, 1] ~~ Tuple[Str, Int]    # -> ""
["a", 12.1] ~~ Tuple[Str, Int]    # -> ""
```

## CycleTuple[A...]

The tuple one or more times.

```perl
["a", -5] ~~ CycleTuple[Str, Int]    # -> 1
["a", -5, "x"] ~~ CycleTuple[Str, Int]    # -> ""
["a", -5, "x", -6] ~~ CycleTuple[Str, Int]    # -> 1
["a", -5, "x", -6.2] ~~ CycleTuple[Str, Int]    # -> ""
```

## Dict[k => A, ...]

The dictionary.

```perl
{a => -1.6, b => "abc"} ~~ Dict[a => Num, b => Str]    # -> 1
{a => -1.6, b => "abc", c => 3} ~~ Dict[a => Num, b => Str]    # -> 1
{a => -1.6} ~~ Dict[a => Num, b => Str]    # -> 1
```

## HasProp[p...]

The hash has properties.

```perl
{a => 1, b => 2, c => 3} ~~ HasProp[qw/a b/]    # -> 1
{a => 1, b => 2} ~~ HasProp[qw/a b/]    # -> 1
{a => 1, c => 3} ~~ HasProp[qw/a b/]    # -> ""
```

## Like

The object or string.

```perl
"" ~~ Like    	# -> 1
1 ~~ Like    	# -> 1
bless({}, "A") ~~ Like    # -> 1
bless([], "A") ~~ Like    # -> 1
bless(\"", "A") ~~ Like    # -> 1
\1 ~~ Like    	# -> ""
```

## HasMethods[m...]

The object or the class has the methods.

```perl
package HasMethodsExample {
	sub x1 {}
	sub x2 {}
}

"HasMethodsExample" ~~ HasMethods[qw/x1 x2/]    			# -> 1
bless({}, "HasMethodsExample") ~~ HasMethods[qw/x1 x2/] # -> 1
bless({}, "HasMethodsExample") ~~ HasMethods[qw/x1/]    # -> 1
"HasMethodsExample" ~~ HasMethods[qw/x3/]    				# -> ""
"HasMethodsExample" ~~ HasMethods[qw/x1 x2 x3/]    		# -> ""
"HasMethodsExample" ~~ HasMethods[qw/x1 x3/]    			# -> ""
```

## Overload`[op...]

The object or the class is overloaded.

```perl
package OverloadExample {
	use overload '""' => sub { "abc" };
}

"OverloadExample" ~~ Overload    # -> 1
bless({}, "OverloadExample") ~~ Overload    # -> 1
"A" ~~ Overload    				# -> ""
bless({}, "A") ~~ Overload    	# -> ""
```

And it has the operators if arguments are specified.

```perl
"OverloadExample" ~~ Overload['""']   # -> 1
"OverloadExample" ~~ Overload['|']    # -> ""
```

## InstanceOf[A...]

The class or the object inherits the list of classes.

```perl
package Animal {}
package Cat { our @ISA = qw/Animal/ }
package Tiger { our @ISA = qw/Cat/ }


"Tiger" ~~ InstanceOf['Animal', 'Cat']    # -> 1
"Tiger" ~~ InstanceOf['Tiger']    		# -> ""
"Tiger" ~~ InstanceOf['Cat', 'Dog']    	# -> ""
```

## ConsumerOf[A...]

The class or the object has the roles.

## StrLike

String or object with overloaded operator `""`.

```perl
"" ~~ StrLike    							# -> 1

package StrLikeExample {
	use overload '""' => sub { "abc" };
}

bless({}, "StrLikeExample") ~~ StrLike    	# -> 1

{} ~~ StrLike    							# -> ""
```

## RegexpLike

The regular expression or the object with overloaded operator `qr`.

```perl
qr// ~~ RegexpLike    	# -> 1
"" ~~ RegexpLike    	# -> ""

package RegexpLikeExample {
	use overload 'qr' => sub { qr/abc/ };
}

"RegexpLikeExample" ~~ RegexpLike    # -> 1
```

## CodeLike

The subroutines.

```perl
sub {} ~~ CodeLike    	# -> 1
\&CodeLike ~~ CodeLike  # -> 1
{} ~~ CodeLike  		# -> ""
```

## ArrayLike`[A]

The arrays or objects with overloaded operator `@{}`.

```perl
[] ~~ ArrayLike    	# -> 1
{} ~~ ArrayLike    	# -> ""

package ArrayLikeExample {
	use overload '@{}' => sub: lvalue { shift->{shift()} };
}

my $x = bless {}, 'ArrayLikeExample';
$x->[1] = 12;
$x  # --> bless {1 => 12}, 'ArrayLikeExample'

$x ~~ ArrayLike    # -> 1
```

## HashLike`[A]

The hashes or objects with overloaded operator `%{}`.

```perl
{} ~~ HashLike    	# -> 1
[] ~~ HashLike    	# -> ""

package HashLikeExample {
	use overload '%{}' => sub: lvalue { shift->[shift()] };
}

my $x = bless [], 'HashLikeExample';
$x->{1} = 12;
$x  # --> bless [undef, 12], 'HashLikeExample'

$x ~~ HashLike    # -> 1

```

# AUTHOR

Yaroslav O. Kosmina [dart@cpan.org](mailto:dart@cpan.org)

# LICENSE

⚖ **GPLv3**