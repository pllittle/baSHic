#!/bin/sh

[ ! -z $src_setup ] && [ $src_setup -eq 1 ] && return 0

# Setup repo and directories
git_dir=$HOME/github

[ ! -d $git_dir ] && mkdir $git_dir
[ ! $(which git &> /dev/null; echo $?) -eq 0 ] \
	&& echo "git missing" >&2 && return 1

if [ ! -d $git_dir/baSHic ]; then
	cd $git_dir
	git clone https://github.com/pllittle/baSHic.git >&2
fi

src_setup=1

###
