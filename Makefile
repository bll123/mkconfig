#
#
#

CP = cp
RM = rm

clean:
	-rm -rf _tmp_mkconfig tests.done tests.log \
		test_tmp.log tests.d/_tmp_runtests > /dev/null 2>&1

distclean:
	$(MAKE) clean

tests.done: runtests.sh tests.d/cache.sh tests.d/include.sh \
		tests.d/multlib.sh tests.d/singlelib.sh
	@echo "## running mkconfig tests"
	CC=$(CC) $(_MKCONFIG_SHELL) ./runtests.sh tests.d
	touch tests.done

tar:
	$(SHELL) mktar.sh
