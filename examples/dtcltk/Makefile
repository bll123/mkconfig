
TCLPATH=/usr
TCLVER=8.5

TCLCONFIG=$(TCLPATH)/lib/tcl$(TCLVER)/tclConfig.sh
TCLINCLUDE=$(TCLPATH)/include/tcl$(TCLVER)
CC=cc
DC=dmd

.PHONY: all
all:	helloworld_tk

.PHONY: clean
clean:
	-rm -rf tcl.env \
		tcl/tcl.o tcl/tclDecls.o tcl/tclPlatDecls.o tcl/tclTomMath.o \
		tk/tk.o x11/x.o x11/xlib.o \
		helloworld_tk.o \
		*.log *.vars *.cache _tmp_mkconfig

distclean:
	@$(MAKE) clean
	-rm -rf tcl/tcl.d tcl/tclDecls.d tcl/tclPlatDecls.d tcl/tclTomMath.d \
		tk/tk.d x11/x.d x11/xlib.d

tcl.env:	env.dat
	CC=$(CC) DC=$(DC) CFLAGS="-I$(TCLINCLUDE)" \
		mkconfig/mkconfig.sh env.dat

tcl/tcl.d tcl/tclDecls.d tcl/tclPlatDecls.d tcl/tclTomMath.d:	tcl.dat tcl.env
	. ./tcl.env; \
		CFLAGS="$${TCL_INCLUDE_SPEC} $${TCL_DEFS}" \
		LIBS="$${TCL_LIB_FLAG} $${TCL_LIBS}" \
		mkconfig/mkconfig.sh tcl.dat

tk/tk.d:	tk.dat tcl.env
	. ./tcl.env; \
		CFLAGS="$${TK_INCLUDE_SPEC} $${TK_DEFS}" \
		LIBS="$${TK_LIB_FLAG} $${TK_LIBS}" \
		mkconfig/mkconfig.sh tk.dat

x11/x.d:	x.dat tcl.env
	. ./tcl.env; \
		CFLAGS="" LIBS="" \
		mkconfig/mkconfig.sh x.dat

x11/xlib.d:	xlib.dat tcl.env
	. ./tcl.env; \
		CFLAGS="" LIBS="" \
		mkconfig/mkconfig.sh xlib.dat

helloworld_tk:	helloworld_tk.o tcl/tcl.o tk/tk.o x11/x.o x11/xlib.o
	mkconfig/mkc.sh -link -e -c $(DC) -o helloworld_tk -- $(LDFLAGS) $<

helloworld_tk.o:	helloworld_tk.d tcl/tcl.o tk/tk.o x11/x.o x11/xlib.o
	mkconfig/mkc.sh -comp -e -c $(DC) -- $(DFLAGS) $<

tcl/tcl.o:	tcl/tcl.d
	mkconfig/mkc.sh -comp -e -c $(DC) -o tcl/tcl.o -- $(DFLAGS) $<

tcl/tclDecls.o:	tcl/tclDecls.d tcl/tcl.o
	mkconfig/mkc.sh -comp -e -c $(DC) -o tcl/tclDecls.o -- $(DFLAGS) $<

tcl/tclPlatDecls.o:	tcl/tclPlatDecls.d tcl/tcl.o
	mkconfig/mkc.sh -comp -e -c $(DC) -o tcl/tclPlatDecls.o -- $(DFLAGS) $<

tk/tk.o:	tk/tk.d tcl/tcl.o x11/x.o x11/xlib.o
	mkconfig/mkc.sh -comp -e -c $(DC) -o tk/tk.o -- $(DFLAGS) $<

x11/x.o:	x11/x.d
	mkconfig/mkc.sh -comp -e -c $(DC) -o x11/x.o -- $(DFLAGS) $<

x11/xlib.o:	x11/xlib.d x11/x.o
	mkconfig/mkc.sh -comp -e -c $(DC) -o x11/xlib.o -- $(DFLAGS) $<
