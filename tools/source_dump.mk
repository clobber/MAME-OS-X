
osx_default:
	@echo Dummy makefile

include mame/makefile

# Using a := forces all variables and functions to be evaluated
OSX_DRVLIBS := $(DRVLIBS)
OSX_CPUOBJS := $(CPUOBJS)
OSX_DBGOBJS := $(DASMOBJS)
OSX_SOUNDOBJS := $(SOUNDOBJS)
OSX_CPUDEFS := $(CPUDEFS)
OSX_SOUNDDEFS := $(SOUNDDEFS)
