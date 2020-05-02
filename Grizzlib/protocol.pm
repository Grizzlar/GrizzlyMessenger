#!/usr/bin/perl
use strict;
use warnings;

package Grizzlib::Protocol;

my $auth = "AUTH";
my $beat = "\n";
my $rate = 1;
my $pSrv = "SERV";
my $pMsg = "MESG";
my $pStt = "STAT";

sub heartRate {
	return $rate;
}
sub heartBeat {
	return $beat;
}
sub auth {
	return $auth;
}
sub pSrv {
	return $pSrv;
}
sub pMsg {
	return $pMsg;
}
sub pStt {
	return $pStt;
}

sub new {
	my $self = {};
	bless $self;
	return $self;
}

sub lineValid {
	my $ln = $_[1];
	if($ln eq "\n"){
		return 1;
	}
	if(length($ln) != 1024){
		return 0;
	}
	return 1;
}

1;