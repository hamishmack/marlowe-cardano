#!/usr/bin/env nix-shell
#!nix-shell -i "make -f" -p gnumake curl unzip pandoc


DATE=$(shell date +"%d %B %Y")


DOCS=$(wildcard *.ipynb)

HTML=$(addsuffix .html,$(basename $(DOCS)))
PPTX=$(addsuffix .pptx,$(basename $(DOCS)))

PNGS=$(addsuffix .png,$(basename $(wildcard diagrams/*.dot)))
SVGS=$(addsuffix .svg,$(basename $(wildcard diagrams/*.dot)))

all: $(HTML)


%.md: %.ipynb %.yaml
	pandoc -f ipynb -t markdown \
	       --metadata-file=$(basename $<).yaml \
	       --metadata date="$(DATE)" \
	       -s $< -o $@
	sed -i -e '/^:::/d' $@

%.html: %.md $(PNGS)
	pandoc -f markdown -t slidy \
	       --slide-level 3 \
	       -s $< -o $@

%.pptx: %.md $(PNGS)
	pandoc -f markdown -t pptx \
	       -s $< -o $@

%.png: %.dot
	dot -Tpng -o $@ $<

%.svg: %.dot
	dot -Tsvg -o $@ $<


.PRECIOUS: %.md %.png %.svg

.SUFFIXES:

.PHONY: all
