.POSIX:
.SUFFIXES:
.PHONY: check

all: check

check:
	-shellcheck -s sh -x shite
	-shellcheck -s sh -x index.sh
	-shellcheck -s sh -x rss.sh
