#!/bin/bash

[ ! -z "$paul_dir" ] && return 0

[ -z "$git_dir" ] && git_dir=$(cd $(dirname $BASH_SOURCE)/../..; pwd)

for fn in getEnv; do
	. "$git_dir/baSHic/scripts/$fn.sh"
	[ $? -eq 0 ] && continue
	echo -e "Error src-ing baSHic's $fn.sh" >&2
	return 1
done

get_paul_dir(){
	local paul_dir
	
	if [ "$curr_host" == "longleaf" ]; then
		paul_dir=/work/users/p/l/pllittle
	elif [ "$curr_host" == "dogwood" ]; then
		paul_dir=/21dayscratch/scr/p/l/pllittle
	elif [ "$curr_host" == "diamond" ]; then
		paul_dir=/home/users/pllittle
	elif [ "$curr_host" == "bioinf" ]; then
		# paul_dir=/datastore/nextgenout2/share/labs/OGR/Collaborators/pllittle
		paul_dir=/datastore/scratch/users/pllittle
	elif [ "$curr_host" == "killdevil" ]; then
		paul_dir=/lustre/scr/p/l/pllittle
	elif [ "$curr_host" == "hutch" ]; then
		paul_dir=/fh/scratch/delete90/sun_w/plittle
	elif check_array $curr_host uthsc_compute uthsc; then
		paul_dir=/scratch/primary/UTHSC/Current_members/Paul_Little
	else
		print_notOpt
		exit 0
	fi
	
	if [ -d $paul_dir ]; then
		echo $paul_dir
	else
		echo -ne "paul_dir doesn't exist!" >&2
		sleep 1
		exit 1
	fi
	
}
paul_dir=$(get_paul_dir)

###
