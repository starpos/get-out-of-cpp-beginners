.PHONY: clean

FILES_MD = $(shell cat chapters-md.list)
FILES_BOOK = $(shell cat chapters-book.list)

out.md: $(FILES_MD)
	cat $(FILES_MD) > $@

out-book.md: $(FILES_BOOK)
	cat $(FILES_BOOK) > $@

review/book.pdf: out-book.md review/config.yml
	md2review --render-header-offset=1 --render-link-in-footnote out-book.md > review/src.re
	cd review && rake pdf

clean:
	rm -f review/book.pdf out-book.md out.md
