CC = gcc -c
CFLAGS = -O1 -march=pentium4 -mfpmath=sse -msse2 -ansi -Wall #-pg# -fprofile-arcs -ftest-coverage

LINKER = gcc
LFLAGS = -lm #-pg

EXE = sheet_evo
OBJS = sheet_evo.o

$(EXE): $(OBJS)
	$(LINKER) -o $(EXE) $(OBJS) $(LFLAGS) 

sheet_evo.o: sheet_evo.c
	$(CC) $(CFLAGS) sheet_evo.c

clean:
	find . \( -name '*.o' -o -name '*~' -o -name core -o -name $(EXE) \) -exec rm {} \;
