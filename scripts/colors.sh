#!/bin/sh

[ ! -z $src_color ] && [ $src_color -eq 1 ] \
	&& return 0

#### COLORS & FONT OPTIONS ####
# 1 = bold, 4 = underline

red='\e[1;31m' 				#	Bold, Red
yellow='\e[1;33m' 		# Bold, Yellow
blue='\e[1;34m' 			# Bold, Blue
grey='\e[1;30m' 			# Bold, Grey
purple='\e[1;35m' 		# Bold, Purple
cyan='\e[1;36m' 			# Bold, Cyan
white='\e[1;37m' 			# Bold, White
orange='\e[38;5;208m' # Bold, Orange
green='\e[0;32m'			# Bold, Green
NC='\e[0m' 						# no color

BU=`tput smul`
EU=`tput rmul`

get_color(){
	local color='\e[0m'
	local input=$1
	
	if [ ! -z $input ]; then
		case $1 in
			red ) 			color='\e[1;31m';; 			# Bold, Red
			yellow )		color='\e[1;33m';; 			# Bold, Yellow, alternate is \e[38;5;11m
			blue )			color='\e[1;34m';; 			# Bold, Blue
			grey )			color='\e[1;30m';; 			# Bold, Grey
			purple )		color='\e[1;35m';; 			# Bold, Purple
			cyan )			color='\e[1;36m';; 			# Bold, Cyan
			white )			color='\e[1;37m';; 			# Bold, White
			orange ) 		color='\e[38;5;208m';; 	# Bold, Orange
			lightblue) 	color='\e[38;5;32m';;		# Ligher Blue
			* )
				echo "Not a coded color!"
				sleep 2
				return 1
				;;
		esac
	fi
	
	echo -e $color
	
}
show_color256(){
	# Source: https://misc.flogisoft.com/bash/tip_colors_and_formatting
	local fgbg color string color2
	for fgbg in 38 48; do # Foreground / Background
		for color in {0..255} ; do # Colors
			# Display the color
			printf "\e[${fgbg};5;%sm  %3s  \e[0m" $color $color >&2
			[ $((($color + 1) % 10)) == 4 ] && echo >&2
		done
		echo >&2
	done
	
	echo -ne "Input a string:\n\t> " >&2; read string
	echo -ne "Input a color as a number (e.g. Red=31,Yellow=33,Blue=34):\n\t> "; read color2
	echo -e "${string}: Default" >&2
	echo -e "\e[${color2}m${string}\e[0m: Colored" >&2
	echo -e "\e[1;${color2}m${string}\e[0m: Bold" >&2
	echo -e "\e[2;${color2}m${string}\e[0m: Dim" >&2
	echo -e "\e[3;${color2}m${string}\e[0m: Italic" >&2
	echo -e "\e[4;${color2}m${string}\e[0m: Underline" >&2
	echo -e "\e[9;${color2}m${string}\e[0m: Strikethrough" >&2
	echo -e "\e[1;4;${color2}m${string}\e[0m: Bold and Underline" >&2
	echo -e "\e[7;${color2}m${string}\e[0m: Reverse" >&2
}
color_code(){
	echo -e "${red}PENDING${NC}" >&2
	echo -e "${cyan}RUNNING${NC}" >&2
	echo -e "${white}SUBMITTING${NC}" >&2
	echo -e "${purple}RE-RUNNING${NC}" >&2
}
print_noInput(){
	local red=`get_color red`
	local NC=`get_color`
	echo -e "${red}No input, try again${NC}" >&2
	sleep 0.1s
}
print_notOpt(){
	local red NC mess
	
	while [ ! -z "$1" ]; do
		case $1 in
			-m | --mess )
				shift
				mess="$1"
				;;
		esac
		shift
	done
	
	red=`get_color red`
	NC=`get_color`
	if [ -z "$mess" ]; then
		echo -e "${red}Not an option, try again${NC}" >&2
	else
		echo -e "${red}${mess}${NC}" >&2
	fi
	
	sleep 0.1s
	
}
print_notInt(){
	local red=`get_color red`
	local NC=`get_color`
	echo -e "${red}Not an integer, try again${NC}" >&2
	sleep 0.1s
}
check_noInput(){
	if [ -z $1 ]; then
		print_noInput
		exit 1
	fi
}
make_help(){
	local help_fn func options
	local cnt usage option opt1 opt2 opt3 opt4
	
	help_fn=~/.help.txt
	cnt=0
	
	while [ ! -z "$1" ]; do
		case $1 in
			-f | --help_fn )
				shift
				help_fn="$1"
				;;
			-n | --func )
				shift
				func="$1"
				;;
			-o | --options )
				while [ ! -z "$2" ]; do
					case $2 in
						-* )
							break
							;;
						* )
							options[cnt]="$2"
							let cnt=cnt+1
							shift
							;;
					esac
				done
				;;
		esac
		shift
	done
	
	[ -f ${help_fn}2 ] && rm ${help_fn}2
	usage="${func}"
	for option in "${options[@]}"; do
		
		# get short param
		opt1="-`echo -e ${option} | cut -d '|' -f1`"
		usage="${usage} ${opt1}"
		
		# get long param
		opt2="--`echo -e ${option} | cut -d '|' -f2`"
		
		# get comment variable
		opt3=`echo -e ${option} | cut -d '|' -f3`
		usage="${usage} <${opt3}>"
		
		# get option details
		opt4=`echo -e ${option} | cut -d '|' -f4`
		
		# Append details to file
		echo -e "${opt1}, ${opt2}|${opt4}" >> ${help_fn}2
		
	done
	
	echo -e "USAGE:\n" > $help_fn
	echo -e "${usage}" | awk '{print "   "$0"\n"}' >> $help_fn
	echo -e "OPTION(S):\n" >> $help_fn
	cat ${help_fn}2 | column -o '     ' -s '|' -t \
		| awk '{print "   "$0"\n"}' >> $help_fn
	rm ${help_fn}2
	cat $help_fn >&2
	rm $help_fn
	
}
make_menu(){
	local color ex_opt base_opt 
	local prompt options option
	local cnt mytab yesno
	color=${NC}; ex_opt=0; base_opt=0; 
	cnt=0; mytab="    "; yesno=0
	
	# Set color, prompt and options
	while [ ! -z "$1" ]; do
		case $1 in
			-c | --color )
				shift
				color="$1"
				;;
			-p | --prompt )
				shift
				prompt="$1"
				;;
			-e | --ex_opt )
				ex_opt=1
				;;
			-b | --base_opt )
				base_opt=1
				;;
			-y | --yesno )
				yesno=1
				options=('1) Yes' '2) No')
				cnt=2
				;;
			-o | --options )
				while [ ! -z "$2" ]; do
					case $2 in
						-* )
							break
							;;
						* )
							options[cnt]="$2"
							let cnt=cnt+1
							shift
							;;
					esac
				done
				;;
			-h | --help )
				make_help -f help_make_menu -n make_menu \
					-o "c|color|color|Color of font" \
					"p|prompt|prompt|Menu prompt" \
					"e|ex_opt|exit_option|Include option to exit" \
					"b|base_opt|base_option|Include base options" \
					"y|yesno|yes_no|Yes/No menu" \
					"o|options|options_array|An array of menu options"
				return 0
				;;
		esac
		shift
	done
	
	# If exit or base option
	if [ $base_opt -eq 1 -o $ex_opt -eq 1 ]; then
		options[cnt]="------------"
		let cnt=cnt+1
		if [ $base_opt -eq 1 ]; then
			options[cnt]="10) Base options"
			let cnt=cnt+1
		fi
		if [ $ex_opt -eq 1 ]; then
			options[cnt]="0) Exit"
			let cnt=cnt+1
		fi
	fi
	
	# Print prompt and options
	echo -ne "${color}${prompt} \n${mytab}" >&2
	for option in "${options[@]}"; do
		echo -ne "${color}$option \n${mytab}" >&2
	done
	echo -ne "${color}> ${NC}" >&2
	
}

src_color=1

###

