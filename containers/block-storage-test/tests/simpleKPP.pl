#!/usr/bin/perl
#

package Stat;

my %units = (
	'BlkAllBW'  => 'GB/s',
	'BlkRanBW'  => 'GB/s',
	'BlkSeqBW'  => 'GB/s',
	'BlkAllIOP' => 'IOPS',
	'BlkRanIOP' => 'IOPS',
	'BlkSeqIOP' => 'IOPS',
	'XX'        => 'XX',
);

sub unitLookUp($) {
	my $prop = shift;
	my $units = $units{$prop};
	
	return $units if (defined($units));
	
	$_ = $prop;
	m#^Blk# and return 'MB/s';
	m#^Obj# and return 'KB/s';
	m#^netSCP# and return 'MB/s';
}

sub new($@) {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	
	my $self = {
		ts     => shift,
		name   => shift || 'X',
		units  => shift || '?',
		values => [],
	};
	bless($self, $class);
	return $self;
}

sub add($$) {
	my $self = shift;
	my $val = shift;
	
	push(@{$self->{values}}, $val);
}

sub summary($) {
	my $self = shift;
	my $sum = 0;
	my $cnt = 0;
	
	foreach my $v (@{$self->{values}}) {
		$cnt++;
		$sum += $v;
	}
	my $avg = $sum / $cnt;
	my $units = unitLookUp($self->{name});
	
	print("$self->{ts},$self->{name},$avg, $units\n");
}

sub summaryJson($) {
	my $self = shift;
	my $sum = 0;
	my $cnt = 0;
	
	foreach my $v (@{$self->{values}}) {
		$cnt++;
		$sum += $v;
	}
	my $avg = $sum / $cnt;
	my $units = unitLookUp($self->{name});
	
	if ($timestampValue ne $self->{ts}) {
		if ($timestampValue eq "") { print('"results": [{'); }
		else { print("},{"); }
		$timestampValue = $self->{ts};
		$timestampValue =~ s/ /'T'/;
		printf('"timeStamp": "%s"', $timestampValue);
	}
	print(',');
	printf('"%s": %s', $self->{name}, $avg);
}

1;

package Metric;

sub new($@) {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	
	my $self = {
		stats => {},
		props => {},
	};
	bless($self, $class);
	return $self;
}

sub add($$$$) {
	my $self = shift;
	my $ts = shift;
	my $metric = shift;
	my $value = shift;
	
	return if ( $metric eq 'BlkW');
	
	my $key = $metric.'/'.$ts;
	my $s = $self->{stats}->{$key};
	unless(defined $s) {
		$s = new Stat($ts, $metric);
		$self->{stats}->{$key} = $s;
	};
	$s->add($value);
}

sub singleton($$$) {
	my $self = shift;
	my $metric = shift;
	my $value = shift;
	
	$self->{props}->{$metric} = $value;
}

sub summary($) {
	my $self = shift;
	
	print "Timestamp,Metric,Value,Units\n";
	foreach my $k (sort sizeSort keys %{$self->{stats}}) {
		my $item = $self->{stats}->{$k};
		$item->summary();
	}
	
	print "\n\nProperty,Value\n";
	foreach my $k (sort keys %{$self->{props}}) {
		print "$k,", $self->{props}->{$k}, "\n";
	}
}

sub summaryJson($) {
	my $self = shift;
	
	print '{';
	
	foreach my $k (sort keys %{$self->{props}}) {
		print "\"$k\": ", "\"$self->{props}->{$k}\",";		
	}
	
	foreach my $k (sort sizeSort keys %{$self->{stats}}) {
		my $item = $self->{stats}->{$k};
		$item->summaryJson();
	}
	
	print("}]}");
	print("\n");
}

sub sizeSort {
	my $A = $a;
	my $B = $b;
	
	$A =~ s#(\.?\d+)/#sprintf("%015d/", $1)#e;
	$A =~ s#(\.?\d+KB)/#sprintf("%015d/", $1 * 1000)#e;
	$A =~ s#(\.?\d+MB)/#sprintf("%015d/", $1 * 1000000)#e;
	$A =~ s#(\.?\d+GB)/#sprintf("%015d/", $1 * 1000000000)#e;
	$A =~ s#(\.?\d+TB)/#sprintf("%015d/", $1 * 1000000000000)#e;
	$B =~ s#(\.?\d+)/#sprintf("%015d/", $1)#e;
	$B =~ s#(\.?\d+KB)/#sprintf("%015d/", $1 * 1000)#e;
	$B =~ s#(\.?\d+MB)/#sprintf("%015d/", $1 * 1000000)#e;
	$B =~ s#(\.?\d+GB)/#sprintf("%015d/", $1 * 1000000000)#e;
	$B =~ s#(\.?\d+TB)/#sprintf("%015d/", $1 * 1000000000000)#e;
	
	return $A cmp $B;
}

