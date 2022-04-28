#!/bin/sh

smart_progress(){
	local cnt tot iter job_status string iter2
	local mult
	
	while [ ! -z "$1" ]; do
		case $1 in
			-c | --cnt )
				shift
				cnt="$1"
				;;
			-t | --tot )
				shift
				tot="$1"
				;;
			-j | --iter )
				shift
				iter="$1"
				;;
			-m | --mult )
				shift
				mult="$1"
				;;
			-r | --string )
				shift
				string="$1"
				;;
			-s | --job_status )
				shift
				job_status="$1"
				;;
		esac
		shift
	done
	
	[ -z $cnt ] 				&& echo "Add -c <iteration cnt>" >&2 && return 1
	[ -z $iter ] 				&& echo "Add -j <iter to print>" >&2 && return 1
	[ -z $tot ] 				&& echo "Add -t <total iterations>" >&2 && return 1
	[ -z $job_status ] 	&& echo "Add -s <job_status>" >&2 && return 1
	[ -z $mult ] 				&& mult=1
	iter2=$((iter * mult))
	
	if [ -z "$string" ]; then
		string="."
	else
		string="$string "
	fi
	
	if [ "$job_status" == "incomplete" ]; then
		echo -ne "${white}$string${NC}" >&2
	elif [ "$job_status" == "notdone" ]; then
		echo -ne "${red}$string${NC}" >&2
	elif check_array $job_status running pending; then
		echo -ne "${cyan}$string${NC}" >&2
	elif [ "$job_status" == "complete" ]; then
		echo -ne "$string" >&2
	else
		echo -ne "${yellow}$string${NC}" >&2
	fi
	
	[ $((cnt % iter)) -eq 0 -o $cnt -eq $tot ] \
		&& echo -ne "$cnt out of $tot " >&2
	[ $((cnt % iter2)) -eq 0 -o $cnt -eq $tot ] \
		&& echo -ne "\n" >&2
	
}

###

