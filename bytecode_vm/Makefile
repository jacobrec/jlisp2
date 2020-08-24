CC=gcc
CFLAGS=-g -lm

BUILDDIR=bin
SOURCEDIR=.

HEADERS = $(wildcard $(SOURCEDIR)/*.h)
SOURCES = $(wildcard $(SOURCEDIR)/*.c)
OBJECTS = $(patsubst $(SOURCEDIR)/%.c, $(BUILDDIR)/%.o, $(SOURCES))

main: $(BUILDDIR)/tokens.o $(BUILDDIR) $(OBJECTS) $(HEADERS)
	$(CC) $(BUILDDIR)/tokens.o $(OBJECTS) $(CFLAGS) -o bin/$@

$(BUILDDIR)/tokens.h: $(BUILDDIR) Makefile
	cat tokens | sed -z 's/\n/,/g' | sed 's/,$$/\n/' | awk '{printf "enum token {%s};", $$1}' > bin/tokens.h
	echo "" >> bin/tokens.h
	echo "char* token_to_string(enum token tok);" >> bin/tokens.h

$(BUILDDIR)/tokens.c: $(BUILDDIR) Makefile
	echo "#include \"tokens.h\"" > bin/tokens.c
	echo "char* token_to_string_array[] = {" >> bin/tokens.c
	cat tokens | sed -r 's/^(.*)$$/"\1",/g' >> bin/tokens.c
	echo "};" >> bin/tokens.c
	echo "char* token_to_string(enum token tok) { return token_to_string_array[tok]; }" >> bin/tokens.c


$(BUILDDIR):
	mkdir -p $(BUILDDIR)

$(BUILDDIR)/tokens.o: $(BUILDDIR)/tokens.c $(BUILDDIR)/tokens.h
	$(CC) $(CFLAGS) $< -c -o $@

$(BUILDDIR)/%.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) $< -c -o $@

run: main
	./bin/main

clean:
	rm -rf $(BUILDDIR)

.PHONY: run clean
