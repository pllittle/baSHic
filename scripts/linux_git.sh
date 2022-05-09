#!/bin/sh

[ ! -z $src_git ] && [ $src_git -eq 1 ] \
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

src_git=1

###

