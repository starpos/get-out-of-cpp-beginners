.PHONY: clean

FILES_MD = $(shell cat chapters-md.list)
FILES_BOOK = $(shell cat chapters-book.list)
FILES_RE = review/chapters.re review/introduction.re review/conclusion_plus.re

out.md: $(FILES_MD)
	cat $(FILES_MD) > $@

chapters.md: $(FILES_BOOK)
	cat $(FILES_BOOK) > $@

conclusion_plus.md: conclusion.md acknowledgement.md author.md copyright.md history.md
	cat conclusion.md > $@
	cat acknowledgement.md |sed 's/##/###/g' >> $@
	cat author.md |sed 's/##/###/g' >> $@
	cat copyright.md |sed 's/##/###/g' >> $@
	cat history.md |sed 's/##/###/g' >> $@

review/%.re: %.md
	md2review --render-header-offset=1 --render-link-in-footnote $< > $@

review/book.pdf: $(FILES_RE) review/config.yml
	cd review && rake pdf

clean:
	rm -f review/book.pdf chapters.md conclusion_plus.md out.md review/*.re
