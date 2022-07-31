#!/bin/sh

[ ! -z $src_latex ] && [ $src_latex -eq 1 ] && return 0

[ -z "$git_dir" ] && git_dir=$(cd $(dirname $BASH_SOURCE)/../..; pwd)

for fn in install linux_perl; do
	. $git_dir/baSHic/scripts/$fn.sh
done

install_tex(){
	# echo "check this!" >&2 && return 1
	local version v1 apps_dir url inst_dir work_dir
	local curr_date curr_yr resp load_env
	
	load_env=0
	while [ ! -z $1 ]; do
		case $1 in
			-v | --version )
				shift
				version="$1"
				;;
			-a | --apps_dir )
				shift
				apps_dir="$1"
				;;
			-e | --load_env )
				load_env=1
				;;
		esac
		shift
	done
	
	[ -z $apps_dir ] && apps_dir=$HOME/apps
	work_dir=$apps_dir/downloads
	curr_yr=$(date +%Y)
	inst_dir=$apps_dir/texlive
	if [ ! -d $inst_dir/$curr_yr ]; then
		[ ! $(ls $inst_dir | grep -v "texmf" | wc -l) -eq 0 ] \
			&& curr_yr=$(ls $inst_dir | grep -v "texmf" | sort -n | tail -n 1)
	fi
	url=http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
	
	# Load environment
	if [ $load_env -eq 1 ]; then
		[ ! -f $inst_dir/$curr_yr/bin/x86_64-linux/pdftex ] \
			&& echo -e "${red}Latex year missing${NC}" >&2 && return 1
		echo -e "Loading texlive environment ..." >&2
		update_env -e PATH -a "$inst_dir/$curr_yr/bin/x86_64-linux"
		update_env -e MANPATH -a "$inst_dir/$curr_yr/texmf-dist/doc/man"
		export INFOPATH=$inst_dir/$curr_yr/texmf-dist/doc/info
		return 0
	fi
	
	if [ -d $inst_dir/$curr_yr ]; then
		make_menu -y -p "Re-install texlive/$curr_yr?"
		read resp
		if [ -z $resp ]; then
			print_noInput
			return 1
		elif [ $resp -eq 1 ]; then
			rm -rf $inst_dir
		else
			return 0
		fi
	fi
	
	# Set environment
	clear_env
	local CPPFLAGS LDFLAGS; # CPPFLAGS=; LDFLAGS=;
	cmd=$(prep_env_cmd -a $apps_dir -p gcc libtool perl)
	eval $cmd >&2 || return 1
	
	new_mkdir $work_dir
	cd $work_dir
	[ ! -f install-tl-unx.tar.gz ] && wget $url >&2
	tar -zxvf install-tl-unx.tar.gz >&2
	curr_date=$(ls | grep -v "tar.gz" | grep "install-tl" | cut -d '-' -f3)
	cd install-tl-$curr_date/
	echo -e "Notes:\n\t1) Install everything \n\t2) Set TEXDIR to $inst_dir/$curr_yr" >&2
	sleep 2
	perl install-tl >&2
	cd $work_dir
	rm -rf install-tl-unx.tar.gz install-tl-$curr_date
	
}


src_latex=1

###

