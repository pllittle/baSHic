#!/bin/sh

[ ! -z $src_version ] && [ $src_version -eq 1 ] \
	&& return 0

[ -z "$git_dir" ] && git_dir=$(cd $(dirname $BASH_SOURCE)/../..; pwd)

for fn in base; do
	. $git_dir/baSHic/scripts/$fn.sh
done

chkVer_R(){
	local resp v1 url cmd tmp_cnt orig_dir work_dir
	
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
		make_menu -c "$yellow" -p "Pick a major version (e.g. 4)"
			cat $work_dir/R_major.txt \
				| awk '{print "   "$0}' >&2
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
		make_menu -c "$yellow" -p "Pick a minor version (e.g. 1.0)"
			cat $work_dir/R_minor.txt \
				| awk '{print "   "$0}' >&2
		read resp
		[ -z $resp ] && print_noInput && continue
		[ ! $(grep "$resp" $work_dir/R_minor.txt | wc -l) -eq 1 ] \
			&& print_notOpt && continue
		v2=$resp
		new_rm $work_dir/header.txt $work_dir/body.html \
			$work_dir/R_minor.txt
		break
	done
	
	echo -e "${v1}.${v2}"
	
}

src_version=1

###


