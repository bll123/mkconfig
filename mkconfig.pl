#!/usr/local/bin/perl
#
# $Id$
#
# Copyright 2005 Brad Lanam Walnut Creek, CA USA
#

use strict;
use Config;
require 5.005;

my $LOG = "../mkconfig.log";
my $TMP = "_tmp";

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
check_run
{
    my ($name, $code, $r_val, $r_clist, $r_config, $r_a) = @_;

    my $rc = check_link ($name, $code, $r_clist, $r_config,
        { 'includes' => 1, 'nounlink' => 1, 'tryextern' => 0, %$r_a, });
    print LOGFH "##  run test: $rc\n";
    $$r_val = 0;
    if ($rc == 0)
    {
        $rc = system ("./$name.exe > $name.out");
        if ($rc == 0)
        {
            open (CRFH, "<$name.out");
            $$r_val = <CRFH>;
            chomp $$r_val;
            close CRFH;
        }
    }
    unlink "$name.exe";
    unlink "$name.c";
    unlink "$name.out";
    unlink "$name.o";
    return $rc;
}

sub
check_link
{
    my ($name, $code, $r_clist, $r_config, $r_a) = @_;

    my $otherlibs = '';
    if (defined ($$r_a{'otherlibs'}))
    {
        $otherlibs = $$r_a{'otherlibs'};
    }

    open (CLFH, ">$name.c");

    print CLFH $precc;

    if ($$r_a{'includes'} == 1)
    {
        # always include these four if present ...
        foreach my $val ('_hdr_stdio', '_hdr_stdlib', '_sys_types', '_sys_param')
        {
            if (defined ($$r_config{$val}) &&
                 $$r_config{$val} ne '0')
            {
                print CLFH "#include <$$r_config{$val}>\n";
            }
        }

        foreach my $val (@$r_clist)
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
                $$r_config{'_include_malloc'} == 0)
            {
                next;
            }
            if ($val eq '_hdr_strings' &&
                $$r_config{'_hdr_string'} == 1 &&
                $$r_config{'_include_string'} == 0)
            {
                next;
            }
            if ($$r_config{$val} ne '0')
            {
                print CLFH "#include <$$r_config{$val}>\n";
            }
        }
        print CLFH "\n";
    }
    print CLFH $code;
    close CLFH;

    system ("cat $name.c >> $LOG");

    my $rc = _check_link ($name, {} );
    if ($rc != 0)
    {
        if ($otherlibs ne '')
        {
            $rc = _check_link ($name, { 'otherlibs' => $otherlibs, } );
            if ($rc == 0)
            {
                my $r_hash = $$r_config{'reqlibs'};
                my @vals = split (/\s+/, $otherlibs);
                foreach my $val (@vals)
                {
                    if ($val eq '') { next; }
                    $$r_hash{$val} = 1;
                }
            }
        }
        if ($rc != 0 && $$r_a{'tryextern'} == 1)
        {
            $rc = _check_link ($name, { 'cflags' => '-D_TRY_extern_', } );
            if ($rc != 0 && $otherlibs ne '')
            {
                $rc = _check_link ($name, { 'cflags' => '-D_TRY_extern_',
                    'otherlibs' => $otherlibs, } );
                if ($rc == 0)
                {
                    my $r_hash = $$r_config{'reqlibs'};
                    my @vals = split (/\s+/, $otherlibs);
                    foreach my $val (@vals)
                    {
                        if ($val eq '') { next; }
                        $$r_hash{$val} = 1;
                    }
                }
            }
        }
    }

    if ($$r_a{'nounlink'} == 0)
    {
        unlink "$name.exe";
        unlink "$name.c";
        unlink "$name.o";
    }
    return $rc;
}

