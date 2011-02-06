#
#
#

RM = rm
DC = gdc

###
#

all-test:	tests.done

# leaves _tmp_mkconfig, _mkconfig_runtests
clean:
	@-$(RM) -rf tests.done tests.d/chksh* > /dev/null 2>&1

realclean:
	@$(MAKE) clean > /dev/null 2>&1
	@-$(RM) -rf _tmp_mkconfig _mkconfig_runtests > /dev/null 2>&1

distclean:
	@$(MAKE) realclean > /dev/null 2>&1

###

tests.done: runtests.sh
	@echo "## running mkconfig tests"
	CC=$(CC) DC=$(DC) $(_MKCONFIG_SHELL) ./runtests.sh tests.d
	touch tests.done

tar:
	./mktar.sh
