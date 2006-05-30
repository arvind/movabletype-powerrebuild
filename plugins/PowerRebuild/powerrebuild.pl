#!/usr/bin/perl
use MT;
MT->add_plugin(MT::Plugin::PowerRebuild->new);

package MT::Plugin::PowerRebuild;
use strict;
use base qw( MT::Plugin );
use vars qw($VERSION);
$VERSION = '1.1';
use MT::Blog;
use MT::Entry;
use MT::Comment;
use MT::TBPing;
use MT::Permission;

sub name { 'Power Rebuild' }
sub description { 'Adds the ability to rebuild (or publish) any item in the system' }
sub version { $VERSION }
sub doc_link { 'http://plugins.movalog.com/powerrebuild/manual' }
sub author_link { 'http://www.movalog.com/' }
sub author_name { 'Arvind Satyanarayan' }

sub init_app {
    my $plugin = shift;
    my($app) = @_;
    return unless $app->isa('MT::App::CMS');
    $app->add_itemset_action({
        type  => 'blog',
        key   => 'rebuild_blogs',
        label => 'Rebuild Blogs',
        code  => sub { rebuild_blogs($plugin, @_) },
        condition => sub { $plugin->perm_check($app) },      
    });
    $app->add_itemset_action({
        type  => 'template',
        key   => 'rebuild_template',
        label => 'Rebuild Templates',
        code  => sub { rebuild_templates($plugin, @_) },
        condition => sub { $plugin->perm_check($app) }, 
    });    
    $app->add_itemset_action({
        type  => 'comment',
        key   => 'rebuild_comments',
        label => 'Rebuild Comments',
        code  => sub { rebuild_entries($plugin, @_) },
        condition => sub { $plugin->comments_perm_check($app) }, 
    });
    $app->add_itemset_action({
        type  => 'ping',
        key   => 'rebuild_trackbacks',
        label => 'Rebuild Trackbacks',
        code  => sub { rebuild_entries($plugin, @_) },
        condition => sub { $plugin->comments_perm_check($app) }, 
    });               
    $app->add_methods(
        rebuild_blogs => sub { rebuild_blogs($plugin, @_) },
    );    
    $app->add_methods(
        rebuild_templates => sub { rebuild_templates($plugin, @_) },
    );      
    $app->add_methods(
        rebuild_entries => sub { rebuild_entries($plugin, @_) },
    );    
}

sub comments_perm_check {
    my $plugin = shift;
    my ($app) = @_;
    my $perms = $app->{perms};
    $perms ? $perms->can_edit_all_posts : $app->user->is_superuser;
}

sub perm_check {
    my $plugin = shift;
    my ($app) = @_;
    my $perms = $app->{perms};
    $perms ? $perms->can_edit_templates : $app->user->is_superuser;
}

sub rebuild_blogs {
    my $plugin = shift;
    my($app) = @_;
    my $q = $app->{query};
    my @blogs;
    my %param;
    for my $blog_id ($q->param('id')) {
        push (@blogs, $blog_id);
    }
    my $data = [];
    my $i = 1;
    for my $blog (@blogs) {
        my $row = { id => $blog};
        push @$data, $row;
    }
    $param{loop} = $data;
    my $offset = $q->param('offset') || '0';
    my $total = $q->param('total') || scalar @blogs;
    my $done = 0;
    $done++ if $offset+1 >= $total;
    my $author = $app->{author};
    my @perms = MT::Permission->load({ author_id => $author->id });
    my %perms = map { $_->blog_id => $_ } @perms;
    
    my $blog;
    $blog = MT::Blog->load($blogs[$offset]);
    my $blog_id = $blog->id;
    $app->rebuild( BlogID => $blog_id );
    $offset++;
    if ($offset < $total){
        my $next_blog = MT::Blog->load($blogs[$offset]);
        $param{to_rebuild} = $next_blog->name if $next_blog;
    }
    $param{offset} = $offset;
    $param{just_rebuilt} = $blog->name;
    $param{rebuild_mode} = 'rebuild_blogs';
    $param{what} = 'blogs';    
    unless ($done) {
        $param{total} = $total;
        $param{multiple} = 1;
        $app->build_page($plugin->load_tmpl('rebuilding_what.tmpl'), \%param);
        } else {
        $app->build_page($plugin->load_tmpl('rebuilt_what.tmpl'), \%param);
    }
}

