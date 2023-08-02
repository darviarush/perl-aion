# NAME

Aion::Type - class for types (validators)

# SYNOPSIS

```perl
my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
12   ~~ $Int # => 1
12.1 ~~ $Int # -> ""

my $Char = Aion::Type->new(name => "Char", test => sub { /^.\z/ });
$Char->include("a")     # => 1
$Char->exclude("ab")    # => 1

my $IntOrChar = $Int | $Char;
77   ~~ $IntOrChar # => 1
"a"  ~~ $IntOrChar # => 1
"ab" ~~ $IntOrChar # -> ""

my $Digit = $Int & $Char;
7  ~~ $Digit # => 1
77 ~~ $Digit # -> ""

"a" ~~ ~$Int; # => 1
5   ~~ ~$Int; # -> ""
```

## 

# METHODS

## new (%ARGUMENTS)

### ARGUMENTS

#### name

Name of type.

#### args

List of type arguments.

#### test

Subroutine for check value.

## include

# OPERATORS

## &{}

It make the object is callable.

## ""

Stringify object.

## $a | $b

It make new type as union of `$a` and `$b`.

## $a & $b

It make new type as intersection of `$a` and `$b`.

## ~ $a

It make exclude type from `$a`.

