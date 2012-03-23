###########################################################################
#
#   osx_tiny.mak
#
#   Small driver-specific example makefile
#	Use make TARGET=tiny to build
#
#   Copyright (c) 1996-2006, Nicola Salmoria and the MAME Team.
#   Visit http://mamedev.org for licensing and usage restrictions.
#
###########################################################################


MAMESRC = $(SRC)/mame
MAMEOBJ = $(OBJ)/mame
EMUOBJ = $(OBJ)/emu

AUDIO = $(MAMEOBJ)/audio
DRIVERS = $(MAMEOBJ)/drivers
LAYOUT = $(MAMEOBJ)/layout
MACHINE = $(MAMEOBJ)/machine
VIDEO = $(MAMEOBJ)/video
EMUMACHINE = $(EMUOBJ)/machine

OBJDIRS += \
        $(AUDIO) \
        $(DRIVERS) \
        $(LAYOUT) \
        $(MACHINE) \
        $(VIDEO) \

#-------------------------------------------------
# tiny.c contains the list of drivers
#-------------------------------------------------

COREOBJS += $(OBJ)/tiny.o



#-------------------------------------------------
# You need to define two strings:
#
#	TINY_NAME is a comma-separated list of driver
#	names that will be referenced.
#
#	TINY_DRIVER should be the same list but with
#	an & in front of each name.
#-------------------------------------------------

OSX_DRIVERS = suprmrio mspacman pacman puckman argus crysbios crysking

COREDEFS += -DTINY_NAME="driver_robby,driver_gridlee,driver_polyplay,driver_alienar"
COREDEFS += -DTINY_POINTER="&driver_robby,&driver_gridlee,&driver_polyplay,&driver_alienar"



#-------------------------------------------------
# Specify all the CPU cores necessary for these
# drivers.
#-------------------------------------------------

CPUS += Z80
CPUS += M6502
CPUS += N2A03
# FOr crysking:
CPUS += SE3208


#-------------------------------------------------
# Specify all the sound cores necessary for these
# drivers.
#-------------------------------------------------

SOUNDS += DAC
SOUNDS += NES
SOUNDS += NAMCO
SOUNDS += SN76496
SOUNDS += AY8910
# For argus:
SOUNDS += YM2203
# For crysking:
SOUNDS += VRENDER0


#-------------------------------------------------
# This is the list of files that are necessary
# for building all of the drivers referenced
# above.
#-------------------------------------------------

DRVLIBS = \
  $(VIDEO)/vsnes.o \
  $(VIDEO)/vrender0.o \
  $(VIDEO)/argus.o \
  $(VIDEO)/ppu2c0x.o \
  $(VIDEO)/pacman.o \
  $(MACHINE)/pacplus.o \
  $(MACHINE)/vsnes.o \
  $(MACHINE)/acitya.o \
  $(MACHINE)/theglobp.o \
  $(MACHINE)/mspacman.o \
  $(MACHINE)/jumpshot.o \
  $(MACHINE)/segacrpt.o \
  $(DRIVERS)/pacman.o \
  $(DRIVERS)/jrpacman.o \
  $(DRIVERS)/pengo.o \
  $(DRIVERS)/vsnes.o \
  $(DRIVERS)/crystal.o \
  $(DRIVERS)/argus.o