sub
_check_link
{
    my ($name, $r_a) = @_;

    my $cmd = "$ENV{'CC'} $ENV{'CFLAGS'} ";
    if (defined ($$r_a{'cflags'}))
    {
        $cmd .= ' ' . $$r_a{'cflags'} . ' ';
    }
    $cmd .= "-o $name.exe $name.c";
    $cmd .= " $ENV{'LDFLAGS'} $ENV{'LIBS'}";
    if (defined ($$r_a{'otherlibs'}) && $$r_a{'otherlibs'} ne undef)
    {
        $cmd .= ' ' . $$r_a{'otherlibs'} . ' ';
    }
    print LOGFH "##  link test: $cmd\n";
    my $rc = system ("$cmd >> $LOG 2>&1");
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

    # always include these four if present ...
    foreach my $val ('_hdr_stdio', '_hdr_stdlib', '_sys_types', '_sys_param')
    {
        if (defined ($$r_config{$val}) &&
             $$r_config{$val} ne '0')
        {
            print CCFH "#include <$$r_config{$val}>\n";
        }
    }

    if ($$r_a{'incheaders'} == 1)
    {
        foreach my $val (@$r_clist)
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
                $$r_config{'_include_malloc'} == 0)
            {
                next;
            }
            if ($val eq '_hdr_strings' &&
                $$r_config{'_hdr_string'} == 1 &&
                $$r_config{'_include_string'} == 0)
            {
                next;
            }
            if ($$r_config{$val} ne '0')
            {
                print CCFH "#include <$$r_config{$val}>\n";
            }
        }
        print CCFH "\n";
    }
    print CCFH $code;
    close CCFH;

    my $cmd = "$ENV{'CC'} $ENV{'CFLAGS'} -c $name.c";
    print LOGFH "##  compile test: $cmd\n";
    system ("cat $name.c >> $LOG");
    my $rc = system ("$cmd >> $LOG 2>&1");
    print LOGFH "##  compile test: $rc\n";
    unlink "$name.c";
    unlink "$name.o";
    return $rc;
}

sub
check_header
{
    my ($name, $file, $r_clist, $r_config) = @_;

    print LOGFH "## [$name] header: $file ... \n";
    print STDERR "header: $file ... ";
    my $code = <<"_HERE_";
#include <${file}>
main () { exit (0); }
_HERE_
    my $rc = check_compile ($name, $code, $r_clist, $r_config,
        { 'incheaders' => 0, });
    my $val = 0;
    if ($rc == 0)
    {
        $val = $file;
        print LOGFH "## [$name] yes\n";
        print STDERR "yes\n";
    }
    else
    {
        print LOGFH "## [$name] no\n";
        print STDERR "no\n";
    }
    push @$r_clist, $name;
    $$r_config{$name} = $val;
}

sub
check_void
{
    my ($name, $r_clist, $r_config) = @_;

    print LOGFH "## [$name] supported: void ... \n";
    print STDERR "supported: void ... ";
    my $code = <<"_HERE_";
main () { void *x; x = (char *) NULL; exit (0); }
_HERE_
    my $rc = check_compile ($name, $code, $r_clist, $r_config,
        { 'incheaders' => 1, });
    push @$r_clist, $name;
    $$r_config{$name} = 0;
    if ($rc == 0)
    {
        $$r_config{$name} = 1;
        print LOGFH "## [$name] yes\n";
        print STDERR "yes\n";
    }
    else
    {
        print LOGFH "## [$name] no\n";
        print STDERR "no\n";
    }
}

sub
check_proto
{
    my ($name, $r_clist, $r_config) = @_;

    print LOGFH "## [$name] supported: prototypes ... \n";
    print STDERR "supported: prototypes ... ";
    my $code = <<"_HERE_";
_BEGIN_EXTERNS_
extern int foo (int, int);
_END_EXTERNS_
int bar () { int rc; rc = foo (1,1); return 0; }
_HERE_
    my $rc = check_compile ($name, $code, $r_clist, $r_config,
        { 'incheaders' => 1, });
    push @$r_clist, $name;
    $$r_config{$name} = 0;
    if ($rc == 0)
    {
        $$r_config{$name} = 1;
        print LOGFH "## [$name] yes\n";
        print STDERR "yes\n";
    }
    else
    {
        print LOGFH "## [$name] no\n";
        print STDERR "no\n";
    }
}

