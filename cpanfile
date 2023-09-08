requires 'perl', '5.008001';

on 'test' => sub {
    requires 'Liveman',
        git => 'https://github.com/darviarush/perl-liveman.git',
        ref => 'master'
    ;
};

requires 'Attribute::Handlers', '1.03';
requires 'common::sense', '3.75';
requires 'Data::Printer', '1.000004';
requires 'Exporter', '5.77';
requires 'Math::BigInt', '1.999837';
requires 'List::Util', '1.63';
requires 'Scalar::Util', '1.63';
requires 'Sub::Util', '1.63';

requires 'config',
    git => 'https://github.com/darviarush/perl-config.git',
    ref => 'master'
;


