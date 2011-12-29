# syntax.y: racc(1)
#
# $Author: h202081 $
# $Id: syntax.y,v 1.1.1.1 2004/10/14 08:20:23 h202081 Exp $

class Y::Parser

prechigh
  nonassoc UMINUS
  left '*' '/' '%'
  left '+' '-'
  nonassoc COMPARE
  nonassoc AND OR
  right '='
preclow

rule
  program : stmts
              {
                result = ProgramNode::new(@fname, @lineno, val[0])
              }

  stmts   :
              {
                result = []
              }
          | stmts stmt
              {
                result.push(val[1])
              }

  stmt    : RETURN opt_expr term
              {
                result = ReturnNode::new(@fname, @lineno, val[1])
              }
          | BREAK opt_expr term
              {
                result = BreakNode::new(@fname, @lineno, val[1])
              }
          | REDO term
              {
                result = RedoNode::new(@fname, @lineno)
              }
          | NEXT term
              {
                result = NextNode::new(@fname, @lineno)
              }
          | defun term
              {
                result = val[0]
              }
          | try term
          | expr term
              {
                result = val[0]
              }
          | expr IF '(' expr ')' opt_then term
              {
                result = IfNode::new(@fname, @lineno, val[3], [val[0]], nil)
              }
          | expr WHILE '(' expr ')' opt_do term
              {
                result = WhileNode::new(@fname, @lineno, val[3], [val[0]])
              }

  try     : TRY opt_term stmts opt_rescue opt_ensure END

  defun   : DEF IDENT '(' opt_params ')' opt_term stmts END
              {
                function = Function::new(val[3], val[6])
                result   = DefunNode::new(@fname, @lineno, nil, val[1].source, function)
              }
          | DEF varref '.' IDENT '(' opt_params ')' opt_term stmts END
              {
                function = Function::new(val[5], val[8])
                result   = DefunNode::new(@fname, @lineno, val[1], val[3].source, function)
              }

  expr    : expr '+' expr
              {
                result = FuncallNode::new(@fname, @lineno, val[0], val[1].source, [val[2]])
              }
          | expr '-' expr
              {
                result = FuncallNode::new(@fname, @lineno, val[0], val[1].source, [val[2]])
              }
          | expr '*' expr
              {
                result = FuncallNode::new(@fname, @lineno, val[0], val[1].source, [val[2]])
              }
          | expr '/' expr
              {
                result = FuncallNode::new(@fname, @lineno, val[0], val[1].source, [val[2]])
              }
          | expr '%' expr
              {
                result = FuncallNode::new(@fname, @lineno, val[0], val[1].source, [val[2]])
              }
          | expr COMPARE expr
              {
                result = FuncallNode::new(@fname, @lineno, val[0], val[1].source, [val[2]])
              }
          | expr AND expr
              {
                result = AndNode::new(@fname, @lineno, val[0], val[2])
              }
          | expr OR expr
              {
                result = OrNode::new(@fname, @lineno, val[0], val[2])
              }
          | NOT '(' expr ')'
              {
                result = NotNode::new(@fname, @lineno, val[2])
              }
          | primary
          | if
          | while

  if      : IF '(' expr ')' opt_term stmts opt_else END
              {
                result = IfNode::new(@fname, @lineno, val[2], val[5], val[6])
              }
          | UNLESS '(' expr ')' opt_term stmts opt_else END
              {
                expr = NotNode::new(@fname, @lineno, val[2])
                result = IfNode::new(@fname, @lineno, expr, val[5], val[6])
              }

  opt_else:
          | else

  else    : ELSE opt_term stmts
              {
                result = ElseNode::new(@fname, @lineno, val[2])
              }

  while   : WHILE '(' expr ')' opt_term stmts END
              {
                result = WhileNode::new(@fname, @lineno, val[2], val[5])
              }
          | DO opt_term stmts END WHILE '(' expr ')'
              {
                result = DoNode::new(@fname, @lineno, val[6], val[2])
              }
          | UNTIL '(' expr ')' opt_term stmts END
              {
                expr = NotNode::new(@fname, @lineno, val[2])
                result = WhileNode::new(@fname, @lineno, expr, val[5])
              }
          | DO opt_term stmts END UNTIL '(' expr ')'
              {
                expr = NotNode::new(@fname, @lineno, val[6])
                result = DoNode::new(@fname, @lineno, expr, val[2])
              }

  funcall : IDENT '(' opt_args ')' opt_block
              {
                result = FuncallNode::new(@fname, @lineno, nil, val[0].source, val[2])
              }
          | varref '.' IDENT '(' opt_args ')' opt_block
              {
                result = FuncallNode::new(@fname, @lineno, val[0], val[2].source, val[4])
              }

  primary : STRING
              {
                result = StringNode::new(@fname, @lineno, val[0].source)
              }
          | NUMBER
              {
                value = val[0].source.to_i()
                result = NumberNode::new(@fname, @lineno, value)
              }
          | '-' NUMBER =UMINUS
              {
                value = 0 - val[0].source.to_i()
                result = NumberNode::new(@fname, @lineno, value)
              }
          | '[' opt_term opt_args ']'
              {
                result = ArrayNode::new(@fname, @lineno, val[2])
              }
          | TRUE
              {
                result = LiteralNode::new(@fname, @lineno, Object::TRUE)
              }
          | FALSE
              {
                result = LiteralNode::new(@fname, @lineno, Object::FALSE)
              }
          | NIL
              {
                result = LiteralNode::new(@fname, @lineno, Object::NIL)
              }
          | '(' expr ')'
              {
                result = val[1]
              }
          | assign
          | funcall
          | varref

  varref  : IDENT
              {
                result = VarrefNode::new(@fname, @lineno, val[0].source)
              }
          | SELF
              {
                result = VarrefNode::new(@fname, @lineno, val[0].source)
              }
          | CONST
              {
                result = ConstNode::new(@fname, @lineno, val[0].source, nil)
              }
          | GVAR
              {
                result = GvarNode::new(@fname, @lineno, val[0].source, nil)
              }
          | IVAR
              {
                result = IvarNode::new(@fname, @lineno, nil, val[0].source)
              }
          | varref '.' IDENT
              {
                result = IvarNode::new(@fname, @lineno, val[0], val[2].source)
              }
          | varref '[' args ']'
              {
                result = ArefNode::new(@fname, @lineno, val[0], val[2])
              }

  assign  : IDENT '=' expr
              {
                result = AssignNode::new(@fname, @lineno, val[0].source, val[2])
              }
          | CONST '=' expr
              {
                result = AssignNode::new(@fname, @lineno, val[0].source, val[2])
              }
          | GVAR '=' expr
              {
                result = GvarNode::new(@fname, @lineno, val[0].source, val[2])
              }
          | IVAR '=' expr
              {
                result = IvarNode::new(@fname, @lineno, nil, val[0].source, val[2])
              }
          | varref '.' IDENT '=' expr
              {
                result = IvarNode::new(@fname, @lineno, val[0], val[2].source, val[4])
              }
          | varref '[' args ']' '=' expr
              {
                result = AsetNode::new(@fname, @lineno, val[0], val[2], val[5])
              }

