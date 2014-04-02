TARG = elegant-memoization

.PRECIOUS: %.tex %.pdf %.web

all: $(TARG).pdf

see: $(TARG).see

%.pdf: %.tex Makefile
	pdflatex $*.tex

# --poly is default for lhs2TeX

%.tex: %.lhs macros.tex mine.fmt Makefile
	lhs2TeX -o $*.tex $*.lhs

showpdf = open -a Skim.app

%.see: %.pdf
	${showpdf} $*.pdf

clean:
	rm $(TARG).{tex,pdf,aux,nav,snm,ptb}

# web: $(TARG).web

# %.web: %.pdf
# 	scp $< conal@conal.net:/home/conal/web/talks
# 	touch $@

web: web-token

# HOST = conal.net
HOST = 174.143.243.105

STASH=conal@$(HOST):/home/conal/web/talks

web: web-token

web-token: $(TARG).pdf
	scp $? $(STASH)/
	touch $@

#  $(TARG).lhs HScan.lhs
