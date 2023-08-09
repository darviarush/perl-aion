# NAME

Aion::Types is library of validators. And it makes new validators

# SYNOPSIS

```perl
use Aion::Types;

# Create validator SpeakOfKitty extends it from validator StrMatch.
BEGIN {
    subtype SpeakOfKitty => as StrMatch[qr/\bkitty\b/i],
        message { "Speak not of kitty!" };
}

"Kitty!" ~~ SpeakOfKitty # => 1

eval { SpeakOfKitty->validate("Kitty!") };
$@ # ~> Speak not of kitty!


BEGIN {
	subtype IntOrArrayRef => as Int | ArrayRef;
}

[] ~~ StrOrArrayRef  # -> 1
5 ~~ StrOrArrayRef   # -> 1
"" ~~ StrOrArrayRef  # -> ""


coerce StrOrArrayRef, from Num, via { int($_ + .5) };

local $_ = 5.5; StrOrArrayRef->coerce # => 6
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

## Optional[A...]


## Slurpy[A...]


## Array`[A]


## ATuple[A...]


## ACycleTuple[A...]


## Hash`[A]


## HMap[K, V]


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
3 ~~ Enum[1,2,3]        # -> 1
"a" ~~ Enum["a", "b"]   # -> 1
4 ~~ Enum[1,2,3]        # -> ""
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
(-3.402823466E+38 - 1) ~~ Float # -> ""
```

## Range[from, to]

Numbers between `from` and `to`.

```perl
1 ~~ Range[1, 3]    # -> 1
2.5 ~~ Range[1, 3]  # -> 1
3 ~~ Range[1, 3]    # -> 1
3.1 ~~ Range[1, 3]  # -> ""
0.9 ~~ Range[1, 3]  # -> ""
```

## Int`[N]

Integers. The parameter `N` 

```perl
 ~~ Int    # -> 1
 ~~ Int`[N]    # -> ""
```

## PositiveInt`[N]

.

```perl
 ~~ PositiveInt`[N]    # -> 1
 ~~ PositiveInt`[N]    # -> ""
```

## Nat`[N]

.

```perl
 ~~ Nat`[N]    # -> 1
 ~~ Nat`[N]    # -> ""
```

## Ref

.

```perl
 ~~ Ref    # -> 1
 ~~ Ref    # -> ""
```

## Tied`[A]

.

```perl
 ~~ Tied`[A]    # -> 1
 ~~ Tied`[A]    # -> ""
```

## LValueRef

.

```perl
 ~~ LValueRef    # -> 1
 ~~ LValueRef    # -> ""
```

## FormatRef

.

```perl
 ~~ FormatRef    # -> 1
 ~~ FormatRef    # -> ""
```

## CodeRef

.

```perl
 ~~ CodeRef    # -> 1
 ~~ CodeRef    # -> ""
```

## RegexpRef

.

```perl
 ~~ RegexpRef    # -> 1
 ~~ RegexpRef    # -> ""
```

## ScalarRef`[A]

.

```perl
 ~~ ScalarRef`[A]    # -> 1
 ~~ ScalarRef`[A]    # -> ""
```

## RefRef`[A]

.

```perl
 ~~ RefRef`[A]    # -> 1
 ~~ RefRef`[A]    # -> ""
```

## GlobRef`[A]

.

```perl
 ~~ GlobRef`[A]    # -> 1
 ~~ GlobRef`[A]    # -> ""
```

## ArrayRef`[A]

.

```perl
 ~~ ArrayRef`[A]    # -> 1
 ~~ ArrayRef`[A]    # -> ""
```

## HashRef`[H]

.

```perl
 ~~ HashRef`[H]    # -> 1
 ~~ HashRef`[H]    # -> ""
```

## Object`[O]

.

```perl
 ~~ Object`[O]    # -> 1
 ~~ Object`[O]    # -> ""
```

## Map[K, V]

.

```perl
 ~~ Map[K, V]    # -> 1
 ~~ Map[K, V]    # -> ""
```

## Tuple[A...]

.

```perl
 ~~ Tuple[A...]    # -> 1
 ~~ Tuple[A...]    # -> ""
```

## CycleTuple[A...]

.

```perl
 ~~ CycleTuple[A...]    # -> 1
 ~~ CycleTuple[A...]    # -> ""
```

## Dict[k => A, ...]

.

```perl
 ~~ Dict[k => A, ...]    # -> 1
 ~~ Dict[k => A, ...]    # -> ""
```

## Like

.

```perl
 ~~ Like    # -> 1
 ~~ Like    # -> ""
```

## HasMethods[m...]

.

```perl
 ~~ HasMethods[m...]    # -> 1
 ~~ HasMethods[m...]    # -> ""
```

## Overload`[m...]

.

```perl
 ~~ Overload`[m...]    # -> 1
 ~~ Overload`[m...]    # -> ""
```

## InstanceOf[A...]

.

```perl
 ~~ InstanceOf[A...]    # -> 1
 ~~ InstanceOf[A...]    # -> ""
```

## ConsumerOf[A...]

.

```perl
 ~~ ConsumerOf[A...]    # -> 1
 ~~ ConsumerOf[A...]    # -> ""
```

## StrLike

.

```perl
 ~~ StrLike    # -> 1
 ~~ StrLike    # -> ""
```

## RegexpLike

.

```perl
 ~~ RegexpLike    # -> 1
 ~~ RegexpLike    # -> ""
```

## CodeLike

.

```perl
 ~~ CodeLike    # -> 1
 ~~ CodeLike    # -> ""
```

## ArrayLike`[A]

.

```perl
 ~~ ArrayLike`[A]    # -> 1
 ~~ ArrayLike`[A]    # -> ""
```

## HashLike`[A]

.

```perl
 ~~ HashLike`[A]    # -> 1
 ~~ HashLike`[A]    # -> ""
```

# AUTHOR

Yaroslav O. Kosmina [dart@cpan.org](mailto:dart@cpan.org)

# LICENSE

⚖ **GPLv3**