# variable: IDENT
#             {
#               result = val[0].source
#             }
#         | CONST
#             {
#               result = val[0].source
#             }
#         | IVAR
#             {
#               result = val[0].source
#             }
#         | GVAR
#             {
#               result = val[0].source
#             }

# mlhs    : varref ','
#         | mlhs ',' varref

  rescue  : RESCUE opt_params term stmts

  opt_rescue:
          | opt_rescue rescue

  ensure  : ENSURE opt_term stmts

  opt_ensure:
          | ensure

  opt_block:
          | block

  block   : '{' opt_bparams opt_term stmts '}'

  opt_bparams:
          | '|' params '|'

  params  : IDENT
              {
                result = [val[0].source]
              }
          | params ',' opt_term IDENT
              {
                result.push(val[3].source)
              }

  opt_params:
              {
                  result = []
              }
          | params

  args    : expr
              {
                result = [val[0]]
              }
          | args ',' opt_term expr
              {
                result.push(val[3])
              }

  opt_args:
              {
                result = []
              }
          | args

  opt_expr:
              {
                result = nil
              }
          | expr

  term    : EOL
          | EOS

  opt_term:
          | term

end

----header
require "y/scan"
require "y/semantics"

----inner
  def initialize(str, fname=nil)
    @fname  = fname
    @lineno = 1

    @scanner = Scanner::new(str, fname)

    @yydebug = true

    @program = yyparse()
  end
  attr_reader :program

  def source()
    (@scanner.nil?) ? nil : (@scanner.source())
  end

  alias :yyparse :do_parse
  private :yyparse

  private
  def yylex()
    yylex = @scanner.yylex()
    token = yylex[1]
    @fname  = token.fname
    @lineno = token.lineno
    yylex
  end
  alias :next_token :yylex

  def on_error(t, val, vstack)
    super
  end

----footer
