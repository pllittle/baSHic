#!/bin/sh

[ ! -z $srcPL_bash ] && [ $srcPL_bash -eq 1 ] \
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
	
	for obj in $@; do
		if [ -d "$obj" ]; then
			rm -rf "$obj"
		elif [ -f "$obj" ]; then
			rm "$obj"
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
	local myuser cloneMeth orig_dir
	local pull=no
	cnt=0
	
	while [ ! -z "$1" ]; do
		case $1 in
			-c | --cloneMeth )
				shift
				cloneMeth="$1"
				;;
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
	
	[ -z "$cloneMeth" ] && cloneMeth=HTTPS
	[ -z "$git_dir" ] && echo "Add -g <git directory>" >&2 && return 1
	[ -z "${userrepos[0]}" ] && echo "Add -r group1/repo1 group2/repo2" >&2 && return 1
	[ -z "$myuser" ] && echo "Add -m <GitHub username>" >&2 && return 1
	check_array "$cloneMeth" HTTPS SSH
	[ ! $? -eq 0 ] && echo "cloneMeth is either HTTPS or SSH" >&2 && return 1
	
	new_mkdir "$git_dir"
	unset SSH_ASKPASS
	orig_dir=$(pwd)
	
	for userrepo in "${userrepos[@]}"; do
		group=$(echo $userrepo | cut -d '/' -f1)
		repo=$(echo $userrepo | cut -d '/' -f2)
		make_menu -y -c "\e[38;5;200m" -p "Pull repo = $userrepo?"
		read -t 5 resp
		[ -z $resp ] && resp=1 && echo -e "${white}$resp${NC}" >&2
		if [ $resp -eq 1 ]; then
			if [ ! -d "$git_dir/$repo" ]; then
				cd "$git_dir"
				if [ "$cloneMeth" == "HTTPS" ]; then
					git clone https://github.com/$userrepo.git >&2
				else
					git clone git@github.com:$userrepo.git >&2
				fi
				[ ! $? -eq 0 ] && echo -e "Error cloning $userrepo" >&2 && return 1
			else
				cd "$git_dir/$repo"
				new_rm ~/pull.out
				git pull > ~/pull.out
				# git pull https://$myuser@github.com/$userrepo > ~/pull.out
				cat ~/pull.out >&2
				if [ "$pull" == "no" ] && [ $(cat ~/pull.out | grep -m 1 "Already up" | wc -l) -eq 1 ]; then
					pull=no
				else
					pull=yes
				fi
			fi
		fi
	done
	
	new_rm ~/pull.out
	cd "$orig_dir"
	[ "$pull" == "yes" ] && exit 0
	
}
show_PATH(){
	echo $PATH | sed 's|:|\n|g' >&2
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
	
	[ -f $dir/aa_run.sh ] && return 0
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

getRepoSrc(){
	local uname repo repo_dir orig_dir
	local script scripts nvalues cnt resp
	cnt=0
	
	while [ ! -z "$1" ]; do
		case $1 in
			-r | --repo )
				shift
				repo="$1"
				;;
			-s | --scripts )
				while [ ! -z "$2" ]; do
					case $2 in
						-* )
							break
							;;
						* )
							scripts[cnt]="$2"
							let cnt=cnt+1
							shift
							;;
					esac
				done
				;;
			-u | --uname )
				shift
				uname="$1"
				;;
		esac
		shift
	done
	
	# Check inputs
	[ -z "$git_dir" ] && echo "Define git_dir variable" >&2 \
		&& return 1
	while [ -z "$repo" ]; do
		make_menu -c "$yellow" -p "Specify a repository name:"
		read resp
		[ -z "$resp" ] && print_noInput && continue
		repo="$resp"
	done
	while [ -z "$uname" ]; do
		make_menu -c "$yellow" -p "Specify the username of $repo:"
		read resp
		[ -z "$resp" ] && print_noInput && continue
		uname="$resp"
	done
	nvalues=${#scripts[@]}
	
	# Set vars
	repo_dir="$git_dir/$repo"
	orig_dir=$(pwd)

	if [ ! -d "$repo_dir" ]; then
		cd "$git_dir"
		git clone https://github.com/$uname/$repo.git >&2
		[ ! $? -eq 0 ] && echo -e "Error cloning $repo" >&2 && return 1
	else
		cd "$repo_dir"
		git pull >&2
		[ ! $? -eq 0 ] && echo -e "Error pulling $repo" >&2 && return 1
	fi
	
	cd "$orig_dir"
	[ $nvalues -eq 0 ] && return 0
	
	for script in "${scripts[@]}"; do
		
		[ ! -f "$repo_dir/$script" ] \
			&& echo -e "Error: $repo's $script missing" >&2 \
			&& return 1
		
		. "$repo_dir/$script"
		[ ! $? -eq 0 ] && echo -e "Error src-ing $repo's $script" >&2 \
			&& return 1
		
	done
	
	return 0
	
}

srcPL_bash=1

###
