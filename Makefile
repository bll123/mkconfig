#
#
#

RM = rm

# leaves _tmp_mkconfig, _mkconfig_runtests
clean:
	@-$(RM) -rf tests.done tests.d/chksh* > /dev/null 2>&1

realclean:
	@$(MAKE) clean
	@-$(RM) -rf _tmp_mkconfig _mkconfig_runtests > /dev/null 2>&1

distclean:
	@$(MAKE) realclean

###

tests.done: runtests.sh tests.d/cache.sh tests.d/include.sh \
		tests.d/multlib.sh tests.d/singlelib.sh
	@echo "## running mkconfig tests"
	CC=$(CC) $(_MKCONFIG_SHELL) ./runtests.sh tests.d
	touch tests.done

tar:
	./mktar.sh
