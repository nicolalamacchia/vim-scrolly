#!/bin/sh

VIM=${VADER_TEST_VIM:-vim}

eval "$VIM -EsNu vimrc -c 'Vader! *'"
