#!/bin/bash

[ ! -z $src_setup ] && [ $src_setup -eq 1 ] && return 0

# Setup repo and directories

[ ! -d $HOME/github ] && mkdir $HOME/github
[ ! $(which git &> /dev/null; echo $?) -eq 0 ] \
	&& echo "git missing" >&2 && return 1

if [ ! -d $HOME/github/baSHic ]; then
	cd $HOME/github
	git clone https://github.com/pllittle/baSHic.git >&2
fi

src_setup=1

###
