mkconfig - configuration tool (version 2.3)

Website: https://gentoo.com/di/mkconfig.html
SourceForge: https://sourceforge.net/projects/mkconfig/

mkconfig is a build configuration utility. It creates an output file
intended to be included as a header file, run as a shell script, used
as a configuration file, or any other use. mkconfig is written in
portable shell script and designed to be extensible for any
configuration use.

It also includes tools that can be used to compile, link and build
libraries and executables using the shell configuration previously
built.

An example of mkconfig in use can be seen in the
'di' program at https://sourceforge.net/projects/diskinfo-di/

mkconfig works with most any bourne shell compatible shell.  Modern
shells that are not bourne shell compatible are:
  posh, yash, zsh (compatibility mode).
Very old shells do not have the memory capabilities needed in order to
save the large number of variables that mkconfig needs.

TESTING
    Version 2.0.0 has been tested on:
      Linux
        RedHat 7.3 (gcc) (ash, bash2, sh/bash2)
        CentOS 3.9 (gcc) (ash, bash2, pdksh, sh/bash2)
        Fedora 7 (gcc) (bash3, sh/bash3)
        Fedora 27 (gcc) (bash4, sh/bash4)
        MX Linux 17.1 (gcc, clang) (bash4, dash, ksh93, mksh)
      BSD
        DragonflyBSD 4.4 (gcc) (bash4, dash, pdksh, ksh93, mksh)
        FreeBSD 7.0 (cc) (sh)
        FreeBSD 11.0 (clang) (sh, bash4, dash, pdksh, ksh93, mksh)
        NetBSD 1.62 (cc) (pdksh, sh)
        NetBSD 2.0 (cc) (pdksh, sh)
        NetBSD 7.0.1 (gcc) (pdksh, sh, bash4, mksh)
        OpenBSD 4.4 (gcc) (pdksh, sh)
      Windows
        Msys2 (gcc, clang) (ash, bash4, dash, sh/bash4)
        Cygwin (gcc) (ash, bash4, dash, mksh, sh/bash4)
      Other
        AIX 7.1 (gcc) (bash4, ksh, ksh93, sh)
        Mac OS X 10.12.6 (clang) (bash3, ksh93, sh/bash3)
        QNX 6.5 (cc) (pdksh, bash4, sh/pdksh)
        SCO SV 6.0.0 (cc) (sh, ksh, ksh93, bash3, bash2)
        Solaris 11/x86 (cc12.3) (bash4, ksh93, sh/ksh93)
        Solaris 10/sparc (cc12.3) (bash4, sh(1), sh, bash3, ksh)
        Solaris 9/x86 (gcc3) (bash4, ksh93, sh(1), bash2, sh)
        Tru64 5.1b (cc) (sh, ksh, bash2)
        UnixWare 7.1.4 (cc) (sh, ksh93, ksh88, bash2)
        (1) not a standard solaris shell

