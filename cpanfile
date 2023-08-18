requires 'perl', '5.008001';

on 'test' => sub {
    requires 'Liveman',
        git => 'https://github.com/darviarush/perl-liveman.git',
        ref => 'master'
    ;
};

requires 'Data::Printer', '1.000004';

requires 'config',
    git => 'https://github.com/darviarush/perl-config.git',
    ref => 'master'
;


