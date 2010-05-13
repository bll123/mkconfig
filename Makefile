#
#
#

CP = cp
RM = rm

clean:
	-rm -rf tests.done > /dev/null 2>&1

distclean:
	$(MAKE) clean

realclean:
	$(MAKE) distclean
	-rm -rf _tmp_mkconfig _mkconfig_runtests > /dev/null 2>&1

tests.done: runtests.sh tests.d/cache.sh tests.d/include.sh \
		tests.d/multlib.sh tests.d/singlelib.sh
	@echo "## running mkconfig tests"
	CC=$(CC) $(_MKCONFIG_SHELL) ./runtests.sh tests.d
	touch tests.done

tar:
	$(SHELL) mktar.sh