sub rebuild_templates {
    my $plugin = shift;
    my($app) = @_;
    my $q = $app->{query};
    my @templates;
    my %param;
    for my $template_id ($q->param('id')) {
        push (@templates, $template_id);
    }
    my $data = [];
    my $i = 1;
    for my $template (@templates) {
        my $row = { id => $template};
        push @$data, $row;
    }
    $param{loop} = $data;
    my $offset = $q->param('offset') || '0';
    my $total = $q->param('total') || scalar @templates;
    my $done = 0;
    $done++ if $offset+1 >= $total;
    require MT::Template;
    require MT::Permission;
    my $author = $app->{author};
    my @perms = MT::Permission->load({ author_id => $author->id });
    
    
    my $template = MT::Template->load($templates[$offset]);
    my $template_id = $template->id;
    $app->rebuild_indexes( BlogID => $template->blog_id, Template => $template, Force => 1 );
    $offset++;
    if ($offset < $total){
        my $next_template = MT::Template->load($templates[$offset]);
        $param{to_rebuild} = 'template \''.$next_template->name.'\'' if $next_template;
    }
    $param{offset} = $offset;
    $param{just_rebuilt} = 'Template \''.$template->name.'\'';
    $param{rebuild_mode} = 'rebuild_templates';
    $param{blog_id} = $template->blog_id;
    unless ($done) {
        $param{total} = $total;
        $param{multiple} = 1;
        $app->build_page($plugin->load_tmpl('rebuilding_what.tmpl'), \%param);
        } else {
        	$param{what} = 'templates';
        $app->build_page($plugin->load_tmpl('rebuilt_what.tmpl'), \%param);
    }
}

sub rebuild_entries {
    my $plugin = shift;
    my($app) = @_;
    my $q = $app->{query};
    my $type = $q->param('_type');
    my @objs;
    my %param;
    for my $obj_id ($q->param('id')) {
        push (@objs, $obj_id);
    }
    my $data = [];
    my $i = 1;
    for my $obj (@objs) {
        my $row = { id => $obj};
        push @$data, $row;
    }
    $param{loop} = $data;
    my $offset = $q->param('offset') || '0';
    my $total = $q->param('total') || scalar @objs;
    my $done = 0;
    $done++ if $offset+1 >= $total;
    my $author = $app->{author};
    my @perms = MT::Permission->load({ author_id => $author->id });
    my $class = $app->_load_driver_for($type) or return;
    
    my $obj = $class->load($objs[$offset]);
    my $obj_id = $obj->id;
    my $entry = MT::Entry->load($obj->entry_id);
    $app->rebuild_entry( Entry => $entry, BuildDependencies => 1 );
    $offset++;
    if ($offset < $total){
        my $next_obj = $class->load($objs[$offset]);
        $param{to_rebuild} = $type.' #'.$next_obj->id if $next_obj;
    }
    $param{offset} = $offset;
    $param{just_rebuilt} = $type.' #'.$obj->id;
    $param{rebuild_mode} = 'rebuild_entries';
    $param{blog_id} = $obj->blog_id;
    $param{what} = $type;    
    unless ($done) {
        $param{total} = $total;
        $param{multiple} = 1;
        $app->build_page($plugin->load_tmpl('rebuilding_what.tmpl'), \%param);
        } else {
        	$param{what} = $type.'s';
        $app->build_page($plugin->load_tmpl('rebuilt_what.tmpl'), \%param);
    }
}
