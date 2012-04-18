#! /usr/bin/perl

use strict;
use warnings;

use AnyEvent;
use JSON::XS;
use AnyEvent::JSONRPC::HTTP::Client;
use Data::Dumper;

$Data::Dumper::Useqq = 1;

my $client = AnyEvent::JSONRPC::HTTP::Client->new(
	url => $ARGV[0]
);

print Dumper($client->call(@{decode_json($ARGV[1])})->recv);
