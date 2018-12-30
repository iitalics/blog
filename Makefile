
all:
	racket lib/sitegen.rkt
	sassc src/style.sass output/style.css
