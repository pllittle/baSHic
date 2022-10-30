#!/bin/sh

[ ! -z $src_version ] && [ $src_version -eq 1 ] \
	&& return 0

[ -z "$git_dir" ] && git_dir=$(cd $(dirname $BASH_SOURCE)/../..; pwd)

for fn in base; do
	. $git_dir/baSHic/scripts/$fn.sh
done

chkVer_GNU(){
	local resp url cmd work_dir
	local pkg exten nver
	
	while [ ! -z "$1" ]; do
		case $1 in
			-p | --pkg )
				shift
				pkg="$1"
				;;
			-e | --exten )
				shift
				exten="$1"
				;;
			-w | --work_dir )
				shift
				work_dir="$1"
				;;
		esac
		shift
	done
	
	[ -z "$pkg" ] 			&& echo "Add -p/--pkg <package>" >&2 && return 1
	[ -z "$work_dir" ] 	&& work_dir=$HOME
	[ -z "$exten" ] 		&& exten=tar.gz
	
	new_mkdir $work_dir
	
	url=https://ftp.gnu.org/gnu/$pkg/
	cmd="curl --url '$url' --fail -s -L"
	cmd="$cmd -D $work_dir/header.txt -o $work_dir/body.html"
	eval $cmd >&2
	[ ! $? -eq 0 ] \
		&& echo -e "${red}Error with curl on $url${NC}" >&2 \
		&& new_rm $work_dir/header.txt $work_dir/body.html \
		&& return 1
	
	cat $work_dir/body.html | sed 's|</td>|</td>\n|g' \
		| grep "$exten" | sed 's|<a href=\(.*\)>\(.*\)</a>|\2|g' \
		| sed 's|<td>||g' | sed 's|</td>||g' \
		| grep "${exten}$" | grep -v "latest" \
		| sed "s|${pkg}-||g" | sed "s|.$exten||g" \
		> $work_dir/$pkg.txt
	nver=$(cat $work_dir/$pkg.txt | wc -l)
	
	while true; do
		cat $work_dir/$pkg.txt | pr -3t -w 40 >&2
		make_menu -c "$yellow" -p "Choose a number:"
		read resp
		
		[ -z "$resp" ] && print_noInput && continue
		check_array $resp $(seq $nver)
		[ ! $? -eq 0 ] && print_notOpt && continue
		break
		
	done
	
	version=$(sed -n ${resp}p $work_dir/$pkg.txt)
	new_rm $work_dir/$pkg.txt $work_dir/body.html \
		$work_dir/header.txt
	
	echo $version
	
}

chkVer_autoconf(){
	chkVer_GNU -p autoconf
}
chkVer_gcc(){
	chkVer_GNU -p gcc
}
chkVer_ncurses(){
	chkVer_GNU -p ncurses
}
chkVer_readline(){
	chkVer_GNU -p readline
}
chkVer_R(){
	local resp v1 url cmd tmp_cnt orig_dir work_dir
	local version
	
	work_dir=$HOME
	new_mkdir $work_dir
	
	# For R major version number, e.g. R-1, R-4
	url=https://cran.r-project.org/src/base
	cmd="curl --url '$url' --fail -s -L"
	cmd="$cmd -D $work_dir/header.txt -o $work_dir/body.html"
	eval $cmd >&2
	[ ! $? -eq 0 ] \
		&& echo -e "${red}Error with curl on R major${NC}" >&2 \
		&& new_rm $work_dir/header.txt $work_dir/body.html \
		&& return 1
	
	cat $work_dir/body.html | grep DIR \
		| sed 's|</td>|</td>\n|g' | grep "a href" \
		| grep "R-" | sed 's|<td>||g' | sed 's|</td>||g' \
		| sed 's|<a\(.*\)>\(.*\)/</a>|\2|g' \
		| sed 's|R-||g' > $work_dir/R_major.txt
	
	while true; do
		echo -e "R major versions:" >&2
		cat $work_dir/R_major.txt \
			| awk '{print "   "$0}' >&2
		make_menu -c "$yellow" -p "Pick a major version (e.g. 4)"
		read resp
		[ -z $resp ] && print_noInput && continue
		check_array $resp $(seq 0 $(tail -n 1 $work_dir/R_major.txt))
		[ ! $? -eq 0 ] && print_notOpt && continue
		v1=$resp
		new_rm $work_dir/header.txt $work_dir/body.html \
			$work_dir/R_major.txt
		break
	done
	
	# For R minor version number
	url=https://cran.r-project.org/src/base/R-$v1/
	cmd="curl --url '$url' --fail -s -L"
	cmd="$cmd -D $work_dir/header.txt -o $work_dir/body.html"
	eval $cmd >&2
	[ ! $? -eq 0 ] \
		&& echo -e "${red}Error with curl on R minor${NC}" >&2 \
		&& new_rm $work_dir/header.txt $work_dir/body.html \
		&& return 1
	
	cat $work_dir/body.html | grep "compressed.gif" \
		| sed 's|</td>|</td>\n|g' | grep "tar.gz" \
		| sed 's|<td>||g' | sed 's|</td>||g' \
		| sed 's|<a\(.*\)>\(.*\)</a>|\2|g' \
		| sed 's|.tar.gz||g' | sed "s|R-${v1}.||g" \
		> $work_dir/R_minor.txt
	
	while true; do
		echo -e "R minor versions:" >&2
		cat $work_dir/R_minor.txt \
			| awk '{print "   "$0}' >&2
		make_menu -c "$yellow" -p "Pick a minor version (e.g. 1.0)"
		read resp
		[ -z $resp ] && print_noInput && continue
		[ ! $(grep "$resp" $work_dir/R_minor.txt | wc -l) -eq 1 ] \
			&& print_notOpt && continue
		v2=$resp
		new_rm $work_dir/header.txt $work_dir/body.html \
			$work_dir/R_minor.txt
		break
	done
	
	version=${v1}.${v2}
	echo $version
	
}


src_version=1

###


