PROJNAME=csense

SRC=$(PROJNAME).asm
INC=

AVRDUDE_ARGS=-c dasaftdi -p t10 -P /dev/ttyUSB0
AVR_FUSE=0xff


AVRDUDE=avrdude
ASM=avra

HEX=$(PROJNAME).hex
MAP=$(PROJNAME).map
LST=$(PROJNAME).lst
EEH=$(PROJNAME).eep.hex
COF=$(PROJNAME).cof
OBJ=$(PROJNAME).obj

.SUFFIXES: .asm .obj .hex
.PHONY: writeflash clean

all: $(HEX)

hex: $(HEX)

writeflash: hex
	$(AVRDUDE) $(AVRDUDE_ARGS) -e -U flash:w:$(HEX)

install: writeflash

writefuse:
	$(AVRDUDE) $(AVRDUDE_ARGS) -e -U BYTE0:w:$(AVR_FUSE):m

$(HEX):
	$(ASM) $(INC) -l $(LST) -m $(MAP) -o $(HEX) $(SRC)

clean:
	$(RM) $(HEX) $(MAP) $(LST) $(EEH) $(COF) $(OBJ)