1;

package main;

my %humanSize = (
	'1024'          => '1KB',
	'10240'         => '10KB',
	'102400'        => '100KB',
	'104857'        => '100KB',
	'1048576'       => '1MB',
	'10485760'      => '10MB',
	'1073741824'    => '1GB',
	'10737418240'   => '10GB',
	'107374182400'  => '.1TB',
	'109951162777'  => '.1TB',
	'1099511627776' => '1TB',
);

my $info = new Metric();

my %monthNumber = (
	'Jan'  =>  1,
	'Feb'  =>  2,
	'Mar'  =>  3,
	'Apr'  =>  4,
	'May'  =>  5,
	'Jun'  =>  6,
	'Jul'  =>  7,
	'Aug'  =>  8,
	'Sep'  =>  9,
	'Oct'  => 10,
	'Nov'  => 11,
	'Dec'  => 12,	
);

sub scan($) {
	my $file = shift;
	my $op = '';
	my $app = '';
	my $fs = '';
	my $tsize = '';
	my $sz = undef;
	my $ncopy = 0;

	my $ln = 0;
	open(F,$file);
	while ($_ = <F>) {
		$ln++;
		
		# Timestamp
		m#^(\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d)# and $ts = $1;
		m#Benchmark Run: \w+ (\w+) (\d+) (\d\d\d\d) (\d\d:\d\d:\d\d)# and do {
			$ts = sprintf("4d-%02d-%02d %s", $3, $monthNumber{$1}, $2, $4);
			next;
		};
		
		# Remove carriage returns
		s/\r//g;
		
		# Header information
		m#LABEL. Metric: (\S+)# and do { $info->singleton('metric', $1); next; };
		m#LABEL. Hostname: (\S+)# and do { $info->singleton('hostname', $1); next; };
		
		m#LABEL. Start Time: (\S+)# and do {
			my $startTime = "$1";
			$info->singleton('startTime', $startTime); next; 
		};

		m#LABEL. Stop Time: (\S+)# and do {
			my $stopTime = "$1";
			$info->singleton('endTime', $stopTime); next; 
		};
		
		m#LABEL. Block Store Units: (\S+)# and do { $info->singleton('blockStoreUnits', $1); next; };
		m#LABEL. File System Type: (\S+)# and do { $info->singleton('fileSystemType', $1); next; };
		
		# File operations
		m#diskBW : (\S+) GB/s# and do { info->add($ts, 'BlkAllBW', $1); next; };
		m#sequenBW : (\S+) GB/s# and do { info->add($ts, 'BlkSeqBW', $1); next; };
		m#randomBW : (\S+) GB/s# and do { info->add($ts, 'BlkRanBW', $1); next; };
		m#^iops : (\S+) IOPS# and do { info->add($ts, 'BlkAllIOP', $1); next; };
		m#sequen_iops : (\S+) IOPS# and do { info->add($ts, 'BlkSeqIOP', $1); next; };
		m#random_iops : (\S+) IOPS# and do { info->add($ts, 'BlkRanIOP', $1); next; };
		
		# Block Store read/write
		m#LABEL. (\S+) Block (\w+) (\d+) bytes# and do {
			$fs = $1; $tsize = $humanSize{$3} || $3;
			next;
		};
		m#BinaryGen (\S+) MB/s# and do {
			my $r = $1;
			$info->add($ts, 'Blk'.'W'.$tsize, $r); next;
		};
		m#copied, \S+ s, (\S+) (.)B/s# and do {
			my $r = $1;
			$r /= 1024 if ($2 eq 'k' || $2 eq 'K');
			$r *= 1024 if ($2 eq 'G');
			$info->add($ts, 'Blk'.'R'.$tsize, $r); next;
		};
	}
	close(F);
}

use Getopt::Long;

my %opts = (
	verbose => 0,
);
my $result = GetOptions(\%Opts,
	"verbose!",
);

foreach my $file ( @ARGV ) {
	scan($file);
}

#$info->summary();
$info->summaryJson();