sub
check_command
{
    my ($name, $cmd, $r_clist, $r_config) = @_;

    print LOGFH "## [$name] command $cmd ... \n";
    print STDERR "command: $cmd ... ";

    push @$r_clist, $name;
    $$r_config{$name} = 0;
    foreach my $p (split /$Config{'path_sep'}/o, $ENV{'PATH'})
    {
        if (-x "$p/$cmd")
        {
            $$r_config{$name} = 1;
            print LOGFH "## [$name] yes\n";
            print STDERR "yes\n";
        }
    }
    if (! defined ($$r_config{$name}))
    {
        print LOGFH "## [$name] no\n";
        print STDERR "no\n";
    }
}

sub
check_include_malloc
{
    my ($name, $r_clist, $r_config) = @_;

    push @$r_clist, $name;
    $$r_config{$name} = 0;
    if ($$r_config{'_hdr_malloc'} ne '0')
    {
        print LOGFH "## [$name] header: include malloc.h ... \n";
        print STDERR "header: include malloc.h ... ";

        my $code = <<"_HERE_";
#include <malloc.h>
main ()
{
    char *x; x = (char *) malloc (20);
}
_HERE_
        my $rc = check_compile ($name, $code, $r_clist, $r_config,
                { 'incheaders' => 0, });
        if ($rc == 0)
        {
            $$r_config{$name} = 1;
            print LOGFH "## [$name] yes\n";
            print STDERR "yes\n";
        }
        else
        {
            print LOGFH "## [$name] no\n";
            print STDERR "no\n";
        }
    }
}

sub
check_include_string
{
    my ($name, $r_clist, $r_config) = @_;

    push @$r_clist, $name;
    $$r_config{$name} = 0;
    if ($$r_config{'_hdr_string'} ne '0' &&
        $$r_config{'_hdr_strings'} ne '0')
    {
        print LOGFH "## [$name] header: include both string.h & strings.h ... \n";
        print STDERR "header: include both string.h & strings.h ... ";

        my $code = <<"_HERE_";
#include <string.h>
#include <strings.h>
main ()
{
    char *x; x = malloc (20);
}
_HERE_
        my $rc = check_compile ($name, $code, $r_clist, $r_config,
                { 'incheaders' => 0, });
        if ($rc == 0)
        {
            $$r_config{$name} = 1;
            print LOGFH "## [$name] yes\n";
            print STDERR "yes\n";
        }
        else
        {
            print LOGFH "## [$name] no\n";
            print STDERR "no\n";
        }
    }
}

sub
check_dcl
{
    my ($name, $proto, $r_clist, $r_config) = @_;

    print LOGFH "## [$name] need prototype: $proto ... \n";
    print STDERR "need prototype: $proto ... ";
    push @$r_clist, $name;
    $$r_config{$name} = 0;
    my $code = <<"_HERE_";
_BEGIN_EXTERNS_
struct _TEST_struct { int _TEST_member; };
extern struct _TEST_struct* $proto _ARG_((struct _TEST_struct*));
_END_EXTERNS_
_HERE_
    my $rc = check_compile ($name, $code, $r_clist, $r_config,
            { 'incheaders' => 1, });
    if ($rc == 0)
    {
        $$r_config{$name} = 1;
        print LOGFH "## [$name] yes\n";
        print STDERR "yes\n";
    }
    else
    {
        print LOGFH "## [$name] no\n";
        print STDERR "no\n";
    }
}

sub
check_type
{
    my ($name, $type, $r_clist, $r_config) = @_;

    print LOGFH "## [$name] type $type ... \n";
    print STDERR "type $type ... ";
    push @$r_clist, $name;
    $$r_config{$name} = 0;
    my $code = <<"_HERE_";
struct xxx { $type mem; };
static struct xxx v;
struct xxx* f() { return &v; }
main () { struct xxx *tmp; tmp = f(); exit (0); }
_HERE_
    my $rc = check_compile ($name, $code, $r_clist, $r_config,
            { 'incheaders' => 1, });
    if ($rc == 0)
    {
        $$r_config{$name} = 1;
        print LOGFH "## [$name] yes\n";
        print STDERR "yes\n";
    }
    else
    {
        print LOGFH "## [$name] no\n";
        print STDERR "no\n";
    }
}

