ifeq ($(LANG),)

# Customize for Windows
# The MIPS gcc compiler must use the cygwin1.dll that came with the compiler.
CC_X86 = cl /O1 /nologo
CP = copy
RM = del
DWIN32 = -DWIN32
BIN_MIPS = ..\..\compiler
SREC_DIR = ..\..\sim\ddr_content
LINUX_PWD =
GCC_MIPS  = $(BIN_MIPS)\gcc $(CFLAGS)
AS_MIPS   = $(BIN_MIPS)\as
LD_MIPS   = $(BIN_MIPS)\ld
DUMP_MIPS = $(BIN_MIPS)\objdump
OBJCOPY   = $(BIN_MIPS)\objcopy

else

# Customized for Linux
# See http://www.opencores.com/projects.cgi/web/mips/linux_tools.htm
CP = cp
RM = rm -rf 
DWIN32 =
BIN_MIPS = 
LINUX_PWD = ./

MIPS_PRE  = mips-linux-gnu-
GCC_MIPS  = $(MIPS_PRE)gcc $(CFLAGS)
AS_MIPS   = $(MIPS_PRE)as
LD_MIPS   = $(MIPS_PRE)ld
DUMP_MIPS = $(MIPS_PRE)objdump
OBJCOPY   = $(MIPS_PRE)objcopy

endif

AFLAGS = -mcpu=r2000
CFLAGS = -O2 -Wall -c -s
CFLAGS += -fno-pic -mips1 -march=r2000 -mno-abicalls -msoft-float

all: opcodes
	
clean:
	-$(RM) *.o *.obj *.map *.lst *.hex *.txt *.exe *.axf

#mlite.exe: mlite.c
#	@$(CC_X86) -o mlite.exe mlite.c $(DWIN32)

opcodes: 
	$(AS_MIPS) $(AFLAGS) -o opcodes.o opcodes.asm
	$(LD_MIPS) -Ttext 0x10000000 -eentry -s -N -o opcodes.axf opcodes.o	
	-@$(DUMP_MIPS) --disassemble opcodes.axf > opcodes.lst
#	$(OC_MIPS) -I elf32-big -S -g --strip-unneeded -R .reginfo -O binary opcodes.axf opcodes.bin
	$(OBJCOPY) -I elf32-big -S -g --strip-unneeded -R .reginfo -O srec opcodes.axf $(SREC_DIR)/opcodes.srec
    
# Run a MIPS opcode simulator
#run: mlite.exe
#	@$(LINUX_PWD)mlite.exe test.bin 
#
#disassemble: mlite.exe
#	$(LINUX_PWD)mlite.exe test.bin BD > test.txt
