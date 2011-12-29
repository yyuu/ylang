#!/usr/bin/env ruby
# y/semantics.rb: class of nodes constructing syntax trees
#
# $Author: h202081 $
# $Id: semantics.rb,v 1.1.1.1 2004/10/14 08:20:23 h202081 Exp $

class Y::SyntaxNode
  def initialize(fname, lineno)
    @fname  = fname
    @lineno = lineno
  end

  alias :__eval__ :eval


  def eval(environ)
    raise("#{@fname}: #{@lineno}: should be overridden")
  end

  protected
  def true?(environ)
    not(self.false?(environ))
  end

  def false?(environ)
    value = self.eval(environ)
    value == Y::Object::FALSE or value == Y::Object::NIL
  end

# def to_object(environ)
#   node = self
#   until node.is_a?(Y::Object)
#     node = node.eval(environ)
#   end
#   node
# end

  private
  def eval_list(list, environ)
    object = Y::Object::NIL
    list.each() { |e|
      object = e.eval(environ)
      object
    }
#   Y::LiteralNode::new(@fname, @lineno, val)
    object
  end
end

class Y::ProgramNode < Y::SyntaxNode
  def initialize(fname, lineno, stmts)
    super(fname, lineno)
    @stmts = stmts
  end
  def eval(environ)
    object = eval_list(@stmts, environ)
  end
end

=begin
class Y::StmtNode < Y::SyntaxNode
  def initialize(&eval_proc)
    super("(primitive)", 0)

    @eval_proc = eval_proc
  end
  def eval(environ)
    object = @eval_proc.call(environ)
  end
end
=end

class Y::ExprNode < Y::SyntaxNode
  def initialize(fname, lineno, expr)
    super(fname, lineno)
    @expr = expr
  end
  def eval(environ)
    object = @expr.eval(environ)
  end
end

class Y::IfNode < Y::SyntaxNode
  def initialize(fname, lineno, expr, stmts, else_node)
    super(fname, lineno)
    @expr      = expr
    @stmts     = stmts
    @else_node = else_node
  end
  def eval(environ)
    object = Y::Object::NIL
    if @expr.true?(environ)
      object = eval_list(@stmts, environ)
    else
      unless @else_node.nil?
        object = @else_node.eval(environ)
      end
    end
    object
  end
end

class Y::ElseNode < Y::SyntaxNode
  def initialize(fname, lineno, stmts)
    super(fname, lineno)
    @stmts = stmts
  end
  def eval(environ)
    eval_list(@stmts, environ)
  end
end

class Y::AndNode < Y::SyntaxNode
  def initialize(fname, lineno, expr0, expr1)
    super(fname, lineno)
    @expr0 = expr0
    @expr1 = expr1
  end
  def eval(environ)
    if @expr0.true?(environ) and @expr1.true?(environ)
      Y::Object::TRUE
    else
      Y::Object::FALSE
    end
  end
end

class Y::OrNode < Y::SyntaxNode
  def initialize(fname, lineno, expr0, expr1)
    super(fname, lineno)
    @expr0 = expr0
    @expr1 = expr1
  end
  def eval(environ)
    if @expr0.true?(environ) or @expr1.true?(environ)
      Y::Object::TRUE
    else
      Y::Object::FALSE
    end
  end
end

class Y::NotNode < Y::SyntaxNode
  def initialize(fname, lineno, expr)
    super(fname, lineno)
    @expr = expr
  end
  def eval(environ)
    if @expr.true?(environ)
      Y::Object::FALSE
    else
      Y::Object::TRUE
    end
  end
end

class Y::WhileNode < Y::SyntaxNode
  def initialize(fname, lineno, expr, stmts)
    super(fname, lineno)
    @expr  = expr
    @stmts = stmts
  end
  def eval(environ)

    while @expr.true?(environ)
      if (val = callcc() { |c| environ.exec_tag(c); nil }).nil?
        eval_list(@stmts, environ)
      else
        if    val == Y::BreakNode
          break
        elsif val == Y::NextNode
          next
        elsif val == Y::RedoNode
          redo
        else
          raise("#{@fname}:#{@lineno}: must not happen")
        end
      end
    end

    object = Y::Object::NIL # while returns nil (Y::Object::NIL is the nil in the y world)
  end
