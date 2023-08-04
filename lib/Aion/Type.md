# NAME

Aion::Type - class of validators.

# SYNOPSIS

```perl
use Aion::Type;

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

Constructor.

### ARGUMENTS

#### name

Name of type.

#### args

List of type arguments.

#### test

Subroutine for check value.

## stringify

Stringify of object (name with arguments):

```perl
my $Int = Aion::Type->new(
    name => "Int",
    args => [3, 5],
);

$Int->stringify  #=> Int[3, 5]
```

## test

Testing the `$_` belongs to the class.

```perl
my $PositiveInt = Aion::Type->new(
    name => "PositiveInt",
    test => sub { /^\d+$/ },
);

local $_ = 5;
$PositiveInt->test  # -> 1
local $_ = -6;
$PositiveInt->test  # -> ""
```

## init

Initial the validator.

```perl
use DDP;
my $Range = Aion::Type->new(
    name => "Range",
    args => [3, 5],
    init => sub {
        @{$Aion::Type::SELF}{qw/min max/} = @{$Aion::Type::SELF->{args}};
    },
    test => sub { p $Aion::Type::SELF->{min}; $Aion::Type::SELF->{min} <= $_ <= $Aion::Type::SELF->{max} },
);

$Range->init;

3 ~~ $Range  # -> 1
4 ~~ $Range  # -> 1
5 ~~ $Range  # -> 1

2 ~~ $Range  # -> ""
6 ~~ $Range  # -> ""
```


## include ($element)

checks whether the argument belongs to the class.

```perl
my $PositiveInt = Aion::Type->new(
    name => "PositiveInt",
    test => sub { /^\d+$/ },
);

$PositiveInt->include(5) # -> 1
$PositiveInt->include(-6) # -> ""
```

## exclude ($element)

Checks that the argument does not belong to the class.

```perl
my $PositiveInt = Aion::Type->new(
    name => "PositiveInt",
    test => sub { /^\d+$/ },
);

$PositiveInt->exclude(5)  # -> ""
$PositiveInt->exclude(-6) # -> 1
```

## detail ($val, $name)

Return message belongs to error.

```perl
my $Int = Aion::Type->new(name => "Int");

$Int->detail(-5, "car") # => Feature car must have the type Int. The same car is -5

my $Num = Aion::Type->new(name => "Num", detail => sub {
    my ($val, $name) = @_;
    "Error: $val is'nt $name!"
});

$num->detail("x", "car")  # => Error: x is'nt car!
```


# OPERATORS

## &{}

It make the object is callable.

```perl
my $PositiveInt = Aion::Type->new(
    name => "PositiveInt",
    test => sub { /^\d+$/ },
);


```

## ""

Stringify object.

## $a | $b

It make new type as union of `$a` and `$b`.

## $a & $b

It make new type as intersection of `$a` and `$b`.

## ~ $a

It make exclude type from `$a`.

