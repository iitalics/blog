
all:
	cp $(wildcard static/*.html) output
	sassc src/style.sass output/style.css
