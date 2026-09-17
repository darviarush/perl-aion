use common::sense;
use Aion;

package Role::Table { use Aion -role;

	inciter table => sub {
		my ($meta, %table) = @_;

		push @{$meta->{tables}}, $meta->{have} => \%table;
	};
}

package Ex::Person { use Aion;
	with qw/Role::Table/;

	have table => (key => "id", columns => [qw/id name/]);

	has id => (is => 'ro');
}

package Ex::Cat { use Aion;

	have table => (key => "uniq", columns => [qw/uniq/]);

	has uniq => (is => 'ro');
}

package Ex::Dog { use Aion;

	inciter table => sub { die "exists" };
}

print "1. loaded\n";
print "2. ", join(" ", map { "$_->[0]={" . join(",", map {"$_=>"} sort keys %{$_->[1]}) . "}" } @{$Aion::META{"Ex::Person"}{tables}}), "\n";
print "3. ", join(" ", map { "$_->[0]={" . join(",", map {"$_=>"} sort keys %{$_->[1]}) . "}" } @{$Aion::META{"Ex::Cat"}{tables}}), "\n";
print "4. ", join("|", sort keys %{$Aion::META{"Ex::Dog"}{inciter}}), "\n";
print "5. have = ", $Aion::META{"Ex::Person"}{have} // "undef", "\n";

package Ex::Fox { use Aion;
	eval { have table => (key => "id") }; print "6. $@";
	have table => (key => "id");
	print "7. have = ", $Aion::META{"Ex::Fox"}{have}, "\n";
	print "8. tables = ", scalar @{$Aion::META{"Ex::Fox"}{tables}}, "\n";
}
