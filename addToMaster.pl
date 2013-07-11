#!/usr/bin/perl
use File::Path;
use JSON::XS;
use Cache::Memcached::Fast;
use Data::Dumper;
use Data::Printer;
use File::Listing qw(parse_dir);
use AI::Classifier::Text::Analyzer;
use Statistics::Basic qw(:all);
use List::Util qw(min max);
        use threads;
our $PATH = shift @ARGV or die("Where are the files -d ");
our $master = {};
use constant OUTPUT    => '/home/santex/repos/searched-micros/json/';
mkpath( OUTPUT );
our $memd = new Cache::Memcached::Fast({
	 servers => [ { address => 'localhost:11211', weight => 2.5 }],
	 namespace => 'my:',
	 connect_timeout => 0.2,
	 io_timeout => 0.1,
	 close_on_error => 1,
	 compress_threshold => 100_000,
	 compress_ratio => 0.9,
	 max_failures => 1,
	 max_size => 512 * 1024,
	});
	
sub init { 
	
	
	print `cd   $PATH`;
	
	$master = $memd->get("master");
	
	
}
our $dir = "";
our $d = {};
sub addToMaster {
		
	my @last = ();
	my @sized = ();
	my @sizedm=();
	MAIN:
	for (parse_dir(`ls -lR  $PATH`)) {
		
		my ($name, $type, $size, $mtime, $mode) = @$_;
	
		if(-f $name){
		
			
			if($name ne __FILE__){
				$d = {};
				$d->{content} = `cat $name`;
				$d->{content} =  JSON::XS->new->allow_nonref->allow_blessed->decode($d->{content});
				$d->{name} = $name;
				$d->{name} =~ s/($PATH\/|$dir\/|.json)//g;
				
				
				if($master->{files}->{$d->{name}}){
			##		print ".";
					next MAIN;
				}
			
				
				push @last,{name=>$d->{name},size=>length($d->{content})};
				
				if(max(@sized) <= length(Dumper($d->{content}))) {
					push @sizedm,{name=>$d->{name},size=>length(Dumper($d->{content}))};	
					push @size,length(Dumper($d->{content}));	
					
				}
				
			}
			
			
			
			my $check = $memd->get($d->{name});
			
			if(defined($d->{content}) && !defined($d->{content}->{"created"}) && !$@){
			
				$d->{content}->{"created"}=time();
				
				$memd->set($d->{name},$d->{content});
		
			
			}
			
	}
			

			$master->{files}->{$d->{name}} = 10+sprintf("%d",length(Dumper($d->{content}))/1024);
			$master->{files}->{$d->{name}} = $master->{files}->{$d->{name}} > 60 ? 60 : $master->{files}->{$d->{name}} ;
			
			
		
	}
		
	 my @vals = values %{$master->{files}};
	 $master->{stats}->{mean} = sprintf("%3.4f",mean(@vals));
	 $master->{stats}->{min} = min(@vals);
	 $master->{stats}->{last}  = [];
	 $master->{stats}->{large}  = [];
	 $master->{files}={};
	 foreach(0..15){
	 my $n = pop @last;
	 push @{$master->{stats}->{last}} ,$n unless(!$n);
	 }
	 
	 foreach(0..30){
	 my $n = shift @sizedm;
	 push @{$master->{stats}->{large}} ,$n unless(!$n);
	 }
	 
	 $master->{stats}->{max} = max(@vals);
     $memd->set("master",$master);
	
}
init;
addToMaster();
$memd->set("master",$master);
p $master;
1;
__DATA__
           my $analyzer = AI::Classifier::Text::Analyzer->new();
           my $features = $analyzer->analyze(Dumper($master));
my @vals = values %$features;
my $mean = mean(@vals);
foreach(keys %$features){
printf("\n%s\t%s",$features->{$_},$_) if($features->{$_}>=$mean*10);
	
}
1;
