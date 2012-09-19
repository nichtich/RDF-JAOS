## RDF::JAOS

The Perl module **RDF::JAOS** implements a simple web application to document
and serve RDF ontologies. The application is implement with Plack

## SYNOPSIS

Create a subdirectory `data` with RDF ontologies in Turtle or RDF/XML syntax.
Then just run the application with:

   plackup -Ilib app/jaso.psgi

Locate your browser to <http://localhost:500>. Modify the templates in
subdirectory `share` to adjust the layout.

## BACKGROUND

On startup all ontology files are parsed with RDF::Trine.

