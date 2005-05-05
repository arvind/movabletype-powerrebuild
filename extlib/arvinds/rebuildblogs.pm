package arvinds::rebuildblogs;
use base MT::App;
use strict;
use MT::App::CMS;
use vars qw(@ISA $VERSION);
@ISA = qw(MT::App::CMS);
$VERSION = '0.1';
sub uri {
    $_[0]->path . MT::ConfigMgr->instance->AdminScript;
}
sub init {
    my $app = shift;
    $app->SUPER::init (@_) or return;
    $app->add_methods (
    'list_blogs' => \&list_blogs,
    #      'start_rebuild' => \&start_rebuild,
    'rebuild_multiple' => \&rebuild_multiple,
    'rebuild_all' => \&rebuild_all);
    $app->{default_mode} = 'list_blogs';
    $app->{requires_login} = 1 ;
    $app->{user_class} = 'MT::Author';
    $app->{is_admin} = 1;
    $app;
}

sub list_blogs {
    my $app = shift;
    require MT::Blog;
    require MT::Permission;
    my $author = $app->{author};
    my @perms = MT::Permission->load({ author_id => $author->id });
    my %perms = map { $_->blog_id => $_ } @perms;
    my @blogs = MT::Blog->load;
    my $data = [];
    my %param;
    my $i = 1;
    for my $blog (@blogs) {
        my $blog_id = $blog->id;
        my $perms = $perms{ $blog_id };
        next unless $perms && $perms->role_mask;
        $param{can_edit_authors} = 1 if $perms->can_edit_authors;
        my $row = { id => $blog->id, name => MT::Util::encode_html($blog->name),
            description => $blog->description,
            site_url => $blog->site_url
        };
        my $iter = MT::Permission->load_iter({ blog_id => $blog_id });
        $row->{can_edit_templates} = $perms->can_edit_templates;
        push @$data, $row;
    }
    $param{blog_loop} = $data;
    $app->build_page('rebuild_blogs.tmpl', \%param);
}

#sub start_rebuild {
    #        my $app = shift;
    #        my %param;
    #        my $offset = 0;
    #        $param{offset} = $offset;
    #        my $total = MT::Blog->count;
    #        $param{total} = $total;
    #        $app->build_page('rebuilding-blogs.tmpl', \%param);
#    }
sub rebuild_all {
    my $app = shift;
    my $q = $app->{query};
    my $offset = $q->param('offset') || '0';
    my $total = $q->param('total') || MT::Blog->count;
    my %param;
    my $done = 0;
    $done++ if $offset+1 >= $total;
    require MT::Blog;
    require MT::Permission;
    my $author = $app->{author};
    my @perms = MT::Permission->load({ author_id => $author->id });
    my %perms = map { $_->blog_id => $_ } @perms;
    my @blogs = MT::Blog->load;
    my $blog;
    $blog = $blogs[$offset];
    my $blog_id = $blog->id;
    $app->rebuild( BlogID => $blog_id );
    $offset++;
    if ($offset < $total){
        $param{next_blog} = $blogs[$offset]->name;
    }
    $param{offset} = $offset;
    $param{blog_title} = $blog->name;
    unless ($done) {
        $param{total} = $total;
        $param{all} = 1;
        $app->build_page('rebuilding_blogs.tmpl', \%param);
        } else {
        $app->build_page('rebuilt_blogs.tmpl', \%param);
    }
}

sub rebuild_multiple {
    my $app = shift;
    my $q = $app->{query};
    my @blogs;
    my %param;
    for my $blog_id ($q->param('blog_id')) {
        push (@blogs, $blog_id);
    }
    my $data = [];
    my $i = 1;
    for my $blog (@blogs) {
        my $row = { id => $blog};
        push @$data, $row;
    }
    $param{blog_loop} = $data;
    my $offset = $q->param('offset') || '0';
    my $total = $q->param('total') || scalar @blogs;
    my $done = 0;
    $done++ if $offset+1 >= $total;
    require MT::Blog;
    require MT::Permission;
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
        $param{next_blog} = $next_blog->name if $next_blog;
    }
    $param{offset} = $offset;
    $param{blog_title} = $blog->name;
    unless ($done) {
        $param{total} = $total;
        $param{multiple} = 1;
        $app->build_page('rebuilding-blogs.tmpl', \%param);
        } else {
        $app->build_page('rebuilt-blogs.tmpl', \%param);
    }
}