#!/usr/bin/env ruby
# y/scan.rb: scanner library
#
# $Author: h202081 $
# $Id: scan.rb,v 1.1.1.1 2004/10/14 08:20:23 h202081 Exp $

if $0 == __FILE__

  module Y
  end

end

require "strscan"

Y::ScanData = Struct::new(:source, :fname, :lineno)

class Y::Scanner

  PATTERN = [
    [/\A[\t\r ]+/,                     :SKIP],
    [/\A(?:\\\r?\n)+/,                 :SKIP],

    [/\A=begin.*\n(?:.*\n)*=end.*\n/,  :COMMENT],
    [/\A(?:[\t ]*\#.*\n)+/,            :COMMENT],
    [/\A(?:\r?\n)+/,                   :EOL],
    [/\A;+/,                           :EOS],

#   [/\A<<[A-Z]+/,                     :HEREDOC],

    [/\A[A-Z][\d\w]*/,                 :CONST],
    [/\A\$\w[\d\w]*/,                  :GVAR],
    [/\A@[\d\w]+/,                     :IVAR],
    [/\A[_a-z][\d\w]*/,                :IDENT],

    [/\A\d+/,                          :NUMBER],
#   [/\A"(?:\\(?!")|.)*?"/,            :STRING],
#   [/\A"(?:[^"\\]+|\\.)*"/,           :STRING],
    [/\A"(?:[^"\\]+|\\\r?\n|\\.)*"/,   :STRING],

    [/\A(?:<=>|[<=>]=)/,               :COMPARE],


    [/\A[^\s]/,                        nil]
  ]

  RESERVED = {
    "and"    => :AND,
    "break"  => :BREAK,
    "case"   => :CASE,
    "def"    => :DEF,
    "do"     => :DO,
    "else"   => :ELSE,
    "elsif"  => :ELSIF,
    "end"    => :END,
    "ensure" => :ENSURE,
    "false"  => :FALSE,
    "if"     => :IF,
    "next"   => :NEXT,
    "nil"    => :NIL,
    "not"    => :NOT,
    "or"     => :OR,
    "redo"   => :REDO,
    "rescue" => :RESCUE,
    "return" => :RETURN,
    "self"   => :SELF,
#   "then"   => :THEN,
    "true"   => :TRUE,
    "try"    => :TRY,
    "unless" => :UNLESS,
    "until"  => :UNTIL,
    "when"   => :WHEN,
    "while"  => :WHILE
  }


  def initialize(str, fname=nil)
    @strscan = StringScanner::new(str)

    @skip_head = true  # if this scan is the first time
                       ## to skip comments or EOLs in start of file
    @last_term = false # if last symbol is a :EOL or :EOS

    @heredoc   = nil

    @fname  = fname
    @lineno = 1
  end

  def source()
    (@strscan.nil?) ? nil : (@strscan.string())
  end

  def yylex()
    token = scan()
    unless token.nil?
      return token
    else
      if @strscan.eos?
        return [false, Y::ScanData::new(nil, @fname, @lineno)]
      else
        raise(Y::ScanError::new("error occurred during scanning source"))
      end
    end
  end
  alias :next_token :yylex

  def each_token()
    begin
      token = yylex()
      ts    = token[0]
      yield(token)
    end while ts
  end
  alias :each :each_token

  private
  def open(fname)
    begin
      File::open(fname, "r") { |io|
        str = io.read()
      }
    rescue Errno::EACCES => e
      STDERR.puts("\e[0;31m#{fname}: #{e}\e[0m")
      exit(1)
    rescue Errno::ENOENT => e
      STDERR.puts("\e[0;31m#{fname}: #{e}\e[0m")
      exit(1)
    end
    str
  end

  def scan()

    until @strscan.eos?

      @strscan.skip(/\A[\t\r ]+/) # skip leading white spaces

      PATTERN.each() { |re, ts|

        if val = @strscan.scan(re)

          case ts
          when :COMMENT then
            @lineno += val.count("\n")

            if @last_term or @skip_head
              break
            else
              @last_term = true
              val = [:EOL, Y::ScanData::new("\n", @fname, @lineno)]
              return val
            end

#         when :HEREDOC then
#
#           @heredoc = /\A<<([A-Z]+)/ =~ val
#
#           raise("here documents have not implemented yet")
#
          when :SKIP    then
            @lineno += val.count("\n")
            break

          else
            if str = (ts == :STRING)
              val = val.gsub(/\\(\r?\n)/) { $1 }
            end

            if str or eol = (ts == :EOL)
              @lineno += val.count("\n")
            end

            val = [(RESERVED[val] || ts || val), Y::ScanData::new(val, @fname, @lineno)]

            if eol or eos = (ts == :EOS)
              if @last_term or @skip_head
                break
              else
                @skip_head = false
                @last_term = true
                return val
              end
            else
              @skip_head = false
              @last_term = false
              return val
            end

          end
        end
      }

    end

    nil

  end
end

if $0 == __FILE__

  scanner = Y::Scanner::new(ARGF.read(), "-")
  scanner.each() { |ts, val|
    STDERR.printf("%4d %10s - %s\n", val.lineno, ts.inspect(), val.source.inspect())
  }

end
