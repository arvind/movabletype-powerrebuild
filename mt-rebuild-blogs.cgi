#!/usr/bin/perl -w
use strict;
my($MT_DIR);
BEGIN {
  if ($0 =~ m!(.*[/\\])!) {
    $MT_DIR = $1;
  } else {
    $MT_DIR = './';
  }
  unshift @INC, $MT_DIR . 'lib';
  unshift @INC, $MT_DIR . 'extlib';
}
eval {
  require arvinds::rebuildblogs;
  my $app = arvinds::rebuildblogs->new (
    Config => $MT_DIR . 'mt.cfg',
    Directory => $MT_DIR
  ) or die arvinds::rebuildblogs->errstr;
  local $SIG{__WARN__} = sub { $app->trace ($_[0]) };
  $app->run;
};
if ($@) {
  print "Content-Type: text/html\n\n";
  print "An error occurred: $@";
}