#!/usr/bin/perl

use strict;
use warnings;
use DBI;
use CGI::Carp "fatalsToBrowser";
use Data::Dumper;

my $dsn = '';
my $user = 'userhoge';
my $pass = 'fuga';
my $dsn = 'dbi:mysql:mydiary';

my $dbh = DBI->connect($dsn, $user, $pass) or die "cannot connect DB $!";;

my $sql = " select * from entries order by created_on desc";
my $sth = $dbh->prepare($sql);
$sth->execute;

my $data = $sth->fetchall_arrayref(+{});
my $dump = Dumper $data;


my $html = <<EOF;
Content-Type:text/html

<title>What a wonderful world...</title>
<h1>My Diary</h1>
<pre>
$dump
</pre>

EOF


print $html;
