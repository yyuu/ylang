#!/usr/bin/env ruby
# y/environ.rb:
#
# $Author: h202081 $
# $Id: environ.rb,v 1.1.1.1 2004/10/14 08:20:23 h202081 Exp $

class Y::Environ
  def initialize()

    @gvtab = Hash::new()

    @fstack = Array::new()
    @fstack.push(Y::Frame::new("(toplevel)"))

    @tstack = Array::new()
    @tstack.push()
  end
  def frame()
    @fstack.last()
  end
  def tag()
    @tstack.last()
  end

  def gvar_assign(gvar, object)
  end

  def gvar_varref(gvar)
    if @gvtab.has_key?(gvar)
      @gvtab[gvar]
    else
      raise(NameError::new("Y:DEBUG: undefined global variable `#{gvar}'"))
    end
  end

  def push_frame(ident)
    @fstack.push(Y::Frame::new(ident))
  end

  def pop_frame()
    @fstack.pop()
  end

  def exec_tag(context)
    @tstack.push(Y::Tag::new(context))
  end

  def jump_tag(state)
    unless tag = @tstack.pop()
      raise(RuntimeError::new("tag stack empty"))
    else
      tag.context.call(state)
    end
  end
end

class Y::Frame
  def initialize(ident)
    @ident  = ident
    @lvtab = Hash::new()
    @lvtab["self"] = Y::Object::OBJECT
  end
  attr_reader :lvtab
  def assign(ident, object)
    @lvtab[ident] = object
    object
  end
  def varref(ident)
    unless @lvtab.has_key?(ident)
      raise(NameError::new("Y:DEBUG: undefined local variable `#{ident}'"))
    else
      if (object = @lvtab[ident]).is_a?(Y::Object)
        object
      else
        Y::Object::NIL
      end
    end
  end
end

class Y::Tag
  def initialize(context)
    unless context.is_a?(Continuation)
      raise(TypeError::new("wrong argument type #{context.class} (excepted Continuation)"))
    end
    @context = context
  end
  def context()
    @context
  end
end
