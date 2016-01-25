CC = gcc -c
ARCHFLAGS = -march=pentium4 -mfpmath=sse -msse2
CFLAGS = -ansi -Wall -O2 $(ARCHFLAGS) #-pg # -DHAVE_INLINE

LINKER = gcc
LFLAGS = -lm -lgsl -L/usr/lib/sse2 -lcblas #-pg

EXE = 3dtx
OBJS = 3dtx.o matvec.o fields.o

$(EXE): $(OBJS)
	$(LINKER) $(LFLAGS) -o $(EXE) $(OBJS)

3dtx.o: 3dtx.c matvec.h fields.h
	$(CC) $(CFLAGS) 3dtx.c

matvec.o: matvec.c
	$(CC) $(CFLAGS) matvec.c

fields.o: fields.c fields.h matvec.h
	$(CC) $(CFLAGS) fields.c

clean:
	find . \( -name '*.o' -o -name '*~' -o -name core -o -name $(EXE) \) -exec rm {} \;
