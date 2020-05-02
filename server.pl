#!/usr/bin/perl
use strict;
use warnings;
use Cwd qw(cwd);
use lib cwd();
use Grizzlib::Server;
print "Initializing the server...\n";
my $server = Grizzlib::Server->new('127.0.0.1', '9110', 2, 10);
$server->mainThread->join();