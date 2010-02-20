#!/usr/bin/perl
#
# $Id$
#
# Copyright 2006-2010 Brad Lanam Walnut Creek, CA USA
#

# HP-UX doesn't have these installed.
# use strict;
# use Config;
require 5.005;

my $CONFH;
my $LOG = "mkconfig.log";
my $TMP = "_tmp_mkconfig";
my $CACHEFILE = "mkconfig.cache";
my $REQLIB = "reqlibs.txt";

my $precc = <<'_HERE_';
#if defined(__STDC__) || defined(__cplusplus) || defined(c_plusplus)
# define _ARG_(x) x
# define _VOID_ void
#else
# define _ARG_(x) ()
# define _VOID_ char
#endif
#if defined(__cplusplus)
# define _BEGIN_EXTERNS_ extern "C" {
# define _END_EXTERNS_ }
#else
# define _BEGIN_EXTERNS_
# define _END_EXTERNS_
#endif
_HERE_

sub
exitmkconfig
{
    my $rc = shift;
    exit 1;
}

sub
printlabel
{
    my ($name, $label) = @_;
    print LOGFH "## [$name] $label ... \n";
    print STDOUT "$label ... ";
}

sub
printyesno_val
{
    my ($name, $val, $tag) = @_;

    if ($val ne "0")
    {
        print LOGFH "## [$name] $val $tag\n";
        print STDOUT "$val $tag\n";
    }
    else
    {
        print LOGFH "## [$name] no $tag\n";
        print STDOUT "no $tag\n";
    }
}

sub
printyesno
{
    my ($name, $val, $tag) = @_;

    if ($val ne "0")
    {
        $val = "yes";
    }
    printyesno_val $name, $val, $tag;
}

sub
savecache
{
    my ($r_clist, $r_config) = @_;

    open (MKCC, ">$CACHEFILE");
    foreach my $val (sort @{$r_clist->{'list'}})
    {
      print MKCC "di_cfg_${val}='" . $r_config->{$val} . "'\n";
    }
    my $vals = join (' ', @{$r_clist->{'list'}});
    print MKCC "di_cfg_vars=' ${vals}'\n";
    close (MKCC);
}

sub
checkcache_val
{
  my ($name, $r_config) = @_;

  my $val = $r_config->{$name};
  my $rc = 1;
  if (defined ($r_config->{$name}) && $val ne "" )
  {
    printyesno_val $name, $val, " (cached)";
    $rc = 0;
  }
  return $rc;
}

sub
checkcache
{
  my ($name, $r_config) = @_;

  my $val = $r_config->{$name};
  my $rc = 1;
  if (defined ($r_config->{$name}) && $val ne "" )
  {
    printyesno $name, $val, " (cached)";
    $rc = 0;
  }
  return $rc;
}

sub
setlist
{
    my ($r_clist, $name) = @_;
    my $r_hash = $r_clist->{'hash'};
    if (! defined ($r_hash->{$name}))
    {
      push @{$r_clist->{'list'}}, $name;
      $r_hash->{$name} = 1;
    }
}

