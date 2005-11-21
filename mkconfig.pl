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

sub
check_run
{
    my ($name, $code, $r_val, $r_clist, $r_config, $r_a) = @_;

    my $rc = check_link ($name, $code, $r_clist, $r_config,
        { 'nounlink' => 1, 'uselibs' => 1, 'tryextern' => 0, });
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

    open (CLFH, ">$name.c");

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
    print CLFH $code;
    close CLFH;

    my $cmd = "$ENV{'CC'} $ENV{'CFLAGS'} -o $name.exe $name.c";
    $cmd .= " $ENV{'LDFLAGS'} $ENV{'LIBS'}";
    if ($$r_a{'uselibs'} == 0)
    {
        $cmd =~ s/-lm//o;
    }
    if ($$r_a{'uselibs'} == 0 &&
        $name =~ /^_mth/o)
    {
        $cmd .= ' -lm';
    }
    print LOGFH "##  link test: $cmd\n";
    system ("cat $name.c >> $LOG");
    my $rc = system ("$cmd >> $LOG 2>&1");
    if ($rc != 0)
    {
        print LOGFH "##  link test fail: try w/extern\n";
        $cmd = "$ENV{'CC'} $ENV{'CFLAGS'} -D_TRY_extern_ -o $name.exe $name.c";
        $rc = system ("$cmd >> $LOG 2>&1");
    }
    print LOGFH "##  link test: $rc\n";
    if ($rc == 0)
    {
        if (! -x "$name.exe")  # not executable.
        {
            $rc = 1;
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
check_compile
{
    my ($name, $code, $r_clist, $r_config, $r_a) = @_;

    open (CCFH, ">$name.c");

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
extern int foo (int, int);
bar () { foo (1,1); }
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
#if defined(__STDC__) || defined(__cplusplus) || defined(c_plusplus)
#define _ARG_(x)	x
#else
#define _ARG_(x)	()
#endif
#if defined(__cplusplus)
#define _BEGIN_EXTERNS_	extern "C" {
#define _END_EXTERNS_	}
#else
#define _BEGIN_EXTERNS_
#define _END_EXTERNS_
#endif
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
main () { f(); exit (0); }
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
#if defined(__cplusplus)
#define _BEGIN_EXTERNS_ extern "C" {
#define _END_EXTERNS_   }
#else
#define _BEGIN_EXTERNS_
#define _END_EXTERNS_
#endif
typedef int (*_TEST_fun_)();
#ifdef _TRY_extern_
_BEGIN_EXTERNS_
extern int $func();
_END_EXTERNS_
#endif
static _TEST_fun_ i=(_TEST_fun_) $func;
main () {  return (i==0); }
_HERE_
    my $val = 0;
    if ($name =~ m#^_mth#o)
    {
        $val = 1;
    }
    my $rc = check_link ($name, $code, $r_clist, $r_config,
        { 'nounlink' => 0, 'uselibs' => $val, 'tryextern' => 1, });
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
        { 'nounlink' => 0, 'uselibs' => 1, 'tryextern' => 0, });
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
        { 'nounlink' => 0, 'uselibs' => 1, 'tryextern' => 0, });
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
        { 'nounlink' => 0, 'uselibs' => 1, 'tryextern' => 0, });
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
        { 'nounlink' => 0, 'uselibs' => 1, 'tryextern' => 0, });
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
        { 'nounlink' => 0, 'uselibs' => 1, 'tryextern' => 0, });
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
    my $val;
    my $rc = check_run ($name, $code, \$val, $r_clist, $r_config);
    if ($rc == 0)
    {
        $$r_config{$name} = $val;
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
    main () { void *x; x = $function; }
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

    open (CCOFH, ">../config.h");
    print CCOFH <<'_HERE_';

#ifndef _config_H
#define _config_H 1
_HERE_

    # FreeBSD has buggy headers, requires sys/param.h as a required include.
    my @headlist1 = (
        [ "_sys_types", "sys/types.h", ],
        [ "_hdr_stdio", "stdio.h", ],
        [ "_hdr_stdlib", "stdlib.h", ],
        [ "_sys_param", "sys/param.h", ],
        );
    my @headlist2 = (
        [ "_hdr_ctype", "ctype.h", ],
        [ "_hdr_errno", "errno.h", ],
        [ "_hdr_fshelp", "fshelp.h", ],
        [ "_hdr_getopt", "getopt.h", ],
        [ "_hdr_kernel_fs_info", "kernel/fs_info.h", ],
        [ "_hdr_limits", "limits.h", ],
        [ "_hdr_libintl", "libintl.h", ],
        [ "_hdr_locale", "locale.h", ],
        [ "_hdr_malloc", "malloc.h", ],
        [ "_hdr_math", "math.h", ],
        [ "_hdr_memory", "memory.h", ],
        [ "_hdr_mntent", "mntent.h", ],
        [ "_hdr_mnttab", "mnttab.h", ],
        [ "_hdr_storage_Directory", "storage/Directory.h", ],
        [ "_hdr_storage_Entry", "storage/Entry.h", ],
        [ "_hdr_storage_Path", "storage/Path.h", ],
        [ "_hdr_string", "string.h", ],
        [ "_hdr_strings", "strings.h", ],
        [ "_hdr_time", "time.h", ],
        [ "_hdr_unistd", "unistd.h", ],
        [ "_hdr_windows", "windows.h", ],
        [ "_hdr_zone", "zone.h", ],
        [ "_sys_fs_types", "sys/fs_types.h", ],
        [ "_sys_fstyp", "sys/fstyp.h", ],
        [ "_sys_fstypes", "sys/fstypes.h", ],
        [ "_sys_mntctl", "sys/mntctl.h", ],
        [ "_sys_mntent", "sys/mntent.h", ],
        [ "_sys_mnttab", "sys/mnttab.h", ],
        [ "_sys_mount", "sys/mount.h", ],
        [ "_sys_stat", "sys/stat.h", ],
        [ "_sys_statfs", "sys/statfs.h", ],
        [ "_sys_statvfs", "sys/statvfs.h", ],
        [ "_sys_time", "sys/time.h", ],
        [ "_sys_vfs", "sys/vfs.h", ],
        [ "_sys_vfstab", "sys/vfstab.h", ],
        [ "_sys_vmount", "sys/vmount.h", ],
        );

    foreach my $r_arr (@headlist1)
    {
        check_header ($$r_arr[0], $$r_arr[1], \@clist, \%config);
    }

    check_void ('_key_void', \@clist, \%config);
    check_proto ('_proto_stdc', \@clist, \%config);

    check_command ('_command_msgfmt', 'msgfmt', \@clist, \%config);

    foreach my $r_arr (@headlist2)
    {
        check_header ($$r_arr[0], $$r_arr[1], \@clist, \%config);
    }

    check_include_malloc ('_include_malloc', \@clist, \%config);
    check_include_string ('_include_string', \@clist, \%config);
    check_dcl ('_npt_getenv', 'getenv', \@clist, \%config);
    check_dcl ('_npt_statfs', 'statfs', \@clist, \%config);
    check_type ('_typ_statvfs_t', 'statvfs_t', \@clist, \%config);
    check_type ('_typ_size_t', 'size_t', \@clist, \%config);
    check_type ('_typ_uint_t', 'uint_t', \@clist, \%config);
    check_type ('_typ_uid_t', 'uid_t', \@clist, \%config);
    check_lib ('_lib_bcopy', 'bcopy', \@clist, \%config);
    check_lib ('_lib_bindtextdomain', 'bindtextdomain', \@clist, \%config);
    check_lib ('_lib_bzero', 'bzero', \@clist, \%config);
    check_lib ('_lib_endmntent', 'endmntent', \@clist, \%config);
    check_lib ('_lib_fmod', 'fmod', \@clist, \%config);
    check_lib ('_lib_fs_stat_dev', 'fs_stat_dev', \@clist, \%config);
    check_lib ('_lib_fshelp', 'fshelp', \@clist, \%config);
    check_lib ('_lib_GetDiskFreeSpace', 'GetDiskFreeSpace', \@clist, \%config);
    check_lib ('_lib_GetDiskFreeSpaceEx', 'GetDiskFreeSpaceEx', \@clist, \%config);
    check_lib ('_lib_GetDriveType', 'GetDriveType', \@clist, \%config);
    check_lib ('_lib_GetLogicalDriveStrings', 'GetLogicalDriveStrings', \@clist, \%config);
    check_lib ('_lib_GetVolumeInformation', 'GetVolumeInformation', \@clist, \%config);
    check_lib ('_lib_getfsstat', 'getfsstat', \@clist, \%config);
    check_lib ('_lib_getmnt', 'getmnt', \@clist, \%config);
    check_lib ('_lib_getmntent', 'getmntent', \@clist, \%config);
    check_lib ('_lib_getmntinfo', 'getmntinfo', \@clist, \%config);
    check_lib ('_lib_getopt', 'getopt', \@clist, \%config);
    check_lib ('_lib_gettext', 'gettext', \@clist, \%config);
    check_lib ('_lib_getvfsstat', 'getvfsstat', \@clist, \%config);
    check_lib ('_lib_getzoneid', 'getzoneid', \@clist, \%config);
    check_lib ('_lib_hasmntopt', 'hasmntopt', \@clist, \%config);
    check_lib ('_lib_memcpy', 'memcpy', \@clist, \%config);
    check_lib ('_lib_memset', 'memset', \@clist, \%config);
    check_lib ('_lib_mntctl', 'mntctl', \@clist, \%config);
    check_lib ('_lib_setlocale', 'setlocale', \@clist, \%config);
    check_lib ('_lib_setmntent', 'setmntent', \@clist, \%config);
    check_lib ('_lib_snprintf', 'snprintf', \@clist, \%config);
    check_lib ('_lib_statfs', 'statfs', \@clist, \%config);
    check_lib ('_lib_statvfs', 'statvfs', \@clist, \%config);
    check_lib ('_lib_sysfs', 'sysfs', \@clist, \%config);
    check_lib ('_lib_textdomain', 'textdomain', \@clist, \%config);
    check_lib ('_lib_zone_getattr', 'zone_getattr', \@clist, \%config);
    check_lib ('_lib_zone_list', 'zone_list', \@clist, \%config);
    # there's no distinction in this program between _lib_fmod and _mth_fmod.
    check_lib ('_mth_fmod', 'fmod', \@clist, \%config);

    check_setmntent_1arg ('_setmntent_1arg', \@clist, \%config);
    check_setmntent_2arg ('_setmntent_2arg', \@clist, \%config);
    check_statfs_2arg ('_statfs_2arg', \@clist, \%config);
    check_statfs_3arg ('_statfs_3arg', \@clist, \%config);
    check_statfs_4arg ('_statfs_4arg', \@clist, \%config);

    check_int_declare ('_dcl_errno', 'errno', \@clist, \%config);
    check_int_declare ('_dcl_optind', 'optind', \@clist, \%config);
    check_ptr_declare ('_dcl_optarg', 'optarg', \@clist, \%config);

    check_member ('_mem_f_bsize_statfs', 'statfs', 'f_bsize', \@clist, \%config);
    check_member ('_mem_f_fsize_statfs', 'statfs', 'f_fsize', \@clist, \%config);
    check_member ('_mem_f_iosize_statfs', 'statfs', 'f_iosize', \@clist, \%config);
    check_member ('_mem_f_frsize_statfs', 'statfs', 'f_frsize', \@clist, \%config);
    check_member ('_mem_f_fstypename_statfs', 'statfs', 'f_fstypename', \@clist, \%config);
    check_member ('_mem_mount_info_statfs', 'statfs', 'mount_info', \@clist, \%config);
    check_member ('_mem_f_type_statfs', 'statfs', 'f_type', \@clist, \%config);
    check_member ('_mem_mnt_time_mnttab', 'mnttab', 'mnt_time', \@clist, \%config);
    check_member ('_mem_vmt_time_vmount', 'vmount', 'vmt_time', \@clist, \%config);

    check_size ('_siz_long_long', 'long long', \@clist, \%config);

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
