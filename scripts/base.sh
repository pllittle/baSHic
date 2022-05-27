#!/bin/sh

[ ! -z $src_bash ] && [ $src_bash -eq 1 ] \
	&& return 0

[ -z "$git_dir" ] && git_dir=$(cd $(dirname $BASH_SOURCE)/../..; pwd)

for fn in colors; do
	. $git_dir/baSHic/scripts/$fn.sh
done

new_mkdir(){
	local ijk
	for ijk in $@; do
		[ ! -d $ijk ] && mkdir $ijk
	done
}
new_rm(){
	local obj
	# echo "Cleaning out old files.", older name "fileExistsThenDelete"
	for obj in $@; do
		# [ -f $obj -o -d $obj ] && rm -rf $obj
		if [ -d $obj ]; then
			rm -rf $obj
		elif [ -f $obj ]; then
			rm $obj
		fi
	done
}
new_dosUnix(){
	dos2unix $@ 2> /dev/null > /dev/null
}
smart_sed(){
	local cmd input_fn output_fn sub subs chost
	local cnt=0
	
	# Get parameter inputs
	while [ ! -z "$1" ]; do
		case $1 in
			-i | --input )
				shift
				input_fn="$1"
				;;
			-o | --output )
				shift
				output_fn="$1"
				;;
			-h | --host )
				shift
				chost="$1"
				;;
			-s | --sub )
				while [ ! -z "$2" ]; do
					case $2 in
						-* )
							break
							;;
						* )
							subs[cnt]="$2"
							let cnt=cnt+1
							shift
					esac
				done
				;;
		esac
		shift
	done
	
	if [ 1 -eq 2 ]; then
		# Real code example to model off of
		cat $1 | sed "s|blah_WF|${curr_host}|g" \
			| sed "s|blah_doing|$doing|g" | sed "s|blah_dataset|${dataset}|g" \
			| sed "s|blah_trim|$trim|g" | sed "s|blah_perm|$perm|g" \
			| sed "s|blah_anaFilter|$anafilter|g" | sed "s|blah_ENSG|$ENSG|g" \
			> $2
	fi
	
	# Formulate cmd
	cmd="cat $input_fn"
	
	if [ ! -z $chost ]; then
		cmd="$cmd | sed \"0,/blah_WF/ s/blah_WF/${chost}/\""
	fi
	
	for sub in "${subs[@]}"; do
		cmd="$cmd | sed \"s|$sub|g\""
	done
	cmd="$cmd > $output_fn"
	# echo -e "$cmd" >&2
	
	eval $cmd
	
}

check_int(){
	local input=$1
	
	if ! [ "$input" -eq "$input" ] 2> /dev/null; then
		return 1
	fi
	
	return 0
}
check_array(){
	local elem=$1
	shift
	local arr=("$@")
	local ii
	for ii in "${arr[@]}"; do
		[ "$ii" == "$elem" ] && return 0
	done
	return 1
}
pull_repos(){
	local git_dir cnt userrepo userrepos resp group repo
	local myuser
	local pull=no
	cnt=0
	
	while [ ! -z "$1" ]; do
		case $1 in
			-g | --git_dir )
				shift
				git_dir="$1"
				;;
			-m | --myuser )
				shift
				myuser="$1"
				;;
			-r | --repos )
				while [ ! -z "$2" ]; do
					case $2 in
						-* )
							break
							;;
						* )
							userrepos[cnt]="$2"
							let cnt=cnt+1
							shift
							;;
					esac
				done
				;;
		esac
		shift
	done
	
	[ -z "$git_dir" ] && echo "Add -g <git directory>" >&2 && return 1
	[ -z "${userrepos[0]}" ] && echo "Add -r group1/repo1 group2/repo2" >&2 && return 1
	[ -z "$myuser" ] && echo "Add -m <GitHub username>" >&2 && return 1
	
	new_mkdir $git_dir
	unset SSH_ASKPASS
	
	for userrepo in "${userrepos[@]}"; do
		group=$(echo $userrepo | cut -d '/' -f1)
		repo=$(echo $userrepo | cut -d '/' -f2)
		make_menu -y -c "\e[38;5;200m" \
			-p "Pull repo = $userrepo?"; read resp
		[ -z $resp ] && resp=1
		if [ $resp -eq 1 ]; then
			if [ ! -d $git_dir/$repo ]; then
				cd $git_dir
				git clone https://github.com/$group/$repo.git >&2
			else
				cd $git_dir/$repo
				new_rm ~/pull.out
				# git pull > ~/pull.out
				git pull https://$myuser@github.com/$group/$repo > ~/pull.out
				if [ "$pull" == "no" ] && [ $(cat ~/pull.out | grep -m 1 "Already up" | wc -l) -eq 1 ]; then
					pull=no
					cat ~/pull.out | grep "Already up" >&2
				else
					cat ~/pull.out >&2
					pull=yes
				fi
			fi
		fi
	done
	
	new_rm ~/pull.out
	[ "$pull" == "yes" ] && exit 0
	
}
show_PATH(){
	echo $PATH | sed 's/:/\n/g' >&2
}
make_aaRun(){
	local dir fn
	
	while [ ! -z "$1" ]; do
		case $1 in
			-d | --dir )
				shift
				dir="$1"
				;;
			-f | --file )
				shift
				fn="$1"
				;;
		esac
		shift
	done
	
	[ -z "$dir" ] && echo "Add -d <project_dir>" >&2 && return 1
	[ -z "$fn" ] 	&& echo "Add -f <filename>" >&2 && return 1
	
	[ -f $dir/aa_run.sh ] && return 1
	[ ! -f $fn ] && echo -e "$fn missing" >&2 && return 1
	
	echo "Making aa_run.sh script ..." >&2
	echo "#!/bin/sh" > $dir/aa_run.sh
	echo -e "fn=$fn" >> $dir/aa_run.sh
	echo 'dos2unix $fn &> /dev/null' >> $dir/aa_run.sh
	echo "bash $fn" >> $dir/aa_run.sh
	
}
git_cache(){
	local sec
	
	make_menu -p "How many seconds to cache token? (e.g. 900)"
	read sec
	[ -z "$sec" ] && print_noInput && return 1
	
	git config --global credential.helper \
		"cache --timeout=$sec" >&2
	
	return 0
}

src_bash=1

###
