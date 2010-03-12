#
#
#

CP = cp
RM = rm

clean:
	-rm -rf _tmp_mkconfig tests.done > /dev/null 2>&1

distclean:
	$(MAKE) clean

tests.done: runtests.sh
	@echo "## running mkconfig tests"
	CC=$(CC) $(_MKCONFIG_SHELL) ./runtests.sh tests
	touch tests.done

tar:
	$(MAKE) current-files
	$(SHELL) mktar.sh

current-files:
	@-$(RM) -f mkconfig.units/* > /dev/null 2>&1
	@$(CP) -f mkconfig.units.base/*.sh mkconfig.units
	@-$(RM) -rf tests/* > /dev/null 2>&1
	@$(CP) -f tests.base/*.sh tests
	@$(CP) -f tests.base/*.dat tests
	@$(CP) -f tests.base/*.config tests
	@$(CP) -f tests.base/*.mkconfig tests
	@$(CP) -f tests.base/*.reqlibs tests
