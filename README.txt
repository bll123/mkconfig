mkconfig - configuration tool (version 2.4)

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

See: examples/helloworld for a simple example.

Another example of mkconfig in use can be seen in the
'di' program at https://sourceforge.net/projects/diskinfo-di/
As of 2020-6-11, the 'di' program version 4.48 is using mkconfig version 2.3.

mkconfig works with most any bourne shell compatible shell.  Modern
shells that are not bourne shell compatible are:
  posh, zsh (compatibility mode).
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
      in a very long time.

