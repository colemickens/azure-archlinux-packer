.NOTPARALLEL:

all: build upload deploy

build upload deploy:
	$(MAKE) do WHAT=$@

do:
	(. ./user.env && ./docker-wrap.sh ./$(WHAT).sh)
