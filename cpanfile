requires 'perl', '5.22.0';

on 'test' => sub {
    requires 'Test::More', '0.98';

    requires 'Carp';
    requires 'common::sense';
    requires 'File::Basename';
    requires 'File::Path';
    requires 'File::Slurper';
    requires 'File::Spec';
    requires 'Scalar::Util';
};

requires 'common::sense', '3.75';
requires 'config', '1.3';
requires 'diagnostics', '0';
requires 'feature', '0';
requires 'overload', '1.37';
requires 'strict', '0';
requires 'warnings', '1.70';
requires 'Aion::Type', '0';
requires 'Aion::Types', '0';
requires 'Attribute::Handlers', '1.03';
requires 'DDP', '0';
requires 'Exporter', '5.77';
requires 'List::Util', '1.63';
requires 'Math::BigInt', '1.999837';
requires 'Math::BigInt::Calc', '0';
requires 'Math::BigInt::FastCalc', '0';
requires 'Math::BigInt::Lib', '0';
requires 'Math::BigInt::Trace', '0';
requires 'Scalar::Util', '1.63';
requires 'Sub::Util', '1.63';
