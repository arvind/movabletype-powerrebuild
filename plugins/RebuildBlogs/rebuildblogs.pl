#!/usr/bin/perl
package MT::Plugin::RebuildBlogs;
use strict;
use MT;
use MT::Plugin;
use vars qw($VERSION);
$VERSION = '0.1';
my $about = {
	dir => 'RebuildBlogs',
  name => 'Rebuild Multiple Blogs',
  config_link => 'mt-rebuild-blogs.cgi',
  description => 'Adding the ability to rebuild multiple blogs at once.',
  doc_link => 'http://www.papascott.de/archives/2004/08/12/hello-world-as-an-mtapp-cgi/'
}; 
MT->add_plugin(new MT::Plugin($about));