sub
check_lib
{
    my ($name, $func, $r_clist, $r_config, $r_a) = @_;

    print LOGFH "## [$name] function: $func ... \n";
    print STDERR "function: $func ... ";
    push @$r_clist, $name;
    $$r_config{$name} = 0;
    my $code = <<"_HERE_";
typedef int (*_TEST_fun_)();
#undef $func
#ifdef _TRY_extern_
_BEGIN_EXTERNS_
extern int $func();
_END_EXTERNS_
#endif
static _TEST_fun_ i=(_TEST_fun_) $func;
main () {  return (i==0); }
_HERE_
    my $val = $$r_a{'otherlibs'} || '';
    if ($name =~ m#^_mth#o)
    {
        $val = '-lm';
    }
    my $rc = check_link ($name, $code, $r_clist, $r_config,
        { 'includes' => 0, 'nounlink' => 0, 'otherlibs' => $val, 'tryextern' => 1, });
    if ($rc == 0)
    {
        $$r_config{$name} = 1;
        print LOGFH "## [$name] yes\n";
        print STDERR "yes\n";
    }
    else
    {
        print LOGFH "## [$name] no\n";
        print STDERR "no\n";
    }
}

sub
check_setmntent_1arg
{
    my ($name, $r_clist, $r_config) = @_;

    print LOGFH "## [$name] setmntent(): 1 argument ... \n";
    print STDERR "setmntent(): 1 argument ... ";
    push @$r_clist, $name;
    $$r_config{$name} = 0;
    my $code = <<"_HERE_";
main () { setmntent ("/etc/mnttab"); }
_HERE_
    my $rc = check_link ($name, $code, $r_clist, $r_config,
        { 'includes' => 1, 'nounlink' => 0, 'otherlibs' => undef, 'tryextern' => 0, });
    if ($rc == 0)
    {
        $$r_config{$name} = 1;
        print LOGFH "## [$name] yes\n";
        print STDERR "yes\n";
    }
    else
    {
        print LOGFH "## [$name] no\n";
        print STDERR "no\n";
    }
}

sub
check_setmntent_2arg
{
    my ($name, $r_clist, $r_config) = @_;

    print LOGFH "## [$name] setmntent(): 2 arguments ... \n";
    print STDERR "setmntent(): 2 arguments ... ";
    push @$r_clist, $name;
    $$r_config{$name} = 0;
    my $code = <<"_HERE_";
main () { setmntent ("/etc/mnttab", "r"); }
_HERE_
    my $rc = check_link ($name, $code, $r_clist, $r_config,
        { 'includes' => 1, 'nounlink' => 0, 'otherlibs' => undef, 'tryextern' => 0, });
    if ($rc == 0)
    {
        $$r_config{$name} = 1;
        print LOGFH "## [$name] yes\n";
        print STDERR "yes\n";
    }
    else
    {
        print LOGFH "## [$name] no\n";
        print STDERR "no\n";
    }
}

sub
check_statfs_2arg
{
    my ($name, $r_clist, $r_config) = @_;

    print LOGFH "## [$name] statfs(): 2 arguments ... \n";
    print STDERR "statfs(): 2 arguments ... ";
    push @$r_clist, $name;
    $$r_config{$name} = 0;
    my $code = <<"_HERE_";
main () {
    struct statfs statBuf; char *name; name = "/";
    statfs (name, &statBuf);
}
_HERE_
    my $rc = check_link ($name, $code, $r_clist, $r_config,
        { 'includes' => 1, 'nounlink' => 0, 'otherlibs' => undef, 'tryextern' => 0, });
    if ($rc == 0)
    {
        $$r_config{$name} = 1;
        print LOGFH "## [$name] yes\n";
        print STDERR "yes\n";
    }
    else
    {
        print LOGFH "## [$name] no\n";
        print STDERR "no\n";
    }
}

sub
check_statfs_3arg
{
    my ($name, $r_clist, $r_config) = @_;

    print LOGFH "## [$name] statfs(): 3 arguments ... \n";
    print STDERR "statfs(): 3 arguments ... ";
    push @$r_clist, $name;
    $$r_config{$name} = 0;
    my $code = <<"_HERE_";
main () {
    struct statfs statBuf; char *name; name = "/";
    statfs (name, &statBuf, sizeof (statBuf));
}
_HERE_
    my $rc = check_link ($name, $code, $r_clist, $r_config,
        { 'includes' => 1, 'nounlink' => 0, 'otherlibs' => undef, 'tryextern' => 0, });
    if ($rc == 0)
    {
        $$r_config{$name} = 1;
        print LOGFH "## [$name] yes\n";
        print STDERR "yes\n";
    }
    else
    {
        print LOGFH "## [$name] no\n";
        print STDERR "no\n";
    }
}

sub
check_statfs_4arg
{
    my ($name, $r_clist, $r_config) = @_;

    print LOGFH "## [$name] statfs(): 4 arguments ... \n";
    print STDERR "statfs(): 4 arguments ... ";
    push @$r_clist, $name;
    $$r_config{$name} = 0;
    my $code = <<"_HERE_";
main () {
    struct statfs statBuf; char *name; name = "/";
    statfs (name, &statBuf, sizeof (statBuf), 0);
}
_HERE_
    my $rc = check_link ($name, $code, $r_clist, $r_config,
        { 'includes' => 1, 'nounlink' => 0, 'otherlibs' => undef, 'tryextern' => 0, });
    if ($rc == 0)
    {
        $$r_config{$name} = 1;
        print LOGFH "## [$name] yes\n";
        print STDERR "yes\n";
    }
    else
    {
        print LOGFH "## [$name] no\n";
        print STDERR "no\n";
    }
}

sub
check_size
{
    my ($name, $type, $r_clist, $r_config) = @_;

    print LOGFH "## [$name] sizeof: $type ... \n";
    print STDERR "sizeof: $type ... ";
    push @$r_clist, $name;
    $$r_config{$name} = 0;
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
        $$r_config{$name} = $val;
        print LOGFH "## [$name] $val\n";
        print STDERR "$val\n";
    }
    else
    {
        print LOGFH "## [$name] no\n";
        print STDERR "no\n";
    }
}

sub
check_member
{
    my ($name, $struct, $member, $r_clist, $r_config) = @_;

    print LOGFH "## [$name] exists: $struct.$member ... \n";
    print STDERR "exists: $struct.$member ... ";
    push @$r_clist, $name;
    $$r_config{$name} = 0;
    my $code = <<"_HERE_";
main () { struct $struct s; int i; i = sizeof (s.$member); }
_HERE_
    my $rc = check_compile ($name, $code, $r_clist, $r_config,
            { 'incheaders' => 1, });
    if ($rc == 0)
    {
        $$r_config{$name} = 1;
        print LOGFH "## [$name] yes\n";
        print STDERR "yes\n";
    }
    else
    {
        print LOGFH "## [$name] no\n";
        print STDERR "no\n";
    }
}

sub
check_int_declare
{
    my ($name, $function, $r_clist, $r_config) = @_;

    print LOGFH "## [$name] declared: $function ... \n";
    print STDERR "declared: $function ... ";
    push @$r_clist, $name;
    $$r_config{$name} = 0;
    my $code = <<"_HERE_";
    main () { int x; x = $function; }
_HERE_
    my $rc = check_compile ($name, $code, $r_clist, $r_config,
            { 'incheaders' => 1, });
    if ($rc == 0)
    {
        $$r_config{$name} = 1;
        print LOGFH "## [$name] yes\n";
        print STDERR "yes\n";
    }
    else
    {
        print LOGFH "## [$name] no\n";
        print STDERR "no\n";
    }
}

sub
check_ptr_declare
{
    my ($name, $function, $r_clist, $r_config) = @_;

    print LOGFH "## [$name] declared: $function ... \n";
    print STDERR "declared: $function ... ";
    push @$r_clist, $name;
    $$r_config{$name} = 0;
    my $code = <<"_HERE_";
main () { _VOID_ *x; x = $function; }
_HERE_
    my $rc = check_compile ($name, $code, $r_clist, $r_config,
            { 'incheaders' => 1, });
    if ($rc == 0)
    {
        $$r_config{$name} = 1;
        print LOGFH "## [$name] yes\n";
        print STDERR "yes\n";
    }
    else
    {
        print LOGFH "## [$name] no\n";
        print STDERR "no\n";
    }
}


sub
create_config
{
    my (@clist, %config);

    $config{'reqlibs'} = {};

    open (CCOFH, ">../config.h");
    print CCOFH <<'_HERE_';

#ifndef _config_H
#define _config_H 1
_HERE_

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
        check_header ($$r_arr[0], $$r_arr[1], \@clist, \%config);
    }
    check_void ('_key_void', \@clist, \%config);
    check_proto ('_proto_stdc', \@clist, \%config);

    if (! open (DATAIN, $ARGV[0]))
    {
        print STDERR "$ARGV[0]: $!\n";
        exit 1;
    }

    while (my $line = <DATAIN>)
    {
        chomp $line;
        if ($line =~ /^#/o || $line eq '')
        {
            next;
        }

        if ($line =~ m#^(hdr|sys)\s+(.*)#o)
        {
            my $typ = $1;
            my $hdr = $2;
            my $nm = "_${typ}_" . $hdr;
            $nm =~ s,\.h$,,o;
            $nm =~ s,/,_,go;
            $nm = lc $nm;
            if ($typ eq 'sys')
            {
                $hdr = 'sys/' . $hdr;
            }
            if (! defined ($config{$nm}))
            {
                check_header ($nm, $hdr, \@clist, \%config);
                if ($hdr eq 'malloc.h')
                {
                    check_include_malloc ('_include_malloc', \@clist, \%config);
                }
                if (($hdr eq 'string.h' && defined $config{'_hdr_strings'} ||
                    ($hdr eq 'strings.h') && defined $config{'_hdr_string'}))
                {
                    check_include_string ('_include_string', \@clist, \%config);
                }
            }
        }
        elsif ($line =~ m#^command\s+(.*)#o)
        {
            my $cmd = $1;
            my $nm = "_command_" . lc $cmd;
            if (! defined ($config{$nm}))
            {
                check_command ($nm, $cmd, \@clist, \%config);
            }
        }
        elsif ($line =~ m#^npt\s+(.*)#o)
        {
            my $func = $1;
            my $nm = "_npt_" . lc $func;
            if (! defined ($config{$nm}))
            {
                check_dcl ($nm, $func, \@clist, \%config);
            }
        }
        elsif ($line =~ m#^typ\s+(.*)#o)
        {
            my $tnm = $1;
            my $nm = "_typ_" . lc $tnm;
            if (! defined ($config{$nm}))
            {
                check_type ($nm, $tnm, \@clist, \%config);
            }
        }
        elsif ($line =~ m#^(lib|mth)\s+([^\s]+)(.*)?#o)
        {
            my $typ = $1;
            my $func = $2;
            my $libs = $3 || '';
            my $nm = "_${typ}_" . $func;
            if (! defined ($config{$nm}))
            {
                check_lib ($nm, $func, \@clist, \%config,
                       { 'otherlibs' => $libs, });
                if ($func eq 'setmntent' && $config{$nm} == 1)
                {
                    check_setmntent_1arg ('_setmntent_1arg', \@clist, \%config);
                    check_setmntent_2arg ('_setmntent_2arg', \@clist, \%config);
                }
                if ($func eq 'statfs' && $config{$nm} == 1)
                {
                    check_statfs_2arg ('_statfs_2arg', \@clist, \%config);
                    check_statfs_3arg ('_statfs_3arg', \@clist, \%config);
                    check_statfs_4arg ('_statfs_4arg', \@clist, \%config);
                }
            }
        }
        elsif ($line =~ m#^dcl\s+(.*)\s+(.*)#o)
        {
            my $type = $1;
            my $var = $2;
            my $nm = "_dcl_" . lc $var;
            if (! defined ($config{$nm}))
            {
                if ($type eq 'int')
                {
                    check_int_declare ($nm, $var, \@clist, \%config);
                }
                elsif ($type eq 'ptr')
                {
                    check_ptr_declare ($nm, $var, \@clist, \%config);
                }
            }
        }
        elsif ($line =~ m#^member\s+(.*)\s+(.*)#o)
        {
            my $struct = $1;
            my $member = $2;
            my $nm = "_mem_" . lc $struct . '_' . lc $member;
            if (! defined ($config{$nm}))
            {
                check_member ($nm, $struct, $member, \@clist, \%config);
            }
        }
        elsif ($line =~ m#^size\s+(.*)#o)
        {
            my $typ = $1;
            $typ =~ s/\s*$//o;
            my $nm = "_siz_" . lc $typ;
            $nm =~ s, ,_,go;
            if (! defined ($config{$nm}))
            {
                check_size ($nm, $typ, \@clist, \%config);
            }
        }
        else
        {
            print "unknown command: $line\n";
            print LOGFH "unknown command: $line\n";
        }
    }

    foreach my $val (@clist)
    {
        if ($config{$val} eq '0')
        {
            print CCOFH "#undef $val\n";
        }
        else
        {
            if ($val =~ m#^_siz_#o)
            {
                print CCOFH "#define $val $config{$val}\n";
            }
            else
            {
                print CCOFH "#define $val 1\n";
            }
        }
    }

    my $r_hash = $config{'reqlibs'};
    print CCOFH "\n";
    print CCOFH "#define REQUIRED_LIBS \"" .
        join (' ', keys %$r_hash) . "\"\n";
    print CCOFH "\n";

    print CCOFH <<'_HERE_';

#if ! _key_void || ! _proto_stdc
# define void int
#endif

#ifndef _
# if _proto_stdc
#  define _(args) args
# else
#  define _(args) ()
# endif
#endif

#if _lib_bindtextdomain && \
_lib_gettext && \
_lib_setlocale && \
_lib_textdomain && \
_hdr_libintl && \
_hdr_locale && \
_command_msgfmt
# define _enable_nls 1
#else
# define _enable_nls 0
#endif

#if _typ_statvfs_t
# define Statvfs_t statvfs_t
#else
# define Statvfs_t struct statvfs
#endif

#if _typ_size_t
# define Size_t size_t
#else
# define Size_t unsigned int
#endif

#if _typ_uint_t
# define Uint_t uint_t
#else
# define Uint_t unsigned int
#endif

#if _typ_uid_t
# define Uid_t uid_t
#else
# define Uid_t int
#endif

#if _lib_snprintf
# define Snprintf snprintf
# define SPF(a1,a2,a3)      a1,a2,a3
#else
# define Snprintf sprintf
# define SPF(a1,a2,a3)      a1,a3
#endif

#define _config_by_iffe_ 0
#define _config_by_mkconfig_pl_ 1

#endif
_HERE_

    close CCOFH;
}


##

if (! -d $TMP) { mkdir $TMP, 0777; }
chdir $TMP;

unlink $LOG;
open (LOGFH, ">>$LOG");
$ENV{'CFLAGS'} = $ENV{'CFLAGS'} . ' ' . $ENV{'CINCLUDES'};
print LOGFH "CC: $ENV{'CC'}\n";
print LOGFH "CFLAGS: $ENV{'CFLAGS'}\n";
print LOGFH "LDFLAGS: $ENV{'LDFLAGS'}\n";
print LOGFH "LIBS: $ENV{'LIBS'}\n";

&create_config;

close LOGFH;

chdir "..";
rmdir $TMP;