sub
print_headers
{
    my ($r_a, $r_clist, $r_config) = @_;
    my $txt;

    $txt = '';

    if ($r_a->{'incheaders'} eq 'all' ||
        $r_a->{'incheaders'} eq 'std')
    {
        # always include these four if present ...
        foreach my $val ('_hdr_stdio', '_hdr_stdlib', '_sys_types', '_sys_param')
        {
            if (defined ($r_config->{$val}) &&
                 $r_config->{$val} ne '0')
            {
                $txt .= "#include <" . $r_config->{$val} . ">\n";
            }
        }
    }

    if ($r_a->{'incheaders'} eq 'all')
    {
        foreach my $val (@{$r_clist->{'list'}})
        {
            if ($val !~ m#^(_hdr_|_sys_)#o)
            {
                next;
            }
            if ($val eq '_hdr_stdio' ||
                $val eq '_hdr_stdlib' ||
                $val eq '_sys_types' ||
                $val eq '_sys_param')
            {
                next;
            }
            if ($val eq '_hdr_malloc' &&
                $r_config->{'_include_malloc'} eq '0')
            {
                next;
            }
            if ($val eq '_hdr_strings' &&
                $r_config->{'_hdr_string'} ne '0' &&
                $r_config->{'_include_string'} eq '0')
            {
                next;
            }
            if ($val eq '_sys_time' &&
                $r_config->{'_hdr_time'} ne '0' &&
                $r_config->{'_include_time'} eq '0')
            {
                next;
            }
            if ($r_config->{$val} ne '0')
            {
                $txt .= "#include <" . $r_config->{$val} . ">\n";
            }
        }
        $txt .= "\n";
    }

    return $txt;
}

sub
check_run
{
    my ($name, $code, $r_val, $r_clist, $r_config, $r_a) = @_;

    my $rc = check_link ($name, $code, $r_clist, $r_config,
        { 'incheaders' => 'all', %$r_a, });
    print LOGFH "##  run test: link: $rc\n";
    $$r_val = 0;
    if ($rc == 0)
    {
        $rc = system ("./$name.exe > $name.out");
        if ($rc & 127) { exitmkconfig ($rc); }
        print LOGFH "##  run test: run: $rc\n";
        if ($rc == 0)
        {
            open (CRFH, "<$name.out");
            $$r_val = <CRFH>;
            chomp $$r_val;
            close CRFH;
        }
    }
    return $rc;
}

sub
check_link
{
    my ($name, $code, $r_clist, $r_config, $r_a) = @_;

    my $otherlibs = '';
    if (defined ($r_a->{'otherlibs'}))
    {
        $otherlibs = $r_a->{'otherlibs'};
    }

    open (CLFH, ">$name.c");
    print CLFH $precc;

    my $hdrs = print_headers ($r_a, $r_clist, $r_config);
    print CLFH $hdrs;
    print CLFH $code;
    close CLFH;

    my $rc = system ("cat $name.c >> $LOG");
    if ($rc & 127) { exitmkconfig ($rc); }

    my $dlibs = '';
    $rc = _check_link ($name, {} );
    if ($rc != 0)
    {
      if ($otherlibs ne '')
      {
        my @olibs = split (/\s+/, $otherlibs);
        my $oliblist = '';
        foreach my $olib (@olibs)
        {
          $oliblist = $oliblist . ' ' . $olib;
          $rc = _check_link ($name, { 'otherlibs' => $oliblist, } );
          if ($rc == 0)
          {
              my $r_hash = $r_config->{'reqlibs'};
              my @vals = split (/\s+/, $oliblist);
              $dlibs = '';
              foreach my $val (@vals)
              {
                  if ($val eq '') { next; }
                  $r_hash->{$val} = 1;
                  $dlibs .= $val . ' ';
              }
              last;
          }
        }
      }
    }

    $r_a->{'dlibs'} = $dlibs;

    return $rc;
}

sub
_check_link
{
    my ($name, $r_a) = @_;

    my $cmd = "$ENV{'CC'} $ENV{'CFLAGS'} ";
    if (defined ($r_a->{'cflags'}))
    {
        $cmd .= ' ' . $r_a->{'cflags'} . ' ';
    }
    $cmd .= "-o $name.exe $name.c";
    $cmd .= " $ENV{'LDFLAGS'} $ENV{'LIBS'}";
    if (defined ($r_a->{'otherlibs'}) && $r_a->{'otherlibs'} ne undef)
    {
        $cmd .= ' ' . $r_a->{'otherlibs'} . ' ';
    }
    print LOGFH "##  link test: $cmd\n";
    my $rc = system ("$cmd >> $LOG 2>&1");
    if ($rc & 127) { exitmkconfig ($rc); }
    print LOGFH "##      link test: $rc\n";
    if ($rc == 0)
    {
        if (! -x "$name.exe")  # not executable.
        {
            $rc = 1;
        }
    }
    return $rc;
}

sub
check_compile
{
    my ($name, $code, $r_clist, $r_config, $r_a) = @_;

    open (CCFH, ">$name.c");

    print CCFH $precc;

    my $hdrs = print_headers ($r_a, $r_clist, $r_config);
    print CCFH $hdrs;
    print CCFH $code;
    close CCFH;

    my $cmd = "$ENV{'CC'} $ENV{'CFLAGS'} -c $name.c";
    print LOGFH "##  compile test: $cmd\n";
    my $rc = system ("cat $name.c >> $LOG");
    if ($rc & 127) { exitmkconfig ($rc); }
    $rc = system ("$cmd >> $LOG 2>&1");
    if ($rc & 127) { exitmkconfig ($rc); }
    print LOGFH "##  compile test: $rc\n";
    return $rc;
}

sub
do_check_compile
{
    my ($name, $code, $inc, $r_clist, $r_config) = @_;

    my $rc = check_compile ($name, $code, $r_clist, $r_config,
        { 'incheaders' => $inc, });
    my $trc = 0;
    if ($rc == 0)
    {
        $trc = 1;
    }
    printyesno $name, $trc;
    setlist $r_clist, $name;
    $r_config->{$name} = $trc;
}

sub
check_header
{
    my ($name, $file, $r_clist, $r_config, $r_a) = @_;

    printlabel $name, "header: $file";
    if (checkcache ($name, $r_config) == 0)
    {
        return;
    }

    my $r_rh = $r_a->{'reqhdr'} || [];
    my $code = '';
    foreach my $reqhdr (@$r_rh)
    {
        $code .= <<"_HERE_";
#include <$reqhdr>
_HERE_
    }
    $code .= <<"_HERE_";
#include <${file}>
main () { exit (0); }
_HERE_
    my $rc = 1;
    $rc = check_compile ($name, $code, $r_clist, $r_config,
        { 'incheaders' => 'std', });
    my $val = 0;
    if ($rc == 0)
    {
        $val = $file;
    }
    printyesno $name, $val;
    setlist $r_clist, $name;
    $r_config->{$name} = $val;
}

sub
check_constant
{
    my ($name, $constant, $r_clist, $r_config, $r_a) = @_;

    printlabel $name, "constant: $constant";
    if (checkcache ($name, $r_config) == 0)
    {
        return;
    }

    my $r_rh = $r_a->{'reqhdr'} || [];
    my $code = '';
    foreach my $reqhdr (@$r_rh)
    {
        $code .= <<"_HERE_";
#include <$reqhdr>
_HERE_
    }
    $code .= <<"_HERE_";
main () { if (${constant} == 0) { 1; } exit (0); }
_HERE_
    do_check_compile ($name, $code, 'all', $r_clist, $r_config);
}

# if the keyword is reserved, the compile will fail.
sub
check_keyword
{
    my ($name, $keyword, $r_clist, $r_config) = @_;

    printlabel $name, "keyword: $keyword";
    if (checkcache ($name, $r_config) == 0)
    {
        return;
    }

    $r_config->{$name} = 0;
    my $code = <<"_HERE_";
main () { int ${keyword}; ${keyword} = 1; exit (0); }
_HERE_
    my $rc = check_compile ($name, $code, $r_clist, $r_config,
        { 'incheaders' => 'std', });
    setlist $r_clist, $name;
    if ($rc != 0)  # failure means it is reserved...
    {
        $r_config->{$name} = 1;
    }
    printyesno $name, $r_config->{$name};
}

sub
check_proto
{
    my ($name, $r_clist, $r_config) = @_;

    printlabel $name, "supported: prototypes";
    if (checkcache ($name, $r_config) == 0)
    {
        return;
    }

    my $code = <<"_HERE_";
_BEGIN_EXTERNS_
extern int foo (int, int);
_END_EXTERNS_
int bar () { int rc; rc = foo (1,1); return 0; }
_HERE_
    my $rc = check_compile ($name, $code, $r_clist, $r_config,
        { 'incheaders' => 'all', });
    setlist $r_clist, $name;
    $r_config->{$name} = 0;
    if ($rc == 0)
    {
        $r_config->{$name} = 1;
    }
    printyesno $name, $r_config->{$name};
}

sub
check_command
{
    my ($name, $cmd, $r_clist, $r_config) = @_;

    printlabel $name, "command: $cmd";
    if (checkcache ($name, $r_config) == 0)
    {
        return;
    }

    setlist $r_clist, $name;
    $r_config->{$name} = 0;
    foreach my $p (split /[;:]/o, $ENV{'PATH'})
    {
        if (-x "$p/$cmd")
        {
            $r_config->{$name} = "$p/$cmd";
            last;
        }
    }
    printyesno $name, $r_config->{$name};
}

# malloc.h conflicts w/string.h on some systems.
sub
check_include_malloc
{
    my ($name, $r_clist, $r_config) = @_;

    if (defined ($r_config->{'_hdr_malloc'}) &&
        $r_config->{'_hdr_malloc'} ne '0' &&
        defined ($r_config->{'_hdr_string'}) &&
        $r_config->{'_hdr_string'} ne '0')
    {
        printlabel $name, "header: include malloc.h";
        if (checkcache ($name, $r_config) == 0)
        {
            return;
        }

        my $code = <<"_HERE_";
main () { char *x; x = (char *) malloc (20); }
_HERE_
        do_check_compile ($name, $code, 'std', $r_clist, $r_config);
    } else {
        setlist $r_clist, $name;
        $r_config->{$name} = 0;
    }
}

sub
check_include_string
{
    my ($name, $r_clist, $r_config) = @_;

    if (defined ($r_config->{'_hdr_string'}) &&
        $r_config->{'_hdr_string'} ne '0' &&
        defined ($r_config->{'_hdr_strings'}) &&
        $r_config->{'_hdr_strings'} ne '0')
    {
        printlabel $name, "header: include both string.h & strings.h";
        if (checkcache ($name, $r_config) == 0)
        {
            return;
        }

        my $code = <<"_HERE_";
#include <string.h>
#include <strings.h>
main () { char *x; x = "xyz"; strcat (x, "abc"); }
_HERE_
        do_check_compile ($name, $code, 'std', $r_clist, $r_config);
    } else {
        setlist $r_clist, $name;
        $r_config->{$name} = 0;
    }
}

sub
check_include_time
{
    my ($name, $r_clist, $r_config) = @_;

    if (defined ($r_config->{'_hdr_time'}) &&
        $r_config->{'_hdr_time'} ne '0' &&
        defined ($r_config->{'_sys_time'}) &&
        $r_config->{'_sys_time'} ne '0')
    {
        printlabel $name, "header: include both time.h & sys/time.h";
        if (checkcache ($name, $r_config) == 0)
        {
            return;
        }

        my $code = <<"_HERE_";
#include <time.h>
#include <sys/time.h>
main () { struct tm x; }
_HERE_
        do_check_compile ($name, $code, 'std', $r_clist, $r_config);
    } else {
        setlist $r_clist, $name;
        $r_config->{$name} = 0;
    }
}

sub
check_npt
{
    my ($name, $proto, $r_clist, $r_config) = @_;

    printlabel $name, "need prototype: $proto";
    if (checkcache ($name, $r_config) == 0)
    {
        return;
    }

    my $code = <<"_HERE_";
_BEGIN_EXTERNS_
struct _TEST_struct { int _TEST_member; };
extern struct _TEST_struct* $proto _ARG_((struct _TEST_struct*));
_END_EXTERNS_
_HERE_
    do_check_compile ($name, $code, 'all', $r_clist, $r_config);
}

sub
check_type
{
    my ($name, $type, $r_clist, $r_config) = @_;

    printlabel $name, "type: $type";
    if (checkcache ($name, $r_config) == 0)
    {
        return;
    }

    my $code = <<"_HERE_";
struct xxx { $type mem; };
static struct xxx v;
struct xxx* f() { return &v; }
main () { struct xxx *tmp; tmp = f(); exit (0); }
_HERE_
    do_check_compile ($name, $code, 'all', $r_clist, $r_config);
}

sub
check_lib
{
    my ($name, $func, $r_clist, $r_config, $r_a) = @_;

    setlist $r_clist, $name;
    my $val = $r_a->{'otherlibs'} || '';

    if ($val ne '')
    {
        printlabel $name, "function: $func [$val]";
    }
    else
    {
        printlabel $name, "function: $func";
        if (checkcache ($name, $r_config) == 0)
        {
            return;
        }
    }

    $r_config->{$name} = 0;
    # unfortunately, this does not work if the function
    # is not declared.
    my $code = <<"_HERE_";
typedef int (*_TEST_fun_)();
static _TEST_fun_ i=(_TEST_fun_) $func;
main () {  i(); return (i==0); }
_HERE_

    my %a = (
         'incheaders' => 'all',
         'otherlibs' => $val,
         );
    my $rc = check_link ($name, $code, $r_clist, $r_config, \%a);
    my $tag = '';
    if ($rc == 0)
    {
      $r_config->{$name} = 1;
      if ($a{'dlibs'} ne '')
      {
          $tag = " with $a{'dlibs'}";
      }
    }
    printyesno $name, $r_config->{$name}, $tag;
}

sub
check_class
{
    my ($name, $class, $r_clist, $r_config, $r_a) = @_;

    setlist $r_clist, $name;
    my $val = $r_a->{'otherlibs'} || '';

    if ($val ne '')
    {
        printlabel $name, "class: $class [$val]";
    }
    else
    {
        printlabel $name, "class: $class";
        if (checkcache ($name, $r_config) == 0)
        {
            return;
        }
    }

    $r_config->{$name} = 0;
    my $code = <<"_HERE_";
main () { $class testclass; }
_HERE_

    my %a = (
         'incheaders' => 'all',
         'otherlibs' => $val,
         );
    my $rc = check_link ($name, $code, $r_clist, $r_config, \%a);
    my $tag = '';
    if ($rc == 0)
    {
      $r_config->{$name} = 1;
      if ($a{'dlibs'} ne '')
      {
          $tag = " with $a{'dlibs'}";
      }
    }
    printyesno $name, $r_config->{$name}, $tag;
}

sub
check_setmntent_args
{
    my ($name, $r_clist, $r_config) = @_;

    printlabel $name, "setmntent # arguments";
    if (checkcache ($name, $r_config) == 0)
    {
        return;
    }

    setlist $r_clist, $name;
    $r_config->{$name} = 0;

    if ($r_config->{'_lib_setmntent'} eq '0')
    {
        printyesno_val $name, $r_config->{$name};
        return;
    }
    my $code = <<"_HERE_";
main () { setmntent ("/etc/mnttab"); }
_HERE_
    my $rc = check_link ($name, $code, $r_clist, $r_config,
        { 'incheaders' => 'all', 'otherlibs' => undef, });
    if ($rc == 0)
    {
        $r_config->{$name} = 2;
        printyesno_val $name, $r_config->{$name};
        return;
    }

    $code = <<"_HERE_";
main () { setmntent ("/etc/mnttab", "r"); }
_HERE_
    $rc = check_link ($name, $code, $r_clist, $r_config,
        { 'incheaders' => 'all', 'otherlibs' => undef, });
    if ($rc == 0)
    {
        $r_config->{$name} = 3;
    }
    printyesno_val $name, $r_config->{$name};
}

sub
check_statfs_args
{
    my ($name, $r_clist, $r_config) = @_;

    printlabel $name, "statfs # arguments";
    if (checkcache ($name, $r_config) == 0)
    {
        return;
    }

    setlist $r_clist, $name;
    $r_config->{$name} = 0;

    if ($r_config->{'_lib_statfs'} eq '0')
    {
        printyesno_val $name, $r_config->{$name};
        return;
    }

    my $code = <<"_HERE_";
main () {
    struct statfs statBuf; char *name; name = "/";
    statfs (name, &statBuf);
}
_HERE_
    my $rc = check_link ($name, $code, $r_clist, $r_config,
        { 'incheaders' => 'all', 'otherlibs' => undef, });
    if ($rc == 0)
    {
        $r_config->{$name} = 2;
        printyesno_val $name, $r_config->{$name};
        return;
    }

    $code = <<"_HERE_";
main () {
    struct statfs statBuf; char *name; name = "/";
    statfs (name, &statBuf, sizeof (statBuf));
}
_HERE_
    $rc = check_link ($name, $code, $r_clist, $r_config,
        { 'incheaders' => 'all', 'otherlibs' => undef, });
    if ($rc == 0)
    {
        $r_config->{$name} = 3;
        printyesno_val $name, $r_config->{$name};
        return;
    }

    $code = <<"_HERE_";
main () {
    struct statfs statBuf; char *name; name = "/";
    statfs (name, &statBuf, sizeof (statBuf), 0);
}
_HERE_
    $rc = check_link ($name, $code, $r_clist, $r_config,
        { 'incheaders' => 'all', 'otherlibs' => undef, });
    if ($rc == 0)
    {
        $r_config->{$name} = 4;
    }
    printyesno_val $name, $r_config->{$name};
}

sub
check_size
{
    my ($name, $type, $r_clist, $r_config) = @_;

    printlabel $name, "sizeof: $type";
    if (checkcache ($name, $r_config) == 0)
    {
        return;
    }

    setlist $r_clist, $name;
    $r_config->{$name} = 0;
    my $code = <<"_HERE_";
main () {
	printf("%u\\n", sizeof($type));
    exit (0);
    }
_HERE_
    my $val = 0;
    my $rc = check_run ($name, $code, \$val, $r_clist, $r_config, {});
    if ($rc == 0)
    {
        $r_config->{$name} = $val;
    }
    printyesno_val $name, $r_config->{$name};
}

sub
check_member
{
    my ($name, $struct, $member, $r_clist, $r_config) = @_;

    printlabel $name, "exists: $struct.$member";
    if (checkcache ($name, $r_config) == 0)
    {
        return;
    }

    setlist $r_clist, $name;
    $r_config->{$name} = 0;
    my $code = <<"_HERE_";
main () { struct $struct s; int i; i = sizeof (s.$member); }
_HERE_
    my $rc = check_compile ($name, $code, $r_clist, $r_config,
            { 'incheaders' => 'all', });
    if ($rc == 0)
    {
        $r_config->{$name} = 1;
    }
    printyesno $name, $r_config->{$name};
}

sub
check_int_declare
{
    my ($name, $function, $r_clist, $r_config) = @_;

    printlabel $name, "declared: $function";
    if (checkcache ($name, $r_config) == 0)
    {
        return;
    }

    setlist $r_clist, $name;
    $r_config->{$name} = 0;
    my $code = <<"_HERE_";
    main () { int x; x = $function; }
_HERE_
    my $rc = check_compile ($name, $code, $r_clist, $r_config,
            { 'incheaders' => 'all', });
    if ($rc == 0)
    {
        $r_config->{$name} = 1;
    }
    printyesno $name, $r_config->{$name};
}

sub
check_ptr_declare
{
    my ($name, $function, $r_clist, $r_config) = @_;

    printlabel $name, "declared: $function";
    if (checkcache ($name, $r_config) == 0)
    {
        return;
    }

    setlist $r_clist, $name;
    $r_config->{$name} = 0;
    my $code = <<"_HERE_";
main () { _VOID_ *x; x = $function; }
_HERE_
    my $rc = check_compile ($name, $code, $r_clist, $r_config,
            { 'incheaders' => 'all', });
    if ($rc == 0)
    {
        $r_config->{$name} = 1;
    }
    printyesno $name, $r_config->{$name};
}


sub
create_config
{
    my ($configfile) = @_;
    my (%clist, %config);

    $clist{'list'} = ();
    $clist{'hash'} = ();
    $config{'reqlibs'} = {};

    if (-f $CACHEFILE)
    {
      open (MKCC, "<$CACHEFILE");
      while (my $line = <MKCC>)
      {
        chomp $line;
        if ($line =~ m/^di_cfg_(.*)='(.*)'/o)
        {
          my $name = $1;
          my $val = $2;
          if ($name eq 'vars') {
            $val =~ s/^ *//;
            @{$clist{'list'}} = split (/ +/, $val);
            foreach my $var (@{$clist{'list'}})
            {
               $clist{'hash'}->{$var} = 1;
            }
          } else {
            $config{$name} = $val;
          }
        }
      }
      close (MKCC);
    }


    # FreeBSD has buggy headers, requires sys/param.h as a required include.
    # always check for these headers.
    my @headlist1 = (
        [ "_hdr_stdlib", "stdlib.h", ],
        [ "_hdr_stdio", "stdio.h", ],
        [ "_sys_types", "sys/types.h", ],
        [ "_sys_param", "sys/param.h", ],
        );

    foreach my $r_arr (@headlist1)
    {
        check_header ($$r_arr[0], $$r_arr[1], \%clist, \%config,
                { 'reqhdr' => [], });
    }
    check_keyword ('_key_void', 'void', \%clist, \%config);
    check_keyword ('_key_const', 'const', \%clist, \%config);
    check_proto ('_proto_stdc', \%clist, \%config);

    if (! open (DATAIN, "<../$configfile"))
    {
        print STDOUT "$configfile: $!\n";
        exit 1;
    }

    my $linenumber = 0;
    my $inheaders = 1;
    my $ininclude = 0;
    my $include = '';
    while (my $line = <DATAIN>)
    {
        chomp $line;
        ++$linenumber;

        if ($ininclude == 0 && ($line =~ /^#/o || $line eq ''))
        {
            next;
        }

        if ($ininclude == 1 && $line =~ m#^endinclude$#o)
        {
            print LOGFH "end include\n";
            $ininclude = 0;
            next;
        }
        elsif ($ininclude == 1)
        {
            $line =~ s,\\(.),$1,g;
            $include .= $line . "\n";
            next;
        }

        if ($inheaders && $line !~ m#^(hdr|sys)#o)
        {
            $inheaders = 0;
        }

        print LOGFH "#### ${linenumber}: ${line}\n";

        if ($line =~ m#^output\s+([^\s]+)#o)
        {
            print "output-file: $1\n";
            print LOGFH "config file: $1\n";
            $CONFH="../$1";
        }
        elsif ($line =~ m#^(source|standard)#o)
        {
            ;
        }
        elsif ($line =~ m#^setmntent_args#o)
        {
            check_setmntent_args ('_setmntent_args', \%clist, \%config);
        }
        elsif ($line =~ m#^statfs_args#o)
        {
            check_statfs_args ('_statfs_args', \%clist, \%config);
        }
        elsif ($line =~ m#^include_malloc#o)
        {
            check_include_malloc ('_include_malloc', \%clist, \%config);
        }
        elsif ($line =~ m#^include_string#o)
        {
            check_include_string ('_include_string', \%clist, \%config);
        }
        elsif ($line =~ m#^include_time#o)
        {
            check_include_time ('_include_time', \%clist, \%config);
        }
        elsif ($line =~ m#^include$#o)
        {
            print LOGFH "start include\n";
            $ininclude = 1;
        }
        elsif ($line =~ m#^(hdr|sys)\s+([^\s]+)\s*(.*)#o)
        {
            my $typ = $1;
            my $hdr = $2;
            my $reqhdr = $3;
            my $nm = "_${typ}_";
            # create the standard header name for config.h
            my @h = split (/\//, $hdr);
            $nm .= join ('_', @h);
            $nm =~ s,\.h$,,o;
            $nm =~ s,:,_,go;
            if ($typ eq 'sys')
            {
                $hdr = 'sys/' . $hdr;
            }
            $reqhdr =~ s/^\s*//o;
            $reqhdr =~ s/\s*$//o;
            my @oh = split (/\s+/, $reqhdr);
            if (! defined ($config{$nm}) ||
                $config{$nm} eq '0')
            {
                check_header ($nm, $hdr, \%clist, \%config,
                    { 'reqhdr' => \@oh, });
            }
        }
        elsif ($line =~ m#^const\s+([^\s]+)\s*(.*)#o)
        {
            my $tnm = $1;
            my $reqhdr = $2;
            my $nm = "_const_" . $tnm;
            $reqhdr =~ s/^\s*//o;
            $reqhdr =~ s/\s*$//o;
            my @oh = split (/\s+/, $reqhdr);
            if (! defined ($config{$nm}) ||
                $config{$nm} eq '0')
            {
                check_constant ($nm, $tnm, \%clist, \%config,
                    { 'reqhdr' => \@oh, });
            }
        }
        elsif ($line =~ m#^command\s+(.*)#o)
        {
            my $cmd = $1;
            my $nm = "_command_" . $cmd;
            if (! defined ($config{$nm}) ||
                $config{$nm} eq '0')
            {
                check_command ($nm, $cmd, \%clist, \%config);
            }
        }
        elsif ($line =~ m#^npt\s+([^\s]*)\s*(.*)#o)
        {
            my $func = $1;
            my $req = $2;
            my $nm = "_npt_" . $func;
            if (! defined ($req) || $config{$req} ne '0')
            {
                if (! defined ($config{$nm}) || $config{$nm} eq '0')
                {
                    check_npt ($nm, $func, \%clist, \%config);
                }
            } else {
              $config{$nm} = 0;
            }
        }
        elsif ($line =~ m#^key\s+(.*)#o)
        {
            my $tnm = $1;
            my $nm = "_key_" . $tnm;
            if (! defined ($config{$nm}) ||
                $config{$nm} eq '0')
            {
                check_keyword ($nm, $tnm, \%clist, \%config);
            }
        }
        elsif ($line =~ m#^class\s+([^\s]+)\s*(.*)?#o)
        {
            my $class = $1;
            my $libs = $2 || '';
            my $nm = "_class_" . $class;
            $nm =~ s,:,_,go;
            if (! defined ($config{$nm}) ||
                $config{$nm} eq '0')
            {
                check_class ($nm, $class, \%clist, \%config,
                       { 'otherlibs' => $libs, });
            }
        }
        elsif ($line =~ m#^typ\s+(.*)#o)
        {
            my $tnm = $1;
            my $nm = "_typ_" . $tnm;
            if (! defined ($config{$nm}) ||
                $config{$nm} eq '0')
            {
                check_type ($nm, $tnm, \%clist, \%config);
            }
        }
        elsif ($line =~ m#^lib\s+([^\s]+)\s*(.*)?#o)
        {
            my $func = $1;
            my $libs = $2 || '';
            my $nm = "_lib_" . $func;
            if (! defined ($config{$nm}) ||
                $config{$nm} eq '0')
            {
                check_lib ($nm, $func, \%clist, \%config,
                       { 'otherlibs' => $libs, });
            }
        }
        elsif ($line =~ m#^dcl\s+([^\s]*)\s+(.*)#o)
        {
            my $type = $1;
            my $var = $2;
            my $nm = "_dcl_" . $var;
            if (! defined ($config{$nm}) ||
                $config{$nm} eq '0')
            {
                if ($type eq 'int')
                {
                    check_int_declare ($nm, $var, \%clist, \%config);
                }
                elsif ($type eq 'ptr')
                {
                    check_ptr_declare ($nm, $var, \%clist, \%config);
                }
            }
        }
        elsif ($line =~ m#^member\s+(.*)\s+(.*)#o)
        {
            my $struct = $1;
            my $member = $2;
            my $nm = "_mem_" . $member . '_' . $struct;
            if (! defined ($config{$nm}) ||
                $config{$nm} eq '0')
            {
                check_member ($nm, $struct, $member, \%clist, \%config);
            }
        }
        elsif ($line =~ m#^size\s+(.*)#o)
        {
            my $typ = $1;
            $typ =~ s/\s*$//o;
            my $nm = "_siz_" . $typ;
            $nm =~ s, ,_,go;
            if (! defined ($config{$nm}) ||
                $config{$nm} eq '0')
            {
                check_size ($nm, $typ, \%clist, \%config);
            }
        }
        else
        {
            print LOGFH "unknown command: $line\n";
            print STDOUT "unknown command: $line\n";
        }
        savecache (\%clist, \%config);
    }

    open (CCOFH, ">$CONFH");
    print CCOFH <<'_HERE_';
#ifndef __INC_CONFIG_H
#define __INC_CONFIG_H 1

_HERE_

    foreach my $val (@{$clist{'list'}})
    {
      my $tval = 0;
      if ($config{$val} ne "0")
      {
          $tval = 1;
      }
      if ($val =~ m#^(_hdr|_sys|_command)#o)
      {
        print CCOFH "#define $val $tval\n";
      }
      else
      {
        print CCOFH "#define $val $config{$val}\n";
      }
    }

    # standard tail -- always needed; non specific
    print CCOFH <<'_HERE_';

#if ! _key_void || ! _proto_stdc
# define void int
#endif
#if ! _key_const || ! _proto_stdc
# define const
#endif

#ifndef _
# if _proto_stdc
#  define _(args) args
# else
#  define _(args) ()
# endif
#endif

_HERE_

    print CCOFH $include;

    print CCOFH <<'_HERE_';

#endif /* __INC_CONFIG_H */
_HERE_
    close CCOFH;

    open (RLIBFH, ">$REQLIB");

    my $r_hash = $config{'reqlibs'};
    print RLIBFH join (' ', keys %$r_hash) . "\n";
    close RLIBFH;

    savecache (\%clist, \%config);
}

sub
usage
{
  print STDOUT "Usage: $0 [-c <cache-file>] ";
  print STDOUT "       [-l <log-file>] [-t <tmp-dir>] [-r <reqlib-file>]";
  print STDOUT "       [-C] <config-file>";
  print STDOUT "  -C : clear cache-file";
  print STDOUT "<tmp-dir> must not exist.";
  print STDOUT "defaults:";
  print STDOUT "  <cache-file> : mkconfig.cache";
  print STDOUT "  <log-file>   : mkconfig.log";
  print STDOUT "  <tmp-dir>    : _tmp_mkconfig";
  print STDOUT "  <reqlib-file>: reqlibs.txt";
}

# main

my $clearcache = 0;
while ($#ARGV > 0)
{
  if ($ARGV[0] eq "-C")
  {
      shift @ARGV;
      $clearcache = 1;
  }
  if ($ARGV[0] eq "-c")
  {
      shift @ARGV;
      $CACHEFILE = $ARGV[0];
      shift @ARGV;
  }
  if ($ARGV[0] eq "-l")
  {
      shift @ARGV;
      $LOG = $ARGV[0];
      shift @ARGV;
  }
  if ($ARGV[0] eq "-t")
  {
      shift @ARGV;
      $TMP = $ARGV[0];
      shift @ARGV;
  }
  if ($ARGV[0] eq "-r")
  {
      shift @ARGV;
      $REQLIB = $ARGV[0];
      shift @ARGV;
  }
}

my $configfile = $ARGV[0];
if (! defined ($configfile) || ! -f $configfile)
{
  usage;
  exit 1;
}
if (-d $TMP && $TMP ne "_tmp_mkconfig")
{
  usage;
  exit 1;
}

$LOG = "../$LOG";
$REQLIB = "../$REQLIB";
$CACHEFILE = "../$CACHEFILE";

if (-d $TMP) { system ("rm -rf $TMP"); }
mkdir $TMP, 0777;
chdir $TMP;

if ($clearcache)
{
    unlink $CACHEFILE;
}

print STDOUT "$0 using $configfile\n";
unlink $LOG;
open (LOGFH, ">>$LOG");
$ENV{'CFLAGS'} = $ENV{'CFLAGS'} . ' ' . $ENV{'CINCLUDES'};
print LOGFH "CC: $ENV{'CC'}\n";
print LOGFH "CFLAGS: $ENV{'CFLAGS'}\n";
print LOGFH "LDFLAGS: $ENV{'LDFLAGS'}\n";
print LOGFH "LIBS: $ENV{'LIBS'}\n";

create_config $configfile;

close LOGFH;

chdir "..";
if (-d $TMP) { system ("rm -rf $TMP"); }
exit 0;
