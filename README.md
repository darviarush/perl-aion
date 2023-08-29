# NAME

**Aion** — A postmodern object system for Perl 5, as `Moose` and `Moo`, but with improvements.

# VERSION

0.01

# SYNOPSIS

```perl
package Calc {

    use Aion;

    has a => (is => 'ro+', isa => Num);
    has b => (is => 'ro+', isa => Num);
    has op => (is => 'ro', isa => Enum[qw/+ - * \/ **/], default => '+');

    sub result {
        my ($self) = @_;
        eval "${\ $self->a} ${\ $self->op} ${\ $self->b}"
    }

}

Calc->new(a => 1.1, b => 2)->result   # => 3.1
```

# DESCRIPTION

Aion — OOP framework for create classes with **features**, has **aspects**, **roles** and so on.

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
use lib "lib";
use Animal;

eval { Animal->new }; $@    # ~> Feature type is required!
eval { Animal->new(name => 'murka') }; $@    # ~> Feature name not set in new!

my $cat = Animal->new(type => 'cat');
$cat->type   # => cat

eval { $cat->name }; $@   # ~> Get feature `name` must have the type Str. The it is undef

$cat->name("murzik");
$cat->name  # => murzik
```

## with

Add to module roles. It call on each the role method `import_with`.

File lib/Role/Keys/Stringify.pm:
```perl
package Role::Keys::Stringify;

use Aion -role;

sub keysify {
    my ($self) = @_;
    join ", ", sort keys %$self;
}

1;
```

File lib/Role/Values/Stringify.pm:
```perl
package Role::Values::Stringify;

use Aion -role;

sub valsify {
    my ($self) = @_;
    join ", ", map $self->{$_}, sort keys %$self;
}

1;
```

File lib/Class/All/Stringify.pm:
```perl
package Class::All::Stringify;

use Aion;

with qw/Role::Keys::Stringify Role::Values::Stringify/;

has [qw/key1 key2/] => (is => 'rw', isa => Str);

1;
```

```perl
use lib "lib";
use Class::All::Stringify;

my $s = Class::All::Stringify->new(key1=>"a", key2=>"b");

$s->keysify     # => key1, key2
$s->valsify     # => a, b
```

## isa ($package)

Check `$package` is the class what extended this class.

```perl
package Ex::X { use Aion; }
package Ex::A { use Aion; extends qw/Ex::X/; }
package Ex::B { use Aion; }
package Ex::C { use Aion; extends qw/Ex::A Ex::B/ }

Ex::C->isa("Ex::A") # -> 1
Ex::C->isa("Ex::B") # -> 1
Ex::C->isa("Ex::X") # -> 1
Ex::C->isa("Ex::X1") # -> ""
Ex::A->isa("Ex::X") # -> 1
Ex::A->isa("Ex::A") # -> 1
Ex::X->isa("Ex::X") # -> 1
```

## does ($package)

Check `$package` is the role what extended this class.

```perl
package Role::X { use Aion -role; }
package Role::A { use Aion; with qw/Role::X/; }
package Role::B { use Aion; }
package Ex::Z { use Aion; with qw/Role::A Role::B/ }

Ex::Z->does("Role::A") # -> 1
Ex::Z->does("Role::B") # -> 1
Ex::Z->does("Role::X") # -> 1
Role::A->does("Role::X") # -> 1
Role::A->does("Role::X1") # -> ""
Ex::Z->does("Ex::Z") # -> ""
```

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

Attribute `Isa` check the signature the function where it called.

**WARNING**: use atribute `Isa` slows down the program.

**TIP**: use aspect `isa` on features is more than enough to check the correctness of the object data.

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


eval { Anim->is_cat("cat") }; $@ # ~> Arguments of method `is_cat` must have the type Tuple\[Object, Str\].
eval { my @items = $anim->is_cat("cat") }; $@ # ~> Returns of method `is_cat` must have the type Tuple\[Bool\].
```

If use name of type in `@signature`, then call subroutine with this name from current package.

# AUTHOR

Yaroslav O. Kosmina [dart@cpan.org](mailto:dart@cpan.org)

# LICENSE

⚖ **GPLv3**