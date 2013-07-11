use WWW::Wikipedia;
use Data::Dumper;
use Data::Printer;
use Data::Freq;
my $data = Data::Freq->new;

		   my $wiki = WWW::Wikipedia->new();
           my $entry = $wiki->search( 'Physics' );
			my @all = ();
		
		if($entry->text_basic){
                  @all = ();  		  
                  push @all,$entry->title();
		  push @all,$entry->related();
	          push @all,$entry->categories();

			
                  $data->add(join("\n",@all));
                  	
		}
		


print            $data->output();

		
__DATA__
 use threads;


 sub thread_job {
  $key = shift;
  $key=`mojo get 127.0.0.1:3000/all:$key`;
  
  
 }

 threads->new(\&thread_job,$_) for(split("\n",`micro any all 