ISSUES
    - D Compiler bugs:
      ldc2 has structure size problems on 64bit (issue #28).
      gdc 4.6.3 (LinuxMint) has structure size problems on 64bit.
    - The D language portions have not been tested or used
      in a long time.

CHANGES

    2.3                                     [2020-6-3]
        Fixed an issue propogating LDFLAGS_SHARED.
        Fix library check when using g++.
        Propogate CFLAGS_OPTIMIZE and CFLAGS_DEBUG properly to linker.
        Added bin/capabilities.sh script.
        Added yash to the supported scripts list (version 2.48 or later;
          I don't know when its issues were fixed).

    2.2                                     [2020-5-22]
        Added support for oilshell (osh; oilshell.org).
        mkcl.sh will display its messages as a single printf so that
          make -j does not look really weird.

    2.1.1                                   [2019-6-25]
        env-cc: Fix getconf/cflags_system.
        Fix putsnonl function when 'echo' is in use.

    2.1.0                                   [2018-12-27]
        Add test for shell interpolation bug.  Use printf if possible
          for POSIX compliance.
        env-cc: Fix cflags_shared.
        env-cc: Pick up all cflags* and ldflags* defaults from the
          environment.
        mkcl.sh: Fix processing of LDFLAGS.
        mkcl.sh: Support .m extension.
        mkcl.sh: Support command line set of env vars (must be quoted).
        env-cc: Add support for DragonFlyBSD.
        env-cc: Add support for pkgconfig files (findpc).

    2.0.0                                   [2018-8-12]
        C: split CFLAGS, LDFLAGS, LIBS into multiple environment
          variables for easier processing. D language is probably broken.
        C: fix shared flags
        C: Various bug fixes for msys2, tru64, etc.
        Clean up interfaces to mkcl.sh, mkstaticlib.sh
        Clean output style for mkc.sh.
        Added compilation log file.
        Added 'findconfig' and 'addconfig' commands for *Config.sh files.
        Removed 'findincludefile' command.
        Remove mksharedlib.sh (now part of mkcl.sh).

    1.31                                    [2018-4-11]
        env-cc: update findincludepath to search more common paths.
        Remove Makefile and MANIFEST from standard distribution.

    1.30                                    [2018-4-10]
        Repo got completely mucked up.  Restore lost code.
        C: size: -lintl option for modern libintl.h
        C: printf_long_double : -lintl option for modern libintl.h
        Minor code cleanup.
        Update copyrights.

    1.29                                    [2018-4-6]
        Changed .tar.gz creation to not include tests.

    1.28                                    [2016-8-9]
        Cleaned up some compiler warnings.
        More fixes for msys/mingw.

    1.27                                    [2016-2-22]
        Protected standard definitions from multiple inclusion.
        Fixed ifoption/ifnotoption.
        Removed 'lib' prefix when creating libraries.
        Removed LDFLAGS when creating shared libraries.
        Fixes to run under msys.
        Added printf_long_double test (for mingw).
        Fix cache bug with values ending in '='.
        Fixed args test on mac os x.
        Fixed args test for cygwin.

    1.26                                    [2016-1-6]
        Added yes/no as possible option values.
        Options can be overridden by environment variables.

    1.25                                    [2015-10-18]
        Fix 'using_gnu_ld' environment test.
        Add 'addldflag' to env-cc.

    1.24                                    [2014-2-15]
        Updates for MirOS and Irix.
        Added -Wno-disabled-macro-expansion for clang.

    1.23                                    [19 Jan 2013]
        Added the 'using_clang' environment directive.
        Added default flags for the clang compiler.

    1.22                                    [15 Nov 2012]
        Fixed the display of the define directive.
        Fixed issues where the cache should not be used for XDR types
          and library function arguments.
        Fixed processing of nested if statements.

    1.21                                    [18 Oct 2012]
        Added examples directory.
        clang: add -Wno-unknown-warning-option
        addcflag directive updated to not add the flag if the compiler
            has a warning.
        Fixed read problems with ksh93 93u+.
        Added a work-around for cd problem w/debian ksh93 93u+ (bug #679966).
        Handle __restrict__ on NetBSD 6.
        Remove improper link flags for AIX.  Not tested.

    1.20                                    [25 Jan 2012]
        D: rewrite c-typedef extraction.
        D: handle situations where structure is typedef'd and a
           ctypedef directive is issued.
        D: several fixes for C structure extraction.
        D: improved nested structure handling.
        D: basic handling for bitfields in structures.
        D: changed prefix from C_TYP_ to C_NATIVE_ for native c types.
        D: Added the noprefix directive to not add C_ST_, C_TYP_, etc.
            prefixes to the original C language types (but not C_NATIVE_).
        D: Casts are converted.  May still be some issues.
        env: Added the source directive.
        D: fixed macro extraction with partial name.
        D: convert the version keyword to version_
        D: handle multi-line statements better.
        D: added the module directive.
        D: added the substitute directive.
        Minor speed improvements for header extraction.
        D: fixed multiple output files.
        mkc.sh: -comp: fixed to add -c flag when compiling to object w/-o flag.
        mkc.sh: merge -link and -comp.
        D: fixed some D1 conversion issues.
        Fixed if statements with unknown variables.
        D: wrap ctypes in extern
        D: fixed type conversions (followed by asterisk, lone unsigned)

    1.19                                    [20 Nov 2011]
        Created mkc.sh as a single entry point for compiling, linking,
           creating libraries, setting options and finding required libraries.
        Solaris 2.6 /bin/sh is no longer excluded.
        Fixed problem with .vars file not being cleaned on remake.
        D: Rework c-structure extraction.
        D: Better handling of nested structures and typedef'd structures.
        D: Add aliases for c argument types.
        D: revert cache check where it shouldn't be cached.
        D: Add aliases for c basic types (csizes directive).
        Fixed mkreqlib.sh to handle clibs for D.
        Fixed c-declaration test for freebsd.
        Change support for tango library and Dv1.
        Changed env-dc to compile to get D version.
        Changed env-cc and env-dc to pick up standard env variables
           from the options file.  This allows the options file to
           keep all configuration data.
        Rearranged directory structure.

    1.18                                    [8 Oct 2011]
        D: C structures are wrapped in extern (C) {}
          (to properly declare functions).
        Fixed multiple output files in the same directory.
        Fixed multiple inclusion tag for C output file.
        Fixed and updated shell locater for runtests.sh.
        Removed -std1 for OSF1 (Tru64).
        Added 'ksh88', 'ksh93' as valid shell names.

    1.17                                    [30 Sep 2011]
        Fixed cmacro directive for D.
        Added cmembertype, cmemberxdr for D.
        Added memberxdr for C.
        Removed rquota_xdr, gqa_uid_xdr.
        Improved documentation.
        Rewrote test suite.
        Fixed 'lib' for D.
        Updated env-cc.sh for SCO OpenServer and UnixWare.
        Fixed structure extraction for HP-UX.
        Various fixes for HP-UX, SCO OpenServer, UnixWare.
        * Shared lib tests fail for HP-UX ansi cc.

    1.16                                    [16 Sep 2011]
        Removed 'di' leftovers.
        Changed internal prefix to 'mkc'.
        Added 'echo' and 'exit' directives.
        Fixed d language tests to be 32/64 bit safe.
        Fixed d language tests for d version 1.
        Fixed d language tests for tango library.
        Added initial support for ldc and tango libraries.
          * On 64-bit, ldc's unions don't match C language sizes.
          * ldc1 doesn't have alias for 'string'.
          * ldc2 tested w/-d flag.
        Tested with dmd1, dmd2, ldc1, ldc2 on 64-bit.
        Tested with dmd1, dmd2, ldc1, ldc2, gdc1, gdc2 on 32-bit.

    1.15                                    [11 Sep 2011]
        Added pdksh in as a valid shell
        Added 'args' directive (C)
        Removed statfs, setmntent, quotactl, getfsstat_type
            (breaks backwards compatibility)
        Added 'addcflags' directive (env)
        Fixed args directive to return valid types (C)
        Fixed cdcl directive to return valid types (D)
        Updated args directive to save return type (C)
        Updated cdcl directive to save return type (D)
        Fixed shell validity tests.

    1.14                                    [22 May 2011]
        Renamed ctypeconv to ctype (breaks backwards compatibility).
        Rewrite ctype check command to use the
          C typedef name, and add an alias.
        Fixed ctype to handle unsigned typedefs correctly.
        Fixed nested structure handling.
        ctypedef will now find function pointer typedefs.
        Made D-C prefixes more consistent (breaks backwards compatibility).
        Added cmacro to convert C macros to functions.
        Merged cdefint and cdefstr to cdefine; made more generic
          (breaks backwards compatibility).
        Added breakdown of arg types for "cdcl args ...".

    1.13                                    [27 Feb 2011]
    	Handle gcc __asm__ function renames.
        Update doc for cdcl.

    1.12                                    [16 Feb 2011]
        Added d-ctypeconv check command.
        Renamed d-ctype to d-ctypedef.
        Updated to work with D1.
        More fixes for D, D-C checks.

    1.11                                    [29 Dec 2010]
        Fixed output of "yes with" libraries.
        Rearranged tests and test directories.
        Fixed test subdirectory handling.
        Added c-rquota, c-getfsstat.
        Added unset CDPATH.  The output from the cd command
          broke the scripts.
        Added D language (not yet complete).
        Backwards compatibility broken for mklink.sh.

    1.10                                    [22 Jul 2010]
        Renamed reqlibs.txt to mkconfig.reqlibs.
            Breaks backwards compatibility.
        Added support for multiple output files.
        Fixed naming of runtest log files.
        Added mkstaticlib.sh.
        Added mksharedlib.sh: preliminary support for shared libs.
        Added mklink.sh: preliminary
        Added new env-cc vars to support shared libs.
        Added new env-extension vars to support shared libs.
        Bug fix: workaround for ksh93 unable to getcwd() on Solaris.
        Fixed env-extension to match manual page.

    1.9                                     [12 Jul 2010]
        Fixed regression tests to work w/c++.
        Code cleanup.

    1.8                                     [10 Jul 2010]
        Internal code cleanup.
        Modify tests to take -d parameter for description output.
        Stop tests on change of pass number on failure.
        Add check_option.
        Fixed member test so either structs or typedefs can be used.
        Changed member test names to be _mem_struct_s_member or
            _mem_sometype_member.  Breaks backwards compatibility.

    1.7                                     [5 Jul 2010]
        Add labels to if statement.
        if statement counter and display.

    1.6                                     [4 Jul 2010]
        Fix getlistofshells() when absolute path.
        Added c-quotactl unit.
        Renamed c-include-time to c-include-conflict, and changed
            how c-include-conflict works.
        Added define, set, setint, setstr, ifoption, ifnotoption, if.
        Added option-file.
        Added mkcsetopt.sh

    1.5                                     [13 May 2010 - separate release]
        Change tmp directory structure and where logs go.
        Fixes for mkconfig.pl to handle absolute paths.
        Remove /bin from path for cygwin (duplicate of /usr/bin).
        Code cleanup.

    1.4 (di ver 4.23)                       [10 May 2010]
        Move -lsun, -lseq out of env-cc.sh
        Update env-cc.sh to handle QNX getconf 'undefined' output.
        Fix cache test (tests.d/cache.sh).
        Fix edit when /bin is symlink (shellfuncs.sh).
        Added test for -n support for shells.
        Added support to mkconfig.sh to munge set output that has $s in it.
        Export shelllist in runtests.sh; more efficient.
        Redo paths in shellfuncs; make sure symlinked paths are present.
        Needed for Tru64, do: export BIN_SH=svr4 beforehand.

    1.3 (di ver 4.22)                       [1 may 2010]
        Use the configuration file and cache to determine the necessary
          libraries to link in rather than linking in all found.
        Change library format to allow better control of link
          tests.
        Change dosubst() to always use sed.  It's more reliable.

    1.2 (di ver 4.20, 4.21)                 [12 mar 2010]
        Rewrite mkconfig.sh to use unit scripts and increase performance.
        Add environment units.
        Allow _MKCONFIG_SHELL to override shell.

    1.1 (di ver 4.19)                       [1 Feb 2010]
        Changed format of config.h file.
        Fixed a quoting bug in mkconfig.sh.
        mkconfig enhancements and cleanup.

    1.0 (di ver 4.18)                       [29 Nov 2009]
        Initial coding
