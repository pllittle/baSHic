#!/bin/sh

[ ! -z $src_R ] && [ $src_R -eq 1 ] && return 0

[ -z "$git_dir" ] && git_dir=$(cd $(dirname $BASH_SOURCE)/../..; pwd)

for fn in install linux_perl linux_python; do
	. $git_dir/baSHic/scripts/$fn.sh
done

install_R(){
	local version v1 pkg pkg_ver apps_dir status
	local url inst_dir down_dir ncores resp cmd
	
	install_args $@ -p R -d 4.1.2; status=$?
	[ $status -eq 2 ] && return 0; [ ! $status -eq 0 ] && return 1
	v1=`echo $version | cut -d '.' -f1`
	url=https://cran.r-project.org/src/base/R-${v1}/R-${version}.tar.gz
	
	extract_url -u $url -a $apps_dir -s $pkg_ver
	[ $? -eq 1 ] && return 0
	new_mkdir $inst_dir
	cd $inst_dir
	
	# Set environment
	clear_env
	local CPPFLAGS LDFLAGS
	ncores=`get_ncores`
	cmd=$(prep_env_cmd -a $apps_dir -p gcc tex libtool \
		ncurses readline bzip2 xz pcre2 zlib curl libxml2 libpng \
		freetype pixman cairo gperf cmake Python fontconfig)
	eval $cmd >&2 || return 1
	# && install_ICU -a $apps_dir -e
	# && install_anaconda -a $apps_dir -e
	
	make_menu -y -p "Do the dependency statuses look good?"; read resp
	if [ -z $resp ]; then
		return 0
	elif [ $resp -eq 1 ]; then
		echo "Continue with installation!" >&2; sleep 5
	else
		return 0
	fi
	
	# Configure and install
	cmd="$down_dir/configure"
	[ ! -z "$CPPFLAGS" ] && cmd="$cmd CPPFLAGS=\"$CPPFLAGS\""
	[ ! -z "$LDFLAGS" ] && cmd="$cmd LDFLAGS=\"$LDFLAGS\""
	cmd="$cmd --prefix=$inst_dir"
	cmd="$cmd --enable-memory-profiling"
	cmd="$cmd --enable-R-shlib"
	if check_array $curr_host hutch uthsc; then
		resp=
		make_menu -y -p "With X11?"; read resp
		[ ! -z $resp ] && [ $resp -eq 2 ] && cmd="$cmd --with-x=no"
	fi
	
	eval $cmd >&2
	[ ! $? -eq 0 ] && return 1
	
	resp=
	make_menu -c "$white" -y -p "R-${version} make and install?"; read resp
	[ -z $resp ] && return 1
	[ ! $resp -eq 1 ] && return 1
	
	make -j $ncores >&2 && make check >&2 \
		&& make install >&2 && make install-tests >&2
	
	local status=$?
	install_wrapup -s $status -i $inst_dir -d $down_dir
	return $status
	
}

src_R=1

###
