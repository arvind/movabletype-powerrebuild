# PowerRebuild - A plugin for Movable Type.
# Copyright (c) 2005-2007, Arvind Satyanarayan.

package MT::Plugin::PowerRebuild;

use 5.006;    # requires Perl 5.6.x
use MT 4.0;   # requires MT 4.0 or later

use base 'MT::Plugin';
our $VERSION = '1.11';

my $plugin;
MT->add_plugin($plugin = __PACKAGE__->new({
	name            => 'PowerRebuild',
	version         => $VERSION,
	description     => '<__trans phrase="Allows you to mass publish weblogs and templates from the respective listing screens">',
	author_name     => 'Arvind Satyanarayan',
	author_link     => 'http://www.movalog.com/',
	plugin_link     => 'http://plugins.movalog.com/powerrebuild/',
	doc_link        => 'http://plugins.movalog.com/powerrebuild/',
}));

# Allows external access to plugin object: MT::Plugin::PowerRebuild->instance
sub instance { $plugin; }

sub init_registry {
	my $plugin = shift;
	$plugin->registry({
		applications => {
			cms => {
				list_actions => {
					template => {
						'powerrebuild_publish_tmpls' => {
							label => "Publish Template(s)",
                            code => sub { $plugin->rebuild_objects(@_) },
                            permissions => 'can_edit_templates',
						}
					},
					blog => {
						'powerrebuild_publish_blogs' => {
							label => "Publish Blog(s)",
							code => sub { $plugin->rebuild_objects(@_) }
						}
					}
				},
				methods => {
					'powerrebuild_publish' => sub { $plugin->rebuild_objects(@_); }
				}
			}
		},
		callbacks => {
			'MT::App::CMS::template_source.list_template' => sub { $plugin->powerrebuild_return_arg(@_); },
			'MT::App::CMS::template_source.list_blog' => sub { $plugin->powerrebuild_return_arg(@_); }
		}
	});
}

sub rebuild_objects {
	my $plugin = shift;
	my ($app) = @_;
	my $q = $app->param;
	
	my $type = $q->param('_type');
	my $class = $app->model($type);
	my (@objs);
	
	# First build a loop of IDs of all the objects that need be republished
	foreach my $id ($q->param('id')) {
		push @objs, { id => $id };
	}
	
	# Next calculate where in the loop we are (or are we there yet?)
	my $offset = $q->param('offset') || '0';
    my $total = $q->param('total') || scalar @objs;
    my $done = 0;
    $done++ if $offset+1 >= $total;
	
	# Load and rebuild the object
	my $obj = $class->load($objs[$offset]->{id});
	my $blog_id = ($type eq 'blog') ? $obj->id : $obj->blog_id;
	my %terms = (
		BlogID => $blog_id,
		($type eq 'template') ? ( Template => $obj, Force => 1 ) : ()
	);
	my $rebuild_meth = ($type eq 'template') ? 'rebuild_indexes' : 'rebuild';
	$app->$rebuild_meth(%terms); 
	$offset++;
	
	# Lets populate $param for our build_page routine
	my $param = {
		type => $type,
		offset => $offset,
		total => $total,
		obj_loop => \@objs,
		type => $type,
		just_rebuilt => $obj->name,
		blog_id => $blog_id,
		return_args => $q->param('return_args')
	};

	# Now that we've increment offset, check if there's still more to republish
	# If yes, load the details of the next item so we can inform the user
	if($offset < $total) {
		my $next = $class->load($objs[$offset]->{id});
		$param->{to_rebuild} = $next->name;
	}
	
	if($done) {
		# $app->add_return_arg( powerrebuild_published => 1);
		$app->call_return( powerrebuild_published => 1 );
	} else {
		return $app->build_page($plugin->load_tmpl('rebuilding.tmpl'), $param);	
	}	
}

# A transformer callback that adds a success message to the listing screens
sub powerrebuild_return_arg {
	my $plugin = shift;
	my ($cb, $app, $tmpl) = @_;
	
	return unless $app->param('powerrebuild_published');
	
	my $old = q{<(\$)?mt:include name="include/header.tmpl"(\$)?>};
	my $new = <<POWERREBUILD;
	
<mt:setvarblock name="content_header" append="1">	
	<mtapp:statusmsg
	 id="powerrebuild"
	 class="success">
		<__trans phrase="Your [_1]s have been successfully published" params="<mt:var name="object_type">">
	</mtapp:statusmsg>
</mt:setvarblock>
POWERREBUILD
	$$tmpl =~ s/($old)/$new\n$1/;
}

1;