#!/usr/bin/perl
use strict;
use warnings;
use Cwd qw(cwd);
use lib cwd();
use IO::Socket::INET;
use threads;
use Grizzlib::Client;

my $client = Grizzlib::Client->new(2);
$client->rThread->join();