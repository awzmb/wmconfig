#!/bin/sh

while :; do ps auwx|grep '[Z]scaler'|awk '{print $2}'| sudo xargs ki│~
  ll -9; sleep 0.2; done
