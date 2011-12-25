package MyApp::Action;
use strict;
use warnings;
use Encode;
use utf8;
use Data::Dumper;
use base qw(Class::Accessor::Fast Class::Data::Inheritable);
__PACKAGE__->mk_accessors(qw(q tpl config c));
__PACKAGE__->mk_classdata('main_model');

sub new {
    my($class, $config, $c, $q) = @_;
    my $self = bless { 
        config => $config,
        c => $c,
        'q' => $q,
    }, $class;

    $self->set_template;

    return $self;
}

# get action name by class name
sub action_name {
    my $self = shift;
    return MyApp::get_package_basename( ref($self) );
}

# get template filename by action name
sub tpl_name {
    my $self = shift;
    $self->action_name . '.tmpl';
}

# set template file
sub set_template {
    my $self = shift;
    
    #my $tpl_filename = $self->config->{template_dir}.'/'.$self->tpl_name;
    my $tpl_filename = '/home/userdqn/perl/mydiary/tmpl/' .$self->tpl_name;

    # catch error if template file is not found
    unless(-f $tpl_filename){
        die("Template File is NOT found. '". $tpl_filename ."'");
    }

    my $filter = sub {
        my $ref = shift;
        $$ref =~ s/\[%/%/g;
        $$ref =~ s/%\]/%/g;
        $$ref = decode('utf-8', $$ref);
    };

    # vanguard option requires die_on_bad_params to be 0
    my $tpl = HTML::Template->new( 
        path => ['/home/userdqn/perl/mydiary/tmpl'],
        filename => $tpl_filename,
        vanguard_compatibility_mode => 1,
        die_on_bad_params => 0,
        associate => $self->q,
        default_escape => 'HTML',
        filter => $filter,
        );

    $self->tpl($tpl);

    $self->set_default_values();

}

# set default values to template
sub set_default_values {
    my $self = shift;
    $self->tpl->param( 'template_name', $self->tpl_name );
}

# execute action
sub run {
    my $self = shift;
    $self->preproccess;
    $self->proccess;
    $self->postproccess;
    $self->output;
}

# redirect by HTTTP header and exit
sub redirect {
    my $self = shift;
    my $url = shift;
    print "Location: " . $url . "\n\n";
    exit;
}

# print HTML
sub output {
    my $self = shift;
    my $charset = $self->config->{http_header_charset};
    print $self->q->header( -charset => $charset);
    print encode('utf-8', $self->tpl->output);
}

# pass data to template
sub set_param {
    my($self, $name, $data) = @_;
    $self->tpl->param( $name => $data );
}

sub set_hash {
    my($self, %hash) = @_;
    $self->tpl->param( %hash );
}


sub preproccess {
    my $self = shift;
    my $msg = $self->q->param('msg');
    
    my %message_table = (
        saved => '保存しました。',
        deleted => '削除しました。',
        );

    $self->set_param( 'message' => $message_table{$msg} ) if defined $message_table{$msg} ;

}

# just to be orverrided
sub proccess {

}

sub postproccess {

}

sub set_list {
    my $self = shift;
    my $list_name = ( shift || 'list' );
    my $model_name = shift;
    my $main_orm = $self->get_orm($model_name);
    my $list = $main_orm->get_all();
    
    $self->set_param($list_name, $list);

}

sub get_orm {
    my ($self, $model_name) = @_;
    unless( defined $model_name ){
        $model_name =$self->main_model;
    }
    my $pkg_name = "MyApp::ORM::".$model_name;
    $pkg_name->new( $self->config );
}

##### Typical Action ######
package MyApp::Action::List;
use strict;
use warnings;
use base "MyApp::Action";

sub proccess {
    my $self = shift;
    $self->set_list;
}

package MyApp::Action::Display;
use strict;
use warnings;
use base "MyApp::Action";

sub proccess {
    my $self = shift;
    my $id = $self->q->param('id');

    my $main_orm = $self->get_orm;
    my $record = $main_orm->find_by_id($id);

    $self->set_hash(%$record);
}


package MyApp::Action::Edit;
use strict;
use warnings;
use base "MyApp::Action";

sub proccess {
    my $self = shift;

    my $id = $self->q->param('id');

    my $main_orm = $self->get_orm;
    my $record = $main_orm->find_by_id($id);
    
    $self->set_hash(%$record);
}

package MyApp::Action::Save;
use strict;
use warnings;
use base "MyApp::Action";

sub proccess {
    my $self = shift;

    my %hash = $self->q->Vars;
    my $main_orm = $self->get_orm;
    my $ret = $main_orm->save(%hash);

    unless($ret){
        die "save failed!";
    }

    $self->set_param('ret', $ret);
}

sub postproccess {
    my $self = shift;
    $self->redirect('./?msg=saved');
}


package MyApp::Action::Delete;
use strict;
use warnings;
use base "MyApp::Action";

sub proccess {
    my $self = shift;
    my $id = $self->q->param('id');

    my $main_orm = $self->get_orm;
    my $ret = $main_orm->delete($id);
    
    $self->set_param('ret', $ret);
}

sub postproccess {
    my $self = shift;
    $self->redirect('./?msg=deleted');
}

##### Concrete Action ######

package MyApp::Action::Entry_List;
use strict;
use warnings;
use base "MyApp::Action::List";
__PACKAGE__->main_model('Entry');

sub proccess {
    my $self = shift;
    $self->set_list;
}

package MyApp::Action::Category_List;
use strict;
use warnings;
use base "MyApp::Action::List";
__PACKAGE__->main_model('Category');

package MyApp::Action::Entry_Create;
use strict;
use warnings;
use base "MyApp::Action";
__PACKAGE__->main_model('Entry');

sub proccess {
    my $self = shift;
    $self->set_list('categories', 'Category');
}

package MyApp::Action::Category_Create;
use strict;
use warnings;
use base "MyApp::Action";
__PACKAGE__->main_model('Category');

package MyApp::Action::Entry_Edit;
use strict;
use warnings;
use base "MyApp::Action::Edit";
__PACKAGE__->main_model('Entry');

package MyApp::Action::Category_Edit;
use strict;
use warnings;
use base "MyApp::Action::Edit";
__PACKAGE__->main_model('Category');


package MyApp::Action::Entry_Display;
use strict;
use warnings;
use base "MyApp::Action::Display";
__PACKAGE__->main_model('Entry');



package MyApp::Action::Entry_Confirm;
use strict;
use warnings;
use base "MyApp::Action";
__PACKAGE__->main_model('Entry');


package MyApp::Action::Category_Confirm;
use strict;
use warnings;
use base "MyApp::Action";
__PACKAGE__->main_model('Category');


package MyApp::Action::Entry_Save;
use strict;
use warnings;
use base "MyApp::Action::Save";
__PACKAGE__->main_model('Entry');


package MyApp::Action::Category_Save;
use strict;
use warnings;
use base "MyApp::Action::Save";
__PACKAGE__->main_model('Category');

package MyApp::Action::Entry_Delete;
use strict;
use warnings;
use base "MyApp::Action::Delete";
__PACKAGE__->main_model('Entry');

package MyApp::Action::Category_Delete;
use strict;
use warnings;
use base "MyApp::Action::Delete";
__PACKAGE__->main_model('Category');


1;
