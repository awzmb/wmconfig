#!/bin/sh
lspci -nnk | grep -iA2 net; lspci -nnk | grep -iA2 vga
