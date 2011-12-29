#!/usr/bin/env ruby
# y/object.rb:
#
# $Author: h202081 $
# $Id: object.rb,v 1.1.1.1 2004/10/14 08:20:23 h202081 Exp $

class Y::Object

  class << self
    def object?(object)
      object.is_a?(self)
    end
  end

  def initialize(proto, value=nil)
    unless proto.nil?
      unless proto.is_a?(Y::Object)
        raise(TypeError::new("wrong argument type #{proto.class} (expected Y::Object or NilClass)"))
      end

      @proto = proto
      if value.nil?
        @value = proto.value.dup()
      else
        @value = value
      end
    else
      @proto = nil
      @value = Object::new()
    end

    @ivtab = Hash::new()
    @imtab = Hash::new()
  end
  attr_accessor :value

  def true?()
    @value != nil and @value != false
  end

  def false?()
    @value == nil or @value == false
  end

  def assign(ident, object)
    unless object.is_a?(Y::Object)
      raise(TypeError::new("wrong argument type #{object.class} (excepted Y::Object)"))
    end

    @ivtab[ident] = object
  end

  def varref(ident)
    if @ivtab.has_key?(ident)
      @ivtab[ident]
    else
      if @proto.nil? # if this instance is a root object
        raise(NameError::new("undefined instance variable `#{ident}'"))
      else
        return @proto.varref(ident)
      end
    end
  end

  def defun(ident, object)
    unless object.is_a?(Y::Function)
      raise(TypeError::new("wrong argument type #{object.class} (excepted Y::Function)"))
    end

    if @imtab.has_key?(ident)
      STDERR.puts("instance method `#{ident}' defined twice")
    end

    @imtab[ident] = object
  end

  def funcall(environ, ident, args)
    if @imtab.has_key?(ident)

      object = @imtab[ident].call(environ, args)

    else
      if @proto.nil?
        raise(NameError::new("undefined instance method `#{ident}'"))
      else
        object = @proto.funcall(environ, ident, args)
      end
    end

    object
  end

end


#class Y::Function  < Y::Object
require "y/semantics"

class Y::Function < Y::SyntaxNode
  def initialize(params, defun_stmts)
    @params      = params
    @defun_stmts = defun_stmts
  end
  def call(environ, args)
    if @params.length != args.length
      raise(ArgumentError::new("wrong number of arguments (#{args.length} for #{@params.length})"))
    end

    frame = environ.frame()
    args.each_with_index() { |object, i|
      ident = @params[i]
      frame.assign(ident, object)
    }

    if (val = callcc() { |c| environ.exec_tag(c); nil }).nil?
      return eval_list(@defun_stmts, environ)
    else # function returned
      unless val.is_a?(Y::Object)
        raise("must not happen")
      end
      return val
    end
  end
end

class Y::PrimitiveFunction < Y::Object
  def initialize(params, &procedure)
    unless procedure.is_a?(Proc)
      raise(TypeError::new("wrong argument type #{procedure.class} (excepted Proc)"))
    end
    @params    = params
    @procedure = procedure
  end
  def call(environ, args)
    if @params.length != args.length
      raise(ArgumentError::new("wrong number of arguments (#{args.length} for #{@params.length})"))
    end

    frame = environ.frame()
    args.each_with_index() { |val, i|
      frame.assign(@params[i], val)
    }

    object = @procedure.call(args, environ)

  end
end

#class Y::Procedure < Y::Function
#end

class Y::ObjectSpace
  def initialize()
    @foo = Hash::new()
    @bar = Hash::new()
    @baz = Hash::new()
  end
end

class Y::Object

  OBJECT  = self::new(nil)

  TRUE    = self::new(OBJECT, true)

  FALSE   = self::new(OBJECT, false)

  NIL     = self::new(OBJECT, true)
  NIL.value = nil

  INTEGER = self::new(OBJECT, 0)

  STRING  = self::new(OBJECT, "")

  ARRAY   = self::new(OBJECT, [])

# OBJECT.assign("OBJECT",  OBJECT)
# OBJECT.assign("TRUE",    TRUE)
# OBJECT.assign("FALSE",   FALSE)
# OBJECT.assign("NIL",     NIL)
# OBJECT.assign("INTEGER", INTEGER)
# OBJECT.assign("STRING",  STRING)
# OBJECT.assign("ARRAY",   ARRAY)

end
