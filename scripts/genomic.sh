#!/bin/sh

[ ! -z $src_genomic ] && [ $src_genomic -eq 1 ] \
	&& return 0

for fn in install; do
	. $HOME/github/baSHic/scripts/$fn.sh
done

# Genomics functions
install_htslib(){
	local version v1 pkg pkg_ver apps_dir status cmd
	local url inst_dir down_dir load_env
	
	install_args $@ -p htslib -d "1.15.1"; status=$?
	[ $status -eq 2 ] && return 0; [ ! $status -eq 0 ] && return 1
	url=https://github.com/samtools/htslib/releases/download
	url=$url/$version/htslib-$version.tar.bz2
	
	# Load environment
	if [ $load_env -eq 1 ]; then
		[ ! -f $inst_dir/lib/pkgconfig/htslib.pc ] \
			&& return 1
		update_env -e PKG_CONFIG_PATH -a "$inst_dir/lib/pkgconfig"
		pkg-config --exists --print-errors htslib >&2 \
			|| return 1
		[ ! -f $inst_dir/bin/htsfile ] \
			&& echo -e "Install $pkg_ver" >&2 \
			&& return 1
		CPPFLAGS="$CPPFLAGS `pkg-config --cflags htslib`"
		LDFLAGS="$LDFLAGS `pkg-config --libs htslib`"
		update_env -e PATH -a "$inst_dir/bin"
		update_env -e LD_LIBRARY_PATH -a "$inst_dir/lib"
		export HTSLIB_DIR=$inst_dir/include/htslib
		return 0
	fi
	
	extract_url -u $url -a $apps_dir -s $pkg_ver
	[ $? -eq 1 ] && return 0
	new_mkdir $inst_dir
	cd $inst_dir
	
	# Set environment
	clear_env
	local CPPFLAGS LDFLAGS
	cmd=$(prep_env_cmd -a $apps_dir -p gcc libtool bzip2 xz zlib curl)
	eval $cmd >&2 || return 1
	
	# Install
	cmd="$down_dir/configure"
	[ ! -z "$CPPFLAGS" ] && cmd="$cmd CPPFLAGS=\"$CPPFLAGS\""
	[ ! -z "$LDFLAGS" ] && cmd="$cmd LDFLAGS=\"$LDFLAGS\""
	cmd="$cmd --prefix=$inst_dir >&2"
	cmd="$cmd && make >&2 && make install >&2"
	eval $cmd
	
	status=$?
	install_wrapup -s $status -i $inst_dir -d $down_dir
	return $status
	
}
install_samtools(){
	local version v1 pkg pkg_ver apps_dir status cmd
	local url inst_dir down_dir load_env
	
	install_args $@ -p samtools -d 1.15.1; status=$?
	[ $status -eq 2 ] && return 0; [ ! $status -eq 0 ] && return 1
	url=https://github.com/samtools/samtools/releases/download
	url=$url/$version/samtools-$version.tar.bz2
	
	# Load environment
	if [ $load_env -eq 1 ]; then
		[ ! -f $inst_dir/bin/samtools ] \
			&& echo -e "Install $pkg_ver" >&2 \
			&& return 1
		update_env -e PATH -a "$inst_dir/bin"
		return 0
	fi
	
	extract_url -u $url -a $apps_dir -s $pkg_ver
	[ $? -eq 1 ] && return 0
	mv $down_dir $inst_dir
	cd $inst_dir
	
	# Set environment
	clear_env
	local CPPFLAGS LDFLAGS
	cmd=$(prep_env_cmd -a $apps_dir -p gcc libtool \
		ncurses xz)
	eval $cmd >&2 || return 1
	
	# Install
	cmd="./configure"
	[ ! -z "$CPPFLAGS" ] && cmd="$cmd CPPFLAGS=\"$CPPFLAGS\""
	[ ! -z "$LDFLAGS" ] && cmd="$cmd LDFLAGS=\"$LDFLAGS\""
	cmd="$cmd --prefix=$inst_dir >&2"
	cmd="$cmd && make >&2 && make install >&2"
	eval $cmd
	
	status=$?
	install_wrapup -s $status -i $inst_dir -d $down_dir
	return $status
	
}
install_bedtools(){
	local version v1 pkg pkg_ver apps_dir status cmd
	local url inst_dir down_dir load_env tmp_dir
	
	install_args $@ -p bedtools -d 2.30.0; status=$?
	[ $status -eq 2 ] && return 0; [ ! $status -eq 0 ] && return 1
	url=https://github.com/arq5x/bedtools2/releases/download
	url=$url/v$version/bedtools-$version.tar.gz
	
	# Load environment
	if [ $load_env -eq 1 ]; then
		[ ! -f $inst_dir/bin/bedtools ] \
			&& echo -e "Install $pkg_ver" >&2 \
			&& return 1
		update_env -e PATH -a "$inst_dir/bin"
		return 0
	fi
	
	extract_url -u $url -a $apps_dir -s $pkg_ver
	[ $? -eq 1 ] && return 0
	tmp_dir=$(ls $apps_dir/downloads | grep $pkg)
	tmp_dir=$apps_dir/downloads/$tmp_dir
	mv $tmp_dir $down_dir; mv $down_dir $inst_dir
	cd $inst_dir
	
	# Set environment
	clear_env
	local CPPFLAGS LDFLAGS
	cmd=$(prep_env_cmd -a $apps_dir -p gcc libtool xz)
	eval $cmd >&2 || return 1
	
	# Install
	make -e VERBOSE=true CPPFLAGS="$CPPFLAGS" \
		LDFLAGS="$LDFLAGS" >&2
	
	status=$?
	install_wrapup -s $status -i $inst_dir -d $down_dir
	return $status
	
}

src_genomic=1

###

