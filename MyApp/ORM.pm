package MyApp::ORM;
use strict;
use warnings;
use base qw(Class::Accessor::Fast Class::Data::Inheritable);
use Data::Dumper;
__PACKAGE__->mk_accessors(qw(config));
__PACKAGE__->mk_classdata('columns');
__PACKAGE__->mk_classdata('belongs_to');
__PACKAGE__->mk_classdata('tablename');


sub _get_tablename {
    my $self = shift;
    my $model_name = ( shift || MyApp::get_package_basename(ref $self) );
    
    return $self->pluralize(lc $model_name);
}

sub pluralize {
    my($self, $word) = @_;
    my %dictionary = (
        entry => 'entries',
        category => 'categories',
        );

    return $dictionary{$word} if defined $dictionary{$word};
}


sub new {
    my ($class, $config) = @_;
    my $self =  bless { config => $config }, $class;

    $self->_init();
    $self->tablename( $self->_get_tablename );
    return $self;
}


sub get_dbinfo {
    my $self = shift;
    $self->{config}->{dbinfo};
}


sub dbh {
    my $self = shift;
    if(@_){
        $self->{dbh} = $_[0];
    }else{
        $self->{dbh};
    }
}


sub get_all {
    my $self = shift;

    $self->get_connection;

    my $main_table = $self->_get_tablename;
    my $field_list = " $main_table.* ";
    my $join_clause = "";

    if( $self->belongs_to ){
        my @parent_models = @{ $self->belongs_to  };

        my $parent_table = $self->_get_tablename($parent_models[0]);
        if( $parent_table ){ $field_list .= ", $parent_table.id as ".$parent_table."_id , $parent_table.name "; }

        $join_clause = sprintf("join %s  ON %s.id = %s.%s_id ", $parent_table, $parent_table, $main_table, $parent_table);


    }


    my $sql = " 
       select 
               $field_list
       from    $main_table
       $join_clause
       order by $main_table.created_on desc
       ";


    my $sth = $self->dbh->prepare($sql);
    eval {
        $sth->execute;
    };
    if($@){
        die("$sql\n\n$@");
    }
    my $records = $sth->fetchall_arrayref(+{});

    $self->_filter($records, 'body', 'add_link');
    $self->_filter($records, 'body', 'nl2br');

    $sth->finish;
    #die( Dumper $records);
    return $records;
}

sub _filter {
    my $self = shift;
    my $lines = shift;
    my $colname = shift;
    my $filter_name = shift;
    my $method_name = '_filter_' . $filter_name;

    for my $line (@$lines) {
        $line->{$colname} = $self->$method_name($line->{$colname}) if( defined $line->{$colname} );
    }

}

sub _filter_add_link {
    my($self, $str) = @_;
    $str =~ s|(http://[^\s]+)|<a href="$1">$1</a>|g ;
    return $str;
}


sub _filter_nl2br {
    my($self, $str) = @_;
    $str =~ s|\n|<br/>|g ;
    return $str;
}


sub get_connection {
    my $self = shift;

    if($self->dbh ){
        return $self->dbh;
    }else{
        # connect DB

        my $db_opt = {
#           AutoCommit=>0,
            RaiseError=>1,
            mysql_enable_utf8=>1,
            on_connect_do => [
                "SET NAMES 'utf8'",
                "SET CHARACTER SET 'utf8'"
                ],
        };
        

        my $dbinfo = $self->get_dbinfo;
        my $dbh = DBI->connect($dbinfo->{dsn}, $dbinfo->{user}, $dbinfo->{pass}, $db_opt) or die "cannot connect DB $!";
        $self->dbh($dbh);
        return $dbh;
    }
}

sub save {
    my($self, %record) = @_;
    if( defined $record{id} && $record{id} ){
        $self->update(%record);
    }else{
        $self->insert(%record);
    }
}

sub insert {
    my($self, %record) = @_;

    $self->get_connection;
    my @columns = @{ $self->columns };
    
    my $colnames = join ', ' , @columns;
    my $values = join ', ', (    map { "'".$record{$_}."'" } @columns ); 
    my $sql = " insert into ".$self->tablename
             ." ( $colnames ) "
             ." values ( $values ) ";
    warn $sql;
    $self->dbh->do($sql);
}



sub update {
    my($self, %record) = @_;

    $self->get_connection;
    my @columns = @{ $self->columns };
    my $colnames = join ', ' , @columns;

    my $pairs = join ', ', (    map { " $_ = '".$record{$_}."'" } @columns ); 
    my $sql = " update  ".$self->tablename
             ." set ". $pairs
             ." where id = ".$record{id};
    warn $sql;
    $self->dbh->do($sql);

}




sub find_by_id {
    my ($self, $id) = @_;

    $self->get_connection;
    
    my $sql = " select * from ".$self->tablename." where id = ".$id;

    my $sth = $self->dbh->prepare($sql);
    $sth->execute;
    my $record = $sth->fetchrow_hashref;


    $sth->finish;
    return $record;
}


sub delete {
    my($self, $id) = @_;

    $self->get_connection;

    my $sql = " delete from  ".$self->tablename
             ." where id = ".$id;
    warn $sql;
    $self->dbh->do($sql);

}

# to be overridden
sub _init {

}

package MyApp::ORM::Entry;
use strict;
use warnings;
use base "MyApp::ORM";
__PACKAGE__->columns([ qw( title body categories_id ) ]);
__PACKAGE__->belongs_to([qw( Category )]);



package MyApp::ORM::Category;
use strict;
use warnings;
use base "MyApp::ORM";
__PACKAGE__->columns([qw( name )]);



1;
