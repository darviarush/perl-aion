!ru:en
# NAME

Aion::Type::Espresso - минимизация (свёртка) ДНФ по алгоритму Эспрессо

# SYNOPSIS

```perl
use Aion::Types qw/Range None/;

my $gap = Range[-10, 0] & Range[0, 8];
$gap->simplify   # => Range[-10, 8]
```

# DESCRIPTION

Роль, которую включает в себя `Aion::Type` (`@ISA = qw/Aion::Type::DNF Aion::Type::Espresso/`). В отличие от `Aion::Type::DNF` (эквивалентные преобразования), здесь выражение приводится к **минимальному покрытию кубов** итеративным алгоритмом Эспрессо.

Сейчас роль **пустая** – ниже спецификация (набор примеров), под которую будет реализован алгоритм. Примеры берут DNF-выражение (после `_simplify`) и показывают целевой минимум. Каждая строка в блоке кода – вход, а `# => справа` – ожидаемый минимум.

Псевдокод (для одного выходного пространства):

	espresso(F, D):
	    R = complement(F ∪ D)
	    F = expand(F, R)
	    F = irredundant(F, D)
	    E = essentials(F, D)
	    F -= E; D |= E
	    repeat:
	        do:
	            F = reduce(F, D)
	            F = expand(F, R)
	            F = irredundant(F, D)
	        while (|F| improves)
	        F = last_gasp(F, D, R)
	    while (cost(F) improves)
	    return F | E

Здесь `F` – покрытие, `D` – «don't-care», `R` – дополнение (запрещённые кубы). Для типов Aion куб – примитивный аспект (перечисление/диапазон/длина и т.п.), а пересечение кубов даёт множество, которое может принимать значение.

Тип описывает **одно** значение, поэтому «координаты» – это оси: числовая (`Range`, `Lim`, `Len`, `LimKeys`), символическая (`Enum`). Структурные семьи (напр. `Object`, `Tuple`, `HashRef`) – отдельные вселенные, их склеивать нельзя.

## Оси и дискретность

* `Range[{from}, {to}]` – интервал **вещественных** (непрерывная ось). Всегда **две** границы. Сливаются кубы, соприкасающиеся в общей замкнутой точке; если между ними разрыв, он остаётся открытым интервалом и кубы не сливаются: `Range[1,5] | Range[6,9]` → `Range[1,5] | Range[6,9]` (между ними `Range[Open[5], Open[6]]`).
* `Len`, `Lim`, `LimKeys` – интервалы **целых положительных** (дискретная ось длины массива/строки/числа ключей). Могут задаваться одним параметром `{to}` – тогда это `{0 .. to}`: `Len[3]` = длины `0..3`. Два соседних целых (например `{3},{4}`) склеиваются в `[3,4]`, между ними значения нет.
* `Enum` – конечное символическое (дискретное) множество помеченных значений.

Дискретная ось, двухпараметровые длины:
```perl
Len[3,3] | Len[4,4]          # => Len[3,4]
Lim[3,3] | Lim[4,4]          # => Lim[3,4]
LimKeys[3,3] | LimKeys[4,4]  # => LimKeys[3,4]
```

Дискретная ось, однопараметровые длины (0..to), поглощение подмножества:
```perl
Len[2] | Len[4]  # => Len[4]
Len[2] | Len[2]  # => Len[2]
```

## Enum

```perl
Enum[1,2] | Enum[2,3]                       # => Enum[1,2,3]
Enum[1,2,3] | Enum[3]                       # => Enum[1,2,3]
Enum[1,2] | Enum[1,2,3]                     # => Enum[1,2,3]
(Enum[1,2,3] | Enum[3,4]) & Enum[2,3,4]     # => Enum[2,3,4]
Enum[1,2] & Enum[3,4]                       # => None
Enum["red"] | Enum["green","red"]           # => Enum["green","red"]
```

## Range (замкнутые границы)

```perl
Range[1,5] | Range[5,9]  # => Range[1,9]    # shared point 5
Range[1,5] | Range[4,8]  # => Range[1,8]    # overlap
Range[0,10] & Range[4,8] # => Range[4,8]
Range[5,20] & Range[6,8] # => Range[6,8]
Range[1,5] | Range[6,9]  # => Range[1,5] | Range[6,9]   # Open(5..6) remains
```

## Range с открытыми границами и бесконечностью

```perl
Range[Opened[1], 5] | Range[1, 5]        # => Range[1, 5]   # open absorbed into closed
Range[Opened[1], Opened[5]] | Range[2,4] # => Range[2,4]   # already covered
Range[1, 5] | Range[Open[5], 9]          # => Range[1, 9]   # no gap on reals
Range[0, 'Inf'] | Range['-Inf', 0]       # => Num
```

