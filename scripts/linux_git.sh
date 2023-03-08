#!/bin/sh

[ ! -z $srcPL_git ] && [ $srcPL_git -eq 1 ] \
	&& return 0

[ -z "$git_dir" ] && git_dir=$(cd $(dirname $BASH_SOURCE)/../..; pwd)

for fn in install; do
	. $git_dir/baSHic/scripts/$fn.sh
done

install_gitlfs(){
	local version v1 pkg pkg_ver apps_dir status cmd
	local url inst_dir down_dir load_env tmp_dir
	
	install_args $@ -p gitlfs -d 3.0.1; status=$?
	[ $status -eq 2 ] && return 0; [ ! $status -eq 0 ] && return 1
	url=https://github.com/git-lfs/git-lfs/releases
	url=$url/download/v$version/git-lfs-v$version.tar.gz
	
	# Load environment
	if [ $load_env -eq 1 ]; then
		[ ! -f $inst_dir/bin/gitlfs ] \
			&& echo -e "Install $pkg_ver" >&2 \
			&& return 1
		update_env -e PATH -a "$inst_dir/bin"
		return 0
	fi
	
	extract_url -u $url -a $apps_dir -s $pkg_ver
	[ $? -eq 1 ] && return 0
	tmp_dir=$(ls $apps_dir/downloads | grep "$pkg")
	tmp_dir=$apps_dir/downloads/$tmp_dir
	mv $tmp_dir $inst_dir
	cd $inst_dir
	
	# Install
	make >&2 && $inst_dir/bin/git-lfs install >&2
	
	status=$?
	install_wrapup -s $status -i $inst_dir -d $down_dir
	[ ! $status -eq 0 ] && return 1
	
	# Make symbolic link
	cd $inst_dir/bin
	ln -s git-lfs gitlfs
	cd 
	return 0
	
}
install_go(){
	local version v1 pkg pkg_ver apps_dir status cmd
	local url inst_dir down_dir load_env tmp_dir
	
	install_args $@ -p go -d 17.1; status=$?
	[ $status -eq 2 ] && return 0; [ ! $status -eq 0 ] && return 1
	url=https://golang.org/dl/go1.${version}.linux-amd64.tar.gz
	
	# Load environment
	if [ $load_env -eq 1 ]; then
		[ ! -f $inst_dir/bin/go ] \
			&& echo -e "Install $pkg_ver" >&2 \
			&& return 1
		update_env -e PATH -a "$inst_dir/bin"
		return 0
	fi
	
	extract_url -u $url -a $apps_dir -s $pkg_ver
	[ $? -eq 1 ] && return 0
	mv $apps_dir/downloads/go $inst_dir
	cd $inst_dir
	
	status=$?
	install_wrapup -s $status -i $inst_dir -d $down_dir
	[ ! $status -eq 0 ] && return 1
	
}

check_repoStat(){
	local repo orig_dir tmp_fn
	
	[ -z "$git_dir" ] && echo "git_dir undefined" >&2 && return 1
	orig_dir=$(pwd)
	tmp_fn="$git_dir/gstat.out"
	
	cd "$git_dir"
	for repo in $(ls | sed 's|/$||g'); do
		[ ! -d "$git_dir/$repo" ] && continue
		
		cd "$git_dir/$repo"
		echo -ne "Checking ${yellow}$repo${NC} " >&2
		
		new_rm "$tmp_fn"
		git status &> "$tmp_fn"
		
		[ $(cat "$tmp_fn" | grep "not a git repository" | wc -l) -gt 0 ] \
			&& echo -e "(${purple}not a repo${NC})" >&2 && continue
			
		[ $(cat "$tmp_fn" | grep "git add" | wc -l) -gt 0 ] \
			&& echo -e "${red}(out of sync, 'git add')${NC}" >&2 && continue
		
		[ $(cat "$tmp_fn" | grep -- "git restore --staged" | wc -l) -gt 0 ] \
			&& echo -e "${red}(out of sync, 'git commit -m')${NC}" >&2 && continue
		
		[ $(cat "$tmp_fn" | grep -- "to publish your local commits" | wc -l) -gt 0 ] \
			&& echo -e "${red}(out of sync, 'git push')${NC}" >&2 && continue
		
		[ $(cat "$tmp_fn" | grep -- "modified:" | wc -l) -gt 0 ] \
			&& echo -e "${red}(out of sync)${NC}" >&2 && continue
		
		[ $(cat "$tmp_fn" | grep -- "up to date" | wc -l) -eq 1 ] \
			&& echo -e "${green}(synced)${NC}" >&2 && continue
		
		echo -e "${red}(out of sync)${NC}" >&2
		
	done
	
	new_rm "$tmp_fn"
	cd "$orig_dir"
	return 0
	
}

srcPL_git=1

###

