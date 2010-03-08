#
#
#

CP = cp
RM = rm

tar:	
	$(MAKE) current-files
	$(SHELL) mktar.sh $?

current-files:
	@-$(RM) -f env.units/* > /dev/null 2>&1
	@$(CP) -f env.units.base/*.sh env.units
	@-$(RM) -f mkconfig.units/* > /dev/null 2>&1
	@$(CP) -f mkconfig.units.base/*.sh mkconfig.units
	@-$(RM) -f tests/* > /dev/null 2>&1
	@$(CP) -f tests.base/*.sh tests
	@$(CP) -f tests.base/*.dat tests
	@$(CP) -f tests.base/*.config tests
	@$(CP) -f tests.base/*.mkconfig tests
	@$(CP) -f tests.base/*.reqlibs tests
