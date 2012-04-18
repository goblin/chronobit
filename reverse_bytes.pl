#! /usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use IO::All;

my $foo = io('-')->slurp;

print scalar reverse $foo;
