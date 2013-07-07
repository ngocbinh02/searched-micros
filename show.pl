#!/usr/bin/perl

use strict;
use warnings;
use JSON::XS;
use Cache::Memcached::Fast;
use Data::Dumper;
use Data::Printer;
use File::Listing qw(parse_dir);
use AI::Classifier::Text::Analyzer;
use Statistics::Basic qw(:all);
use List::Util qw(min max);

our $PATH = shift || "." ;
our $master = {};
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
	
	$PATH = shift || "." ;
	print `cd   $PATH`;
	
	$master = $memd->get("master");
}

our $dir = "";
our $d = {};



sub addToMaster {
		
	for (parse_dir(`ls -lR  $PATH`)) {
		
		my ($name, $type, $size, $mtime, $mode) = @$_;

		if( -f $name){
		
			
			if($name ne __FILE__){
				$d = {};
				$d->{content} = `cat $name`;
				$d->{content} =  JSON::XS->new->allow_nonref->allow_blessed->decode($d->{content});
				$d->{name} = $name;
				$d->{name} =~ s/($PATH\/|$dir\/|.json)//g;
			}
			
			print	$d->{name} ,"\n";
			$memd->set($d->{name},$d->{content});
			$master->{files}->{$d->{name}} = length(Dumper($d->{content}));

		}
	}
		
	 my @vals = values %{$master->{files}};
	 $master->{stats}->{mean} = sprintf("%3.4f",mean(@vals));
	 $master->{stats}->{min} = min(@vals);
	 $master->{stats}->{max} = max(@vals);


     $memd->set("master",$master);
	
}

init;

addToMaster();

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
