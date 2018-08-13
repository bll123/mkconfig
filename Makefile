#
#
#

RM = rm
DC = gdc
SHELL = /bin/sh

###
#

.PHONY: test
test:	tests.done

# leaves _tmp_mkconfig, _mkconfig_runtests, checktests
.PHONY: clean
clean:
	@-$(RM) -rf tests.done tests.d/chksh* tests.d/c.d/chksh* \
		tests.d/d.d/chksh* mkconfig.cache mkconfig.log \
		mkc*.vars *~ */*~ */*/*~ \
		*.orig */*.orig > /dev/null 2>&1

.PHONY: realclean
realclean:
	@$(MAKE) clean > /dev/null 2>&1
	@-$(RM) -rf checktests _tmp_mkconfig _mkconfig_runtests \
		> /dev/null 2>&1

.PHONY: distclean
distclean:
	@$(MAKE) realclean > /dev/null 2>&1

###

checktests:
	$(_MKCONFIG_SHELL) ./mkconfig.sh features/checktests.dat
	touch checktests

tests.done: runtests.sh
	@echo "## running mkconfig tests"
	CC=$(CC) DC=$(DC) $(_MKCONFIG_SHELL) ./runtests.sh tests.d
	touch tests.done

.PHONY: tar
tar:
	./util/mktar.sh
.PHONY: alltar
alltar:
	$(MAKE) distclean
	tar -c -z --exclude=*.gz --exclude=Archive --exclude=TODO \
		-f mkconfig.tar.gz *
