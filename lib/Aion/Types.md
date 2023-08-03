# NAME

Aion::Types is library of validators. And it makes new validators

# SYNOPSIS

```perl
use Aion::Types;

BEGIN {
    subtype "SpeakOfKitty", as StrMatch[qr/\bkitty\b/i],
        message { "Speak not of kitty!" };
}

"Kitty!" ~~ SpeakOfKitty # => 1

```

# DESCRIPTION

Hierarhy of types:

```
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

`1` is true. `0`, `""` or `undef` is false

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

.

```perl
 ~~ Tel    # -> 1
 ~~ Tel    # -> ""
```

## Url

.

```perl
 ~~ Url    # -> 1
 ~~ Url    # -> ""
```

## Path

.

```perl
 ~~ Path    # -> 1
 ~~ Path    # -> ""
```

## Html

.

```perl
 ~~ Html    # -> 1
 ~~ Html    # -> ""
```

## StrDate

.

```perl
 ~~ StrDate    # -> 1
 ~~ StrDate    # -> ""
```

## StrDateTime

.

```perl
 ~~ StrDateTime    # -> 1
 ~~ StrDateTime    # -> ""
```

## StrMatch[qr/.../]

.

```perl
 ~~ StrMatch[qr/.../]    # -> 1
 ~~ StrMatch[qr/.../]    # -> ""
```

## ClassName[A]

.

```perl
 ~~ ClassName[A]    # -> 1
 ~~ ClassName[A]    # -> ""
```

## RoleName[A]

.

```perl
 ~~ RoleName[A]    # -> 1
 ~~ RoleName[A]    # -> ""
```

## Numeric

.

```perl
 ~~ Numeric    # -> 1
 ~~ Numeric    # -> ""
```

## Num

.

```perl
 ~~ Num    # -> 1
 ~~ Num    # -> ""
```

## PositiveNum

.

```perl
 ~~ PositiveNum    # -> 1
 ~~ PositiveNum    # -> ""
```

## Float

.

```perl
 ~~ Float    # -> 1
 ~~ Float    # -> ""
```

## Range[from, to]

.

```perl
 ~~ Range[from, to]    # -> 1
 ~~ Range[from, to]    # -> ""
```

## Int`[N]

.

```perl
 ~~ Int`[N]    # -> 1
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