end

class Y::DoNode < Y::WhileNode
  def eval(environ)

    begin
      if (val = callcc() { |c| environ.exec_tag(c); nil }).nil?
        eval_list(@stmts, environ)
      else
        if    val == Y::BreakNode
          break
        elsif val == Y::NextNode
          next
        elsif val == Y::RedoNode
          redo
        else
          raise("#{@fname}:#{@lineno}: must not happen")
        end
      end
    end while @expr.true?(environ)

    object = Y::Object::NIL
  end
end

class Y::BreakNode < Y::SyntaxNode
  def initialize(fname, lineno, expr)
    super(fname, lineno)
    @expr = expr
  end
  def eval(environ)
    environ.jump_tag(self.class)

    object = Y::Object::NIL
  end
end

class Y::NextNode < Y::SyntaxNode
  def eval(environ)
    environ.jump_tag(self.class)

    object = Y::Object::NIL
  end
end

class Y::RedoNode < Y::SyntaxNode
  def eval(environ)
    environ.jump_tag(self.class)

    object = Y::Object::NIL
  end
end

class Y::ReturnNode < Y::SyntaxNode
  def initialize(fname, lineno, expr=nil)
    super(fname, lineno)
    @expr = expr
  end
  def eval(environ)
    object = Y::Object::NIL
    unless @expr.nil?
      object = @expr.eval(environ)
    end

    environ.jump_tag(object)

    object = Y::Object::NIL
  end
end

class Y::DefunNode < Y::SyntaxNode
  def initialize(fname, lineno, this, ident, function)
    super(fname, lineno)
    @this = this || Y::VarrefNode::new(fname, lineno, "self")
    @ident    = ident
    @function = function
  end
  def eval(environ)
    recv = @this.eval(environ)
    recv.defun(@ident, @function)

    Y::Object::NIL
  end
end

class Y::FuncallNode < Y::SyntaxNode
  PRIMITIVE_PUBLIC = [
    "*", "+", "-", "/", "<", ">", "!=", "<=", "==", ">=", "<=>"
  ]
  PRIMITIVE_PRIVATE = [
    "exec", "exit", "getc", "gets", "p", "print", "printf",
    "putc", "puts", "rand", "readline", "sleep", "sprintf",
    "system"
  ]

  def initialize(fname, lineno, object, ident, args)

    super(fname, lineno)
    @object = object || Y::LiteralNode::new(fname, lineno, Y::Object::OBJECT)

    @ident  = ident
    @args   = args

    @recv   = Object::new()
  end
  def eval(environ)
    object = Y::Object::NIL

    primitive_public  = PRIMITIVE_PUBLIC.index(@ident)
    primitive_private = PRIMITIVE_PRIVATE.index(@ident)

    if primitive = (primitive_public or primitive_private)
      ruby_args = @args.collect() { |e|
        y_object = e.eval(environ)
        ruby_object = y_object.value
      }
    end

    object = Y::Object::NIL
    if primitive

      if   primitive_public
        recv = @object.eval(environ).value
        ruby_value =  recv.__send__(@ident, *ruby_args)
      elsif primitive_private
        ruby_value = @recv.__send__(@ident, *ruby_args)
      else

        raise("must not happen")
      end

      case ruby_value
      when Array
        object = Y::Object::new(Y::Object::ARRAY, ruby_value)
      when FalseClass
        object = Y::Object::FALSE
      when Integer
        object = Y::Object::new(Y::Object::INTEGER, ruby_value)
      when NilClass
        object = Y::Object::NIL
      when String
        object = Y::Object::new(Y::Object::STRING, ruby_value)
      when TrueClass
        object = Y::Object::TRUE
      else
        raise(TypeError::new("unknown class of ruby object (#{ruby_value.class})"))
      end
    else

      args = @args.collect() { |expr|
        expr.eval(environ)
      }

      environ.push_frame(@ident)

      recv = @object.eval(environ)
#     begin
        object = recv.funcall(environ, @ident, args)