## Len (длина строки — дискретная ось)

```perl
Len[3,3] | Len[4,4]          # => Len[3,4]
Len[1,1] | Len[1,2] | Len[2,2] # => Len[1,2]
Len[2,4] & Len[3,5]          # => Len[3,4]
Len[1,2] | Len[4,4]          # => Len[1,2] | Len[4,4]   # gap {3}, no merge
Len[2] | Len[4]              # => Len[4]                # 1-arg means 0..N
```

## Lim (длина массива) и LimKeys (число ключей хэша)

```perl
Lim[3,3] | Lim[4,4]          # => Lim[3,4]
Lim[1,3] | Lim[2,5]          # => Lim[1,5]
Lim[2,4] & Lim[4,8]          # => Lim[4,4]              # singleton lengths
Lim[3,3] | ~Lim[3,3]         # => Any
LimKeys[2,3] | LimKeys[3,5]  # => LimKeys[2,5]
LimKeys[3,3] | LimKeys[2,3]  # => LimKeys[2,3]
Lim[1,2] | Lim[3,4]          # => Lim[1,2] | Lim[3,4]   # no integer between 2 and 3? none on reals counts, but 2 and 3 distinct
```

## Числовые типы и базы (Int / Num / Nat / Positive…)

```perl
Nat & Range[3, 'Inf']            # => Range[3, 'Inf']
(Nat & Range[100, 'Inf']) & Range[0, 50] # => None
PositiveInt & ~PositiveInt       # => None
PositiveInt | ~PositiveInt       # => Num
Range[51, 'Inf'] & ~Range[0, 50] # => Range[51, 'Inf']
Int | ~Int                       # => Num
Nat & Int                        # => Nat
PositiveInt | Int                # => Int           # Int supertype absorbs
```

## Сложные выражения (`&`/`|`/`~` несколько уровней)

```perl
(Enum[1,2] | Range[0,10]) & (Enum[2,3] | Range[5,20])  # => Enum[2,3] | Range[5,10]
(Len[1,3] & ~Len[2,2]) | Len[2,2]       # => Len[1,3]
(Num & Range[0,10]) | (Num & Range[5,20]) # => Num & Range[0,20]
~Enum[1,2,3] & ~Enum[3,4,5]         # => ~Enum[1,2,3,4,5]
```

## Дополнительные типы

**`Any`, `None` (`~Any`)** – универсум и пустота; с их помощью проверяешь полноту ON/OFF-покрытия.
```perl
Any & None  # => ~Any
Any | None  # => Any
Num | None  # => Num
```

**`Exclude` / `~`** – даёт `complement`, `R` и «don't-care».
```perl
Enum[1,2,3] & ~Enum[2]    # => Enum[1,3]
Enum[1,2] | ~Enum[1,2,3]  # => ~Enum[3]
Int & ~Int                # => None
```

**Открытые границы `Opened`/`Lim` и `'Inf'`** – влияют на склейку соседних кубов.
```perl
Range[0, 'Inf'] & Range['-Inf', 10]     # => Range[0, 10]
Range[Opened[0], 'Inf'] | Range[0, 'Inf'] # => Range[0, 'Inf']
```

**Числовые базы с наследниками** (`Int`, `Num`, `Nat`, `Positive…`).
```perl
PositiveInt | ~PositiveInt   # => Num
Nat & ~Range[0, 50]          # => Range[51, 'Inf']
PositiveInt | Int            # => Int
```

**`Str`/`NonEmptyStr` рядом с `Len`** – проверяет, что длины живут внутри строковой вселенной.
```perl
Str & (Len[1,1] | Len[1,2])  # => Str & Len[1,2]
NonEmptyStr & ~Len[0,0]      # => NonEmptyStr
```

**`Bool`** – двузначная ось для проверки полноты.
```perl
Bool | ~Bool # => Any
Bool & Bool  # => Bool
```

**Структурные `Object`, `Tuple`, `HashRef`, `HasMethods`, `ConsumerOf` – «не трогать»** (не координаты оси; пересечение разных вселенных пусто и не должно сливаться).
```perl
ArrayRef & HashRef    # => None
Object & ArrayRef     # => ArrayRef
ArrayRef & Enum[1]    # => ArrayRef & Enum[1]
```

**Don't-care-формулировки** – «вне» больше, чем «внутри» (проверка, что `expand`/`last_gasp` не выдаст куб без реального значения).
```perl
~Enum[1,2,3,4,5,6,7] | Enum[1,2,3]   # => ~Enum[4,5,6,7]
```

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Type::Espresso module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
