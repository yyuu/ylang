#!/usr/bin/env zsh

for f in */*.yl; do
  if diff -q "${f}" "${f}.out" &>/dev/null; then
    echo "${0}: ${f} success"
  else
    echo "${0}: ${f} failed"
    exit 1
  fi
done
