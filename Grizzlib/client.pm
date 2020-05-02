#!/usr/bin/perl
use strict;
use warnings;
use IO::Socket::INET;
use threads;
use Grizzlib::Protocol;

$| = 1;

package Grizzlib::Client;
my $gp = new Grizzlib::Protocol;
my $period = 2;
my $socket;
my $bearR;
sub new {
	my $class = shift;
	$period = shift;
	my $self = {};
	bless $self;
	$socket = IO::Socket::INET->new(
		PeerHost => '127.0.0.1',
		PeerPort => '9110',
		Proto => 'tcp',
		Blocking => '0',
	) or die "Could not open socket: ".$!."\n";
	threads->create(\&heart, $socket)->detach();
	#$socket->send("AUTH Test:GRIZZLE:".("0"x1006)."\n");
	$bearR = threads->create(\&beaR, $socket);
	return $self;
}

sub rThread {
	return $bearR;
}

sub beaR {
	my $bear = shift;
	while(1) {
		while(1){
			my $ln = $bear->getline();
			last unless defined($ln);
			print $ln;
		}
		sleep $period;
	}
}

sub heart {
	my $bear = shift;
	while(1){
		$bear->send($gp->heartBeat);
		sleep $gp->heartRate;
	}
}

1;