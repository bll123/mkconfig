#
#
#

CP = cp
RM = rm

current-files:
	-$(RM) -rf env.units
	mkdir env.units;chmod 755 env.units
	-$(CP) -f env.units.base/* env.units > /dev/null 2>&1
	-$(RM) -rf mkconfig.units
	mkdir mkconfig.units;chmod 755 mkconfig.units
	-$(CP) -f mkconfig.units.base/* mkconfig.units > /dev/null 2>&1
	-$(RM) -rf tests
	mkdir tests;chmod 755 tests
	-$(CP) -f tests.base/* tests > /dev/null 2>&1
