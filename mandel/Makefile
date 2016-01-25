CC	= gcc
SRGPDIR = /usr/X11R6
CFLAGS  = -I$(SRGPDIR)/include -Wall -ansi -pedantic
LDFLAGS	= -L$(SRGPDIR)/lib -lsrgp -lX11 -lm
OBJS	= main.o calc.o graph.o
EXE	= mandel
RM	= /bin/rm -f

$(EXE):	$(OBJS)
	$(CC) $(OBJS) -o $(EXE)  $(LDFLAGS)

main.o:	main.c calc.h graph.h
	$(CC) $(CFLAGS) -c main.c

calc.o: calc.c calc.h
	$(CC) $(CFLAGS) -c calc.c

graph.o:graph.c calc.h
	$(CC) $(CFLAGS) -c graph.c


clean:
	$(RM) $(OBJS) *~
