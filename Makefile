
JQ_FILES=$(wildcard src/*.jq)
JQ_FILES_TEST=$(patsubst %.jq,%.test,${JQ_FILES})

test: ${JQ_FILES_TEST}

install:
	@if [ -e ~/.jq -a ! -h ~/.jq ]; then \
		echo "Failed to install as ~/.jq already exist and is a regular file"; \
		exit 1; \
	fi
	@if [ ! -e ~/.jq -o "$$(readlink ~/.jq)" != "${PWD}/.jq" ]; then \
		echo "Installing ~/.jq symlink"; \
		ln -fs "${PWD}/.jq" ~/.jq; \
	fi

	@echo "Rebuilding .jq"
	@cat ${JQ_FILES} > .jq

# prepend include statement(s) before test expression to so that the functions will
# be available in the tests
%.test: %.jq
	@printf "Tests for %s:\n" $<
	@jq --arg includes "$<" -rRs 'include "make"; from_defs | to_test' $< | \
		HOME=${TMP_HOME} jq --run-tests
	@printf '\n'

.PHONY: README.md
README.md: make.jq ${JQ_FILES}
	@sed '/^## Functions/q' README.md > README.md.tmp
	@jq -rRs -L .. 'include "make"; [from_defs] | to_markdown' ${JQ_FILES} >> README.md.tmp
	@sed -ne '/^## Development/,$$ p' README.md >> README.md.tmp
	@mv README.md.tmp README.md

