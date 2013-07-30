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
use Digest::MD5 qw(md5 md5_hex md5_base64);
use YAML qw<DumpFile LoadFile>;
  

our $PATH = shift @ARGV or die("Where are the files -d ");
our $master = {};


use constant OUTPUT    => '/home/santex/repos/searched-micros/json/';
mkpath( OUTPUT );
our $memd = new Cache::Memcached::Fast({
	 servers => [ { address => '127.0.0.1:11211', weight => 2.5 }],
	 namespace => 'my:',
	 connect_timeout => 0.2,
	 io_timeout => 0.1,
	 close_on_error => 1,
	 compress_threshold => 100_000,
	 compress_ratio => 0.9,
	 max_failures => 1,
	 max_size => 512 * 1024,
	});

our $date = `date  +"%Y-%m-%d"`;
	
sub fread {
	my $fn = shift;
	 	
	 if (-f $fn && $fn =~ /\.json$/) {
       open (IN, "<$fn") || warn "Could not open $fn: $!\n", return (0);
       my @lines = <IN>;
       close IN;
       return join("",@lines);
       
    }
}
sub init { 
	
	
	print `cd   $PATH`;
	
	$master = {};#$memd->get("master");
	
	
}
our $dir = "";
our $d = {};
sub addToMaster {
		
	my @last = ();
	my @sized = ();
	my @sizedm=();
	my $count = 0;
	MAIN:
	for (parse_dir(`ls -lR  $PATH`)) {
		
		my ($name, $type, $size, $mtime, $mode) = @$_;

    if(-d $name){
      next;
    }
		
		if(-f $name){
		
        

				
				$d = {};
				$d->{content} = fread($name);	
        next if (length(Dumper($d->{content}))<=1024*2);
        $d->{size} = sprintf("%d",length(Dumper($d->{content}))/1024);
          
				next unless($d->{size}>2);
        #die($d->{content});

        my @dirs=split("\/",$name);
				$d->{name} = $dirs[$#dirs];
        #p @dirs;
        #p $d;
        #die();
				$d->{name} =~ s/(.json)//g;


        if(-d $d->{name}){
          next;
        }
        
        next MAIN unless($d->{name}!~/\W/); 
				next unless(!$master->{$d->{name}});		
				next unless($d->{content}=~/^[\{]/);

				
        
        
				
 #       $d->{content} =  JSON::XS->new->allow_nonref->allow_blessed->decode($d->{content});
	#			if($d->{content}->{links}){
					
#					$d->{content}->{links} = [sort grep{/^http/}@{$d->{content}->{links}}];
					
		#		}

				#next if ($d->{size}<mean(@size));
				print ".";
			#		next MAIN;
				push @size,$d->{size};					
				$memd->set($d->{name},$d->{content});
				
				
				push @last,{name=>$d->{name},size=>$d->{size}};
          
				if(max(@sized) < $d->{size}) {
					push @sizedm,{name=>$d->{name},size=>$d->{size}};	

					
				}
				
			
			
			
			
			my $check = $memd->get($d->{name});
			
			if(defined($d->{content}) && !defined($d->{content}->{"created"}) && !$@){
			
				$d->{content}->{"created"}=time();
				
				$memd->set($d->{name},$d->{content});
		
			
			}
			
	}
			

			$master->{files}->{$d->{name}} = $d->{size};
			$master->{files}->{$d->{name}} = $master->{files}->{$d->{name}} > 250 ? 250 : $master->{files}->{$d->{name}} ;
			
			if($count % 2500 == 1){
				print $count;
         
			}
			$count++;



	
  }	


my @names = sort keys %{$master->{files}};
	 my @vals = values %{$master->{files}};
	 $master->{stats}->{files} = [@names];
	 $master->{stats}->{mean} = sprintf("%3.4f",mean(@vals));
	 $master->{stats}->{min} = min(@vals);
	 $master->{stats}->{max} = max(@vals);	 
   $memd->set(md5_hex("master"),$master->{stats});
   
    return $master;
	
}
init;
$master = addToMaster();
#$memd->set(md5_hex("master"),$master->{stats});
#$master = $memd->get(md5_hex("master"));
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
