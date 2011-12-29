#!/usr/bin/env ruby
# y/all.rb:
#
# $Author: h202081 $
# $Id: all.rb,v 1.1.1.1 2004/10/14 08:20:23 h202081 Exp $

module Y

  class YError < StandardError
  end
  class ScanError < YError
  end
  class SyntaxError < YError
  end

  class << self
    def new(fname, source=nil, environ=nil)
      if source.nil?
        begin
          File::open(fname, "r") { |io|
            source = io.read()
          }
        rescue Errno::EACCES => e
          STDERR.puts("\e[0;31m#{@fname}:#{@lineno}: #{e}\e[0m")
          exit(1)
        rescue Errno::ENOENT => e
          STDERR.puts("\e[0;31m#{@fname}:#{@lineno}: #{e}\e[0m")
          exit(1)
        end
      end
   
      if environ.nil?
        environ = Y::Environ::new()
      end
   
      parser  = Y::Parser::new(source, fname)
      program = parser.program

      return program
    end
  end
end

require "y/scan"
#class Y::Scanner
#class Y::ScanData < Struct

require "y/syntax"
#class Y::Parser

require "y/semantics"
#class Y::SyntaxNode
#class Y::ProgramNode < Y::SyntaxNode
#class Y::StmtNode    < Y::SyntaxNode
#class Y::ExprNode    < Y::SyntaxNode
#class Y::IfNode      < Y::SyntaxNode
#class Y::ElseNode    < Y::SyntaxNode
#class Y::WhileNode   < Y::SyntaxNode
#class Y::DefunNode   < Y::SyntaxNode
#class Y::FuncallNode < Y::SyntaxNode
#class Y::VarrefNode  < Y::SyntaxNode
#class Y::AssignNode  < Y::SyntaxNode
#class Y::BreakNode   < Y::SyntaxNode
#class Y::RedoNode    < Y::SyntaxNode
#class Y::NextNode    < Y::SyntaxNode
#class Y::ReturnNode  < Y::SyntaxNode

require "y/environ"
#class Y::Environ
#  class Frame
#  class Tag

require "y/object"
#class Y::Object
#class Y::Function < Y::SyntaxNode
#class Y::ObjectSpace
