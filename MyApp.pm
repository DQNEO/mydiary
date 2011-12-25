package MyApp;
use strict;
use warnings;
use CGI;
use CGI::Carp "fatalsToBrowser";
use DBI;
use HTML::Template;
use MyApp::Action;
use MyApp::ORM;
#use Data::Dumper;

sub run {

    # config
    my $config = {

        dbinfo => {
            user => 'userhoge',
            pass => 'fuga',
            dsn => 'dbi:mysql:mydiary',
        },
        
        default_action => 'Entry_List',
        http_header_charset => 'utf-8',
        template_dir => 'tmpl',

    };

    my $q = CGI->new;
    my $mode = $q->param('mode');
    if(! $mode ){
        $mode = $config->{default_action};
    }
    my $action_class = "MyApp::Action::".$mode;
    my $default_action_class = "MyApp::Action::".$config->{default_action};
    my $action;

    eval {
        $action = $action_class->new($config, 0, $q);
    };

    if($@ =~ /perhaps you forgot to load/){
        $action = $default_action_class->new($config, 0, $q);
    }elsif($@){
        die($@);        
    }

    #if($@){
        #die "action class $action_class is NOT FOUND ";
    #}

    $action->run;
    
    exit;
}

sub get_package_basename {
    my $_package = shift;
    my ($name) = ( $_package  =~  /::([^:]+)$/ );
    return $name;
}

1;
