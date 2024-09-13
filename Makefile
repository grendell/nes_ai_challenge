AS = ca65
LD = ld65
AS_FLAGS =
LD_FLAGS = -C nrom.cfg
OBJ = obj

nes_ai_challenge.nes: $(OBJ) $(OBJ)/nes_ai_challenge.o
	$(LD) $(LD_FLAGS) $(OBJ)/nes_ai_challenge.o -o nes_ai_challenge.nes

$(OBJ):
	mkdir $(OBJ)

$(OBJ)/nes_ai_challenge.o: nes_ai_challenge.s system.inc readjoy.inc nrom.cfg
	$(AS) $(AS_FLAGS) nes_ai_challenge.s -o $(OBJ)/nes_ai_challenge.o

.PHONY: clean
clean:
	rm -rf $(OBJ) nes_ai_challenge.nes