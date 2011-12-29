#!/usr/bin/env ruby
# main.rb: main()
#
# $Author: h202081 $
# $Id: y.rb,v 1.1.1.1 2004/10/14 08:20:23 h202081 Exp $

require "getoptlong"
require "y/all"

EXIT_SUCCESS = 0
EXIT_FAILURE = 1

option = Hash::new()
parser = GetoptLong::new()
parser.set_options(
  ["--check",   "-c", GetoptLong::NO_ARGUMENT],
  ["--help",          GetoptLong::NO_ARGUMENT],
  ["--verbose", "-v", GetoptLong::NO_ARGUMENT],
  ["--version",       GetoptLong::NO_ARGUMENT],
  ["--eval",    "-e", GetoptLong::REQUIRED_ARGUMENT],
  ["--require", "-r", GetoptLong::REQUIRED_ARGUMENT]
)

begin
  parser.each_option { |k, v|
    k = k.sub(/^-+/, "")
    option[k] = v
  }
rescue GetoptLong::AmbigousOption,  GetoptLong::InvalidOption,
       GetoptLong::MissingArgument, GetoptLong::NeedlessArgument
  exit(EXIT_FAILURE)
end
parser = nil

if option.has_key?("help")
  STDOUT.puts(<<-"E")
help!
  E
end

if option.has_key?("version")
  STDOUT.puts(<<-"E")
version!
  E
end

environ = Y::Environ::new()

if option.has_key?("require")
  library = Y::new(option["require"], nil, environ)
  begin
    library.eval(environ)
  rescue Racc::ParseError, Y::ScanError => e
    p(e)
    exit(EXIT_FAILURE)
  end
end


source = nil
if option.has_key?("eval")
  fname  = "-e"
  source = option["eval"]
else
  unless fname = ARGV.shift()
    fname  = "-"
    source = STDIN.read()
  end
end

begin
  program = Y::new(fname, source, environ)
rescue Racc::ParseError, Y::ScanError => e
  p(e)
  exit(EXIT_FAILURE)
end

unless option.has_key?("check")
  program.eval(environ)
else
  STDOUT.puts("Syntax OK")
end

exit(EXIT_SUCCESS)
