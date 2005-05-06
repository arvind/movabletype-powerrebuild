#!/usr/bin/perl
package MT::Plugin::RebuildBlogs;
use strict;
use MT;
use MT::Plugin;
use vars qw($VERSION);
$VERSION = '1.0';
my $about = {
	dir => 'RebuildBlogs',
  name => 'MT RebuildBlogs v'.$VERSION,
  config_link => 'mt-rebuild-blogs.cgi',
  description => 'Adds the ability to rebuild multiple blogs at once.',
  doc_link => 'http://www.movalog.com:82/cgi-bin/trac.cgi/wiki/MtRebuildBlogs'
}; 
MT->add_plugin(new MT::Plugin($about));