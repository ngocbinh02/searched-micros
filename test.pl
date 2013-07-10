 use threads;


 sub thread_job {
  $key = shift;
  $key=`mojo get 127.0.0.1:3000/all:$key`;
  print STDOUT $key;
  
 }

 threads->new(\&thread_job,$_) for(split("\n",`micro any 3`));
 
