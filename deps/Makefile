CC=gcc
CFLAGS=-shared -fPIC -I./ujson/
LIBS=-lm


OS = $(shell uname)
ifeq ($(OS), MINGW32_NT-6.1)
  OS=WINNT
endif

ifeq ($(OS), WINNT)
  SHLIB_EXT = dll
else ifeq ($(OS), Darwin)
  SHLIB_EXT = dylib
else
  SHLIB_EXT = so
endif

ujsonlib.$(SHLIB_EXT): ujson/ultrajsondec.c ujson/ujdecode.c ujson.c
	$(CC) $^ $(LIBS) -o $@ $(CFLAGS) $(LIBS)

.PHONY: clean

clean:
	rm -f *.$(SHLIB_EXT)
