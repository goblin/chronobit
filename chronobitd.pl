#! /usr/bin/perl

use strict;
use warnings;

use AnyEvent;
use JSON::XS;
use AnyEvent::JSONRPC::HTTP::Server;
use YAML::Syck;
use Data::Dumper;
use Log::Log4perl;

use ChronoBit::Bitcoin;
use ChronoBit::Util;
use ChronoBit::JSONRPC;

my $cfg = LoadFile('chronobit.conf');
Log::Log4perl->init_and_watch($cfg->{log_conf}, 5);
my $log = Log::Log4perl->get_logger;

my $jsonrpc = ChronoBit::JSONRPC->new(cfg => $cfg);

sub jsonrpc_handler {
	my ($method, $res_cv, @params) = @_;

	$res_cv->result($jsonrpc->$method(@params));
}

my %callbacks = map { my $m = $_; $m => sub { jsonrpc_handler($m, @_); } } $jsonrpc->all_methods();

my $server = AnyEvent::JSONRPC::HTTP::Server->new( port => $cfg->{port}, host => '0.0.0.0' );
$server->reg_cb(%callbacks);

$log->info('starting');
my $quit_program = AnyEvent->condvar;
$quit_program->recv;
