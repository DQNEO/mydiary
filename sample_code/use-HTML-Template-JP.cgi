#!/usr/bin/perl

use strict;
use warnings;
use HTML::Template;
use CGI::Carp "fatalsToBrowser";

my $tmpl =<<EOF;
<html>
<h1>HTML::Template Sample</h1>
hello! <TMPL_VAR NAME=who><br/>
<tmpl_var name=msg>

<p>
<TMPL_LOOP NAME=EMPLOYEE_INFO>
  Name: <TMPL_VAR NAME=name> <br>
  Job:  <TMPL_VAR NAME=job> <p>
</TMPL_LOOP>
</p>

</html>

EOF

my $tpl = HTML::Template->new( scalarref => \$tmpl );
$tpl->param( who => "あ");
$tpl->param( msg => 'how r u ?');
$tpl->param(EMPLOYEE_INFO => [
		{ name => 'Sam', job => 'programmer' },
		{ name => 'Steve', job => 'soda jerk' },
	    ]
    );

print "Content-Type:text/html;charset=utf-8\n\n";
print $tpl->output;
