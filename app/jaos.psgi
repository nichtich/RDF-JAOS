use 5.10.0;
use RDF::JAOS;
use Dancer;

use File::ShareDir 'module_dir';
use File::Spec::Functions qw(rel2abs catfile);

#set appdir => rel2abs( module_dir('RDF::JAOS') ); 
set views  => rel2abs( path( module_dir('RDF::JAOS'), 'views' ) ); 
set public => rel2abs( path( module_dir('RDF::JAOS'), 'public' ) ); 

start;
