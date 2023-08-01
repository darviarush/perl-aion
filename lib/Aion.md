# NAME

**Aion** — A postmodern object system for Perl 5, as `Moose` and `Moo`, but with improvements.

# VERSION

1.0

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
use Calc;

Calc->new(a => 1, b => 2)->result   # => 3
```

# DESCRIPTION



# SUBROUTINES

`use Aion` include in module types from `Aion::Types` and next subroutines:

## has

Make method for get/set property.

File lib/Animal.pm:
```perl
package Animal;

use Aion;



1;
```

## extends (@superclasses)

Extends package other package. It call on each the package method `import_with`.

## with

Add to module roles. It call on each the role method `import_with`.

# METHODS

`use Aion` include in module next methods:

## new (%parameters)

The constructor.

## has ($property)

It check what property is set.
