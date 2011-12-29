
SYNTAX    = y/syntax.rb
SEMANTICS = y/semantics.rb

PARSER    = syntax.y
SCANNER   = y/scan.rb

SOURCE    = src

MAIN      = ./y.rb
TEST      = ./tests

YACC      = /usr/bin/racc
RUBY      = /usr/bin/ruby

${MAIN}: ${SYNTAX} ${SEMANTICS}

.PHONY: ${SYNTAX} debug

${SYNTAX}: ${YACC} ${PARSER}
	${YACC} -o ${SYNTAX} ${PARSER}

debug: ${YACC} ${PARSER}
	${YACC} -o ${SYNTAX} ${PARSER} -g -v

#test: ${RUBY} ${MAIN} ${TEST}
#	chmod 755 ${MAIN}
#	zsh -c "for f in ${TEST}/*.mo; do \
#		diff -u <(${MAIN} $${f}) $${f}.out; \
#	done"
