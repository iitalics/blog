
all: html css

html:
	mkdir -p output
	racket lib/sitegen.rkt

css:
	sassc lib/style.sass output/style.css

clean:
	rm -rf output

.PHONY: all html css clean
