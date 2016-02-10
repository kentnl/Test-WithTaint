requires 'perl', '5.006';
requires 'strict';
requires 'warnings';

on test => sub {
    requires 'Test::More';
    requires 'strict';
    requires 'warnings';
};

on develop => sub {
    requires 'CPAN::Meta::Converter';
    requires 'CPAN::Meta::Prereqs';
    requires 'Carp';
    requires 'Config';
    requires 'Data::Dumper';
    requires 'Exporter';
    requires 'ExtUtils::MM';
    requires 'ExtUtils::MakeMaker';
    requires 'ExtUtils::Manifest';
    requires 'File::Find';
    requires 'File::Path';
    requires 'File::Spec';
    requires 'File::Temp';
    requires 'Getopt::Long';
    requires 'Module::CPANfile';
    requires 'Module::Metadata';
    requires 'PIR';
    requires 'Path::Tiny';
    requires 'Perl::PrereqScanner';
    requires 'Pod::Coverage::TrustPod';
    requires 'Pod::Perldoc::ToPod';
    requires 'Test::CPAN::Changes';
    requires 'Test::EOL';
    requires 'Test::More', '0.96';
    requires 'Test::Perl::Critic';
    requires 'Test::Pod', '1.41';
    requires 'Test::Pod::Coverage', '1.08';
    requires 'base';
    requires 'lib';
    requires 'perl', '5.006';
    requires 'strict';
    requires 'warnings';
};