#     rescue StandardError => e
#       STDERR.puts("\e[0;31m#{@fname}:#{@lineno}: #{e}\e[0m")
#       exit(1)
#     end

      environ.pop_frame()

    end

    object
  end
end

class Y::LiteralNode < Y::SyntaxNode
  def initialize(fname, lineno, value)
    super(fname, lineno)
    @value = value
  end
  def eval(environ)
    Y::Object::new(Y::Object::OBJECT, @value)
  end
end

class Y::StringNode < Y::LiteralNode
  def eval(environ)
    value = __eval__(@value)
    Y::Object::new(Y::Object::STRING, value)
  end
end

class Y::NumberNode < Y::LiteralNode
  def eval(environ)
    Y::Object::new(Y::Object::INTEGER, @value)
  end
end

class Y::ArrayNode < Y::LiteralNode
  def eval(environ)
    value = @value.collect() { |e|
      e.eval(environ)
    }
    Y::Object::new(Y::Object::ARRAY, value)
  end
end

#class Y::VarrefNode < Y::SyntaxNode
#  def initialize(fname, lineno, object, var)
#    super(fname, lineno)
##   @object = object || Y::LiteralNode::new(fname, lineno, Y::Object::OBJECT)
#    @object = object
#    @var    = var
#  end
## def eval(environ)
##   frame = environ.frame()
##   recv = @object.eval(environ)
##   object = recv.varref(@ident)
##   object
## end
#end
#
#class Y::AssignNode < Y::SyntaxNode
## def initialize(fname, lineno, object, ident, expr)
##   super(fname, lineno)
##   @object = object || Y::LiteralNode::new(fname, lineno, Y::Object::OBJECT)
#
##   @ident = ident
##   @expr  = expr
## end
## def eval(environ)
##   recv = @object.eval(environ)
##   object = recv.assign(@ident, @expr.eval(environ))
##   object
## end
#end

class Y::GvarNode < Y::SyntaxNode
  def initialize(fname, lineno, gvar, expr=nil)
    super(fname, lineno)
    @gvar = gvar
    @expr = expr
  end
  def eval(environ)
    unless @expr.nil?
      object = environ.gvar_assign(@gvar, @expr.eval(environ))
#STDERR.puts("DEBUG: global variable `#{@gvar}' is assigned with #{object.value.inspect()}")
    else
      object = environ.gvar_varref(@gvar)
    end
    object
  end
end

class Y::IvarNode < Y::SyntaxNode
  def initialize(fname, lineno, this, ivar, expr=nil)
    super(fname, lineno)
    @this = this || VarrefNode::new(@fname, @lineno, "self")
    @ivar = ident
    @expr = expr
  end
  def eval(environ)
    unless @expr.nil?
      object = @expr.eval(environ)
      @this.assign(@ivar, object)
#STDERR.puts("DEBUG: instance variable `#{@ivar}' is assigned with #{object.value.inspect()}")
    else
      object = @this.varref(@ivar)
    end
    object
  end
end

class Y::VarrefNode < Y::SyntaxNode
  def initialize(fname, lineno, ident)
    super(fname, lineno)
    @ident = ident
  end
  def eval(environ)
    frame = environ.frame()
    object = frame.varref(@ident)
  end
end

class Y::AssignNode < Y::SyntaxNode
  def initialize(fname, lineno, ident, expr)
    super(fname, lineno)
    @ident = ident
    @expr  = expr
  end
  def eval(environ)
    frame = environ.frame()
    object = @expr.eval(environ)
    frame.assign(@ident, object)
#STDERR.puts("DEBUG: local variable `#{@ident}' is assigned with #{object.value.inspect()}")
    object
  end
end

class Y::ArefNode < Y::SyntaxNode
  def initialize(fname, lineno, varref, args)
    raise("not implemented")
  end
end

class Y::AstfNode < Y::SyntaxNode
  def initialize(fname, lineno, varref, args, expr)
    raise("not implemented")
  end
end

class Y::ConstNode < Y::SyntaxNode
  def initialize(fname, lineno, const, expr)
    raise("not implemented")
  end
end
