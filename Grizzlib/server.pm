#!/usr/bin/perl
use strict;
use warnings;
use feature "switch";
use IO::Socket::INET;
use threads;
use threads::shared;
use Thread::Queue;
use Grizzlib::Protocol;

$| = 1;

package Grizzlib::Server;
my $gp = new Grizzlib::Protocol;
my @readQ = (new Thread::Queue, new Thread::Queue);
my $sockQ = new Thread::Queue;
my $kilQ = new Thread::Queue;
my %killist :shared;
my %users :shared;
my $rqi :shared = 0;
my @handles;
my $socket;
my $mThread;
my $period = 2;
my $port = '9110';
my $host = '127.0.0.1';

sub new { #Host, Port, Period, Reader thread, Socket thread
	my $class = shift;
	$host = shift;
	$port = shift;
	$period = shift;
	my $self = {};
	bless $self;
	$socket = IO::Socket::INET->new(
		LocalHost => $host,
		LocalPort => $port,
		Proto => 'tcp',
		Listen => 5,
		Reuse => 1
	) or die "Could not open socket: ".$!."\n";
	$mThread = threads->create(\&main, $socket);
	foreach((1..shift)){	
		threads->create(\&handleBeaR)->detach();
	}
	foreach((1..shift)){
		threads->create(\&handleSock)->detach();
	}
	#threads->create(\&heartBeat)->detach();
	#threads->create(\&dumper)->detach();
	return $self;
}

sub mainThread {
	return $mThread;
}

sub handleSock {
	my @bears;
	my %dToBear;
	while(my $conn = $sockQ->dequeue()){
		my $sock = new IO::Socket::INET;
		my $handle = $sock->fdopen($$conn[1], "w+");
		if(!defined($handle)){
			next;
		}
		if(exists($dToBear{$$conn[1]})){
			splice @bears, $dToBear{$$conn[1]}, 1;
			delete $dToBear{$$conn[1]};
		}
		$dToBear{$$conn[1]} = scalar(@bears);
		push(@bears, $sock);
		while(defined(my $target = $kilQ->dequeue_nb())){
			print "Target: ".$target."\n";
			if(exists($dToBear{$target})){
				splice @bears, $dToBear{$target}, 1;
				delete $dToBear{$target};
			}
			delete $killist{$target};
		}
	}
}

sub killBear {
	$kilQ->enqueue(shift);
	return -1;
}

sub handleBeaR {
	my $sock = new IO::Socket::INET;
	my $rq = $rqi;
	while(my $conn = $readQ[$rq]->dequeue()){
		my $filen = $$conn[1];
		my $bear = $sock->fdopen($filen, "w+");
		if(!defined($bear)){
			print "DISC $filen\n";
			if(!$readQ[$rq]->pending()){
				$rqi = ($rq+1) % 2;
			}
			$rq = $rqi;
			next;
		}
		$bear->blocking(0);
		while(1){
			my $ln = $bear->getline();
			last unless defined($ln);
			last if !$gp->lineValid($ln);
			if($gp->heartBeat eq $ln){
				my $now = time();
				print "HeartBeat from clientID $$conn[0]-".Socket::inet_ntoa($bear->peeraddr)."\n";
				if($filen == 5 && !exists($killist{$filen})){
					$killist{$filen} = 1;
					killBear($filen);
				}
				last;
			}
			chomp($ln);
			given(substr($ln,0,4)){
				when($gp->auth) {
					my ($username, $password, $crap) = split(/:/, substr $ln, 5);
					print "U: $username | P: $password\n";
					$bear->send("$username\n");
				}
				when($gp->pSrv) { sleep 1; }
				when($gp->pMsg) { sleep 1; }
				when($gp->pStt) { sleep 1; }
			}
		}
		close $bear;
		$readQ[($rq+1) % 2]->enqueue($conn);
		if(!$readQ[$rq]->pending()){
			$rqi = ($rq+1) % 2;
		}
		$rq = $rqi;
	}
}

sub dumper {
	while(1){
		
		sleep 2;
	}
}

sub main {
	my $socket = shift;
	print "Server running...\n";
	while(1) {
		my $bSocket = $socket->accept();
		my $conn_id = int(rand()*100000000)+1;
		my @info = ($conn_id, fileno($bSocket));
		$sockQ->enqueue(\@info);
		while($sockQ->pending()) {}
		my $rq = $rqi;
		if($readQ[$rq]->pending()){
			$readQ[($rq+1) % 2]->enqueue(\@info);
		}else{
			$readQ[$rq]->enqueue(\@info);
		}
	}
}

1;