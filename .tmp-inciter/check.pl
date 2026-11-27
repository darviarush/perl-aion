use common::sense;
use Aion;

package Role::Table { use Aion -role;

	havelock table => sub {
		my ($meta, %table) = @_;

		push @{$meta->{tables}}, $meta->{have} => \%table;
	};
}

package Ex::Person { use Aion;
	with qw/Role::Table/;

	have table => (name => 'person', key => "id", columns => [qw/id name/]);

	has id => (is => 'ro');
}

package Ex::Cat { use Aion;

	have table => (name => 'cat', key => "uniq", columns => [qw/uniq/]);

	has uniq => (is => 'ro');
}

package Ex::Dog { use Aion;

	havelock table => sub { $_[0]{havelock} = 1 };

	print "1. havelock twice: ";
	my $ok = eval "package Ex::Dog; havelock(table => sub { 1 }); 1";
	print $ok? "ok\n": "die: $@";

	print "2. have table: ";
	$ok = eval "package Ex::Dog; have(table => (name => 'dog')); 1";
	print $ok? "ok, tables=" . scalar(@{$Aion::META{"Ex::Dog"}{tables}}) . "\n": "die: $@";
}

package Ex::Fox { use Aion;

	print "3. have without havelock: ";
	my $ok = eval "package Ex::Fox; have(table => (name => 'fox')); 1";
	print $ok? "ok\n": "die: $@";
}

print "4. Person: ", join(" ", map { "$_->[0]={" . join(",", map {"$_"} sort keys %{$_->[1]}) . "}" } @{$Aion::META{"Ex::Person"}{tables}}), "\n";
print "5. Cat: ", join(" ", map { "$_->[0]={" . join(",", map {"$_"} sort keys %{$_->[1]}) . "}" } @{$Aion::META{"Ex::Cat"}{tables}}), "\n";
print "6. have after: ", $Aion::META{"Ex::Person"}{have} // "undef", "\n";
