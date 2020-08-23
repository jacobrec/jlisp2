CC=gcc
CFLAGS=-g -lm

BUILDDIR=bin
SOURCEDIR=.

SOURCES = $(wildcard $(SOURCEDIR)/*.c)
OBJECTS = $(patsubst $(SOURCEDIR)/%.c, $(BUILDDIR)/%.o, $(SOURCES))

main: $(BUILDDIR)/tokens.c $(BUILDDIR) $(OBJECTS)
	$(CC) $(OBJECTS) $(CFLAGS) -o bin/$@

$(BUILDDIR)/tokens.c: $(BUILDDIR) tokens
	cat tokens | sed -z 's/\n/,/g' | sed 's/,$$/\n/' | awk '{printf "enum token {%s};", $$1}' > bin/tokens.c
	echo "" >> bin/tokens.c
	echo "char* token_to_string_array[] = {" >> bin/tokens.c
	cat tokens | sed -r 's/^(.*)$$/"\1",/g' >> bin/tokens.c
	echo "};" >> bin/tokens.c
	echo "char* token_to_string(enum token tok) { return token_to_string_array[tok]; }" >> bin/tokens.c

$(BUILDDIR):
	mkdir -p $(BUILDDIR)

$(BUILDDIR)/%.o: %.c
	$(CC) $< -c -o $@

run: main
	./bin/main

clean:
	rm -rf $(BUILDDIR)

.PHONY: run clean
