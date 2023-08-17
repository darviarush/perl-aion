# NAME

**Aion** — A postmodern object system for Perl 5, as `Moose` and `Moo`, but with improvements.

# VERSION

0.01

# SYNOPSIS

File lib/Calc.pm:
```perl
package Calc;

use Aion;

has a => (is => 'ro+', isa => Num);
has b => (is => 'ro+', isa => Num);
has op => (is => 'ro', isa => Enum[qw/+ - * \/ **/], default => '+');

sub result {
    my ($self) = @_;
    eval "${\ $self->a} ${\ $self->op} ${\ $self->b}"
}

1;
```

```perl
use lib "lib";
use Calc;

Calc->new(a => 1.1, b => 2)->result   # => 3.1
```

# DESCRIPTION

Aion — OOP 

Properties declared via `has` are called **features**.

And `is`, `isa`, `default` and so on in `has` are called **aspects**.

In addition to standard aspects, roles can add their own aspects using subroutine `aspect`.

# SUBROUTINES IN CLASSES AND ROLES

`use Aion` include in module types from `Aion::Types` and next subroutines:

## has ($name, @aspects)

Make method for get/set feature (property) of the class.

File lib/Animal.pm:
```perl
package Animal;
use Aion;

has type => (is => 'ro+', isa => Str);
has name => (is => 'rw-', isa => Str);

1;
```

```perl
use Animal;

eval { Animal->new }; $@    # ~> 123
eval { Animal->new(name => 'murka') }; $@    # ~> 123

my $cat = Animal->new(type => 'cat');
$cat->type   # => cat

eval { $cat->name }; $@   # ~> 123

$cat->name("murzik");
$cat->name  # => murzik
```

## with

Add to module roles. It call on each the role method `import_with`.

## aspect ($aspect => sub { ... })

It add aspect to this class or role, and to the classes, who use this role, if it role.

# SUBROUTINES IN CLASSES

## extends (@superclasses)

Extends package other package. It call on each the package method `import_with` if it exists.

# SUBROUTINES IN ROLES

## requires (@subroutine_names)

It add aspect to the classes, who use this role.

# METHODS

## has ($feature)

It check what property is set.

## clear ($feature)

It check what property is set.


# METHODS IN CLASSES

`use Aion` include in module next methods:

## new (%parameters)

The constructor.

# ATTRIBUTES

Aion add universal attributes.

## Isa (@signature)

```perl
package Anim {
    use Aion;

    sub is_cat : Isa(Object => Str => Bool) {
        my ($self, $anim) = @_;
        $anim =~ /(cat)/
    }
}

my $anim = Anim->new;

$anim->is_cat('cat')    # -> 1
$anim->is_cat('dog')    # -> ""


eval { Anim->is_cat("cat") }; $@ # ~> 123
eval { my @items = $anim->is_cat("cat") }; $@ # ~> 123
```

# AUTHOR

Yaroslav O. Kosmina [dart@cpan.org](mailto:dart@cpan.org)

# LICENSE

⚖ **GPLv3**