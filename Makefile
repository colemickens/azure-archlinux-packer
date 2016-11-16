.NOTPARALLEL:

all: build upload deploy

build upload deploy:
	$(MAKE) do WHAT=$@

do:
	(source ./user.env && ./docker-wrap.sh ./$(WHAT).sh)
