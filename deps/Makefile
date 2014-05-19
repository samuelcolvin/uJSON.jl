CC=gcc
CFLAGS=-shared -fPIC -I./ujson/
LIBS=-lm

ujsonlib.so: ujson/ultrajsondec.c ujson/ujdecode.c ujson.c
	$(CC) $^ $(LIBS) -o $@ $(CFLAGS) $(LIBS)

.PHONY: clean

clean:
	rm -f *.so