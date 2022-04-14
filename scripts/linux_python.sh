#!/bin/sh

[ ! -z $src_python ] && [ $src_python -eq 1 ] \
	&& return 0

for fn in install; do
	. $HOME/github/baSHic/scripts/$fn.sh
done

# Python Functions
install_Python(){
	local version v1 v2 pkg pkg_ver apps_dir cmd status
	local url inst_dir down_dir load_env
	
	install_args $@ -p Python -d "2.7.6, 3.8.1, 3.8.4, 3.10.4"; status=$?
	[ $status -eq 2 ] && return 0; [ ! $status -eq 0 ] && return 1
	url=https://www.python.org/ftp/python/${version}/Python-${version}.tgz
	v1=$(echo $version | cut -d '.' -f1-2)
	
	if [ $load_env -eq 1 ]; then
		[ ! -f $inst_dir/lib/pkgconfig/python-$v1.pc ] \
			&& return 1
		[ ! -f $inst_dir/bin/python${v1} ] \
			&& echo -e "Install $pkg_ver" >&2 \
			&& return 1
		update_env -e PKG_CONFIG_PATH -a "$inst_dir/lib/pkgconfig"
		local pc_fn
		for pc_fn in `ls $inst_dir/lib/pkgconfig | grep "python-$v1" | sed 's|.pc$||g'`; do
			pkg-config --exists --print-errors $pc_fn >&2 \
				|| return 1
			CPPFLAGS="$CPPFLAGS `pkg-config --cflags $pc_fn`"
			LDFLAGS="$LDFLAGS `pkg-config --libs $pc_fn`"
		done
		update_env -e PATH -a "$inst_dir/bin"
		update_env -e LD_LIBRARY_PATH -a "$inst_dir/lib"
		update_env -e LIBRARY_PATH -a "$inst_dir/lib"
		update_env -e CPATH -a "$inst_dir/include"
		update_env -e MANPATH -a "$inst_dir/share/man"
		return 0
	fi
	
	extract_url -u $url -a $apps_dir -s $pkg_ver
	[ $? -eq 1 ] && return 0
	new_mkdir $inst_dir
	cd $inst_dir
	
	# Set environment
	clear_env
	local PYTHONHOME
	local CPPFLAGS LDFLAGS
	cmd=$(prep_env_cmd -a $apps_dir -p gcc libtool \
		ncurses readline bzip2 zlib)
	eval $cmd >&2 || return 1
	
	# Install
	cmd="$down_dir/configure"
	[ ! -z "$CPPFLAGS" ] && cmd="$cmd CPPFLAGS=\"$CPPFLAGS\""
	[ ! -z "$LDFLAGS" ] && cmd="$cmd LDFLAGS=\"$LDFLAGS\""
	cmd="$cmd --prefix=$inst_dir >&2"
	cmd="$cmd && make >&2 && make install >&2"
	eval $cmd
	
	local status=$?
	install_wrapup -s $status -i $inst_dir -d $down_dir
	
	# Add sym links
	if [ ! -f $inst_dir/bin/python ]; then
		echo "Creating sym link python" >&2
		v2=$(echo $version | cut -d '.' -f1-2)
		cmd="ln -s $inst_dir/bin/python$v2 $inst_dir/bin/python"
		eval $cmd
	fi
	if [ ! -f $inst_dir/bin/pip ]; then
		echo "Creating sym link pip" >&2
		v2=$(echo $version | cut -d '.' -f1)
		cmd="ln -s $inst_dir/bin/pip$v2 $inst_dir/bin/pip"
		eval $cmd
	fi
	
	return $status
	
}
install_pip(){
	local apps_dir py_dir
	local url=https://bootstrap.pypa.io/pip/get-pip.py
	local inst_fn=get-pip.py
	
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
		esac
		shift
	done
	
	[ -z $apps_dir ] && apps_dir=$HOME/apps
	
	# Set environment
	clear_env
	local PYTHONHOME CPPFLAGS LDFLAGS
	cmd=$(prep_env_cmd -a $apps_dir -p gcc libtool \
		ncurses readline bzip2 zlib Python)
	eval $cmd >&2 || return 1
	# local PYTHONPATH=$py_dir/lib/python${v2}:$py_dir/lib/python${v2}/site-packages:$PYTHONPATH
	
	# Check pip already installed
	if [ -f $py_dir/bin/pip ]; then
		pip install -U pip >&2
	else
		new_mkdir $apps_dir/downloads
		cd $apps_dir/downloads
		[ ! -f $inst_fn ] && wget --no-check-certificate $url >&2
		python $inst_fn >&2
		new_rm $HOME/downloads/$inst_fn
	fi
	
}
install_pymod(){
	local apps_dir v2 py_dir pylib mod mods
	local cmd
	local cnt=0
	
	while [ ! -z $1 ]; do
		case $1 in
			-a | --apps_dir )
				shift
				apps_dir="$1"
				;;
			-m | --modules )
				while [ ! -z "$2" ]; do
					case $2 in
						-* )
							break
							;;
						* )
							mods[cnt]="$2"
							let cnt=cnt+1
							shift
							;;
					esac
				done
				;;
		esac
		shift
	done
	
	[ -z $apps_dir ] && apps_dir=$HOME/apps
	[ -z "${mods[0]}" ] && echo "no modules provided" >&2 && return 1
	
	# Set environment
	clear_env
	local PYTHONHOME CPPFLAGS LDFLAGS
	cmd=$(prep_env_cmd -a $apps_dir -p gcc libtool \
		ncurses readline bzip2 zlib Python)
	eval $cmd >&2 || return 1
	
	# Add PYTHONPATH??
	# update_env -e PYTHONPATH -a "$pylib" "$pylib/site-packages"
	
	# Install modules
	for mod in "${mods[@]}"; do
		pip -m install $mod >&2
	done
	
	# Remove python from PATH
	clear_env
	
	return 0
	
}
install_fontconfig(){
	local version pkg pkg_ver apps_dir status cmd
	local url inst_dir down_dir ncores load_env
	
	install_args $@ -p fontconfig -d 2.13.96; status=$?
	[ $status -eq 2 ] && return 0; [ ! $status -eq 0 ] && return 1
	url=https://www.freedesktop.org/software/fontconfig
	url=$url/release/fontconfig-${version}.tar.gz
	
	# Load environment
	if [ $load_env -eq 1 ]; then
		[ ! -f $inst_dir/bin/fc-cat ] \
			&& echo -e "Install $pkg_ver" >&2 \
			&& return 1
		[ ! -f $inst_dir/lib/pkgconfig/fontconfig.pc ] \
			&& return 1
		update_env -e PKG_CONFIG_PATH -a "$inst_dir/lib/pkgconfig"
		pkg-config --exists --print-errors fontconfig >&2 \
			|| return 1
		CPPFLAGS="$CPPFLAGS `pkg-config --cflags fontconfig`"
		LDFLAGS="$LDFLAGS `pkg-config --libs fontconfig`"
		update_env -e LD_LIBRARY_PATH -a "$inst_dir/lib"
		return 0
	fi
	
	extract_url -u $url -a $apps_dir -s $pkg_ver
	[ $? -eq 1 ] && return 0
	new_mkdir $inst_dir
	cd $inst_dir
	
	# Set environment
	clear_env
	local CPPFLAGS LDFLAGS
	cmd=$(prep_env_cmd -a $apps_dir -p gcc libtool \
		libxml2 freetype gperf ncurses readline bzip2 \
		zlib Python)
	eval $cmd >&2 || return 1
	
	# Install
	cmd="$down_dir/configure"
	[ ! -z "$CPPFLAGS" ] && cmd="$cmd CPPFLAGS=\"$CPPFLAGS\""
	[ ! -z "$LDFLAGS" ] && cmd="$cmd LDFLAGS=\"$LDFLAGS\""
	cmd="$cmd --prefix=$inst_dir --enable-libxml2 >&2"
	cmd="$cmd && make >&2 && make install >&2"
	eval $cmd
	
	local status=$?
	install_wrapup -s $status -i $inst_dir -d $down_dir
	return $status
	
}


# Boost Functions
install_boost(){
	local version v1 pkg pkg_ver apps_dir status cmd
	local url inst_dir down_dir load_env tmp_dir
	
	install_args $@ -p boost -d 1.73.0; status=$?
	[ $status -eq 2 ] && return 0; [ ! $status -eq 0 ] && return 1
	v1=$(echo $version | sed 's|\.|_|g')
	url=https://sourceforge.net/projects/boost/files
	url=$url/boost/$version/boost_${v1}.tar.gz
	
	# Load environment
	if [ $load_env -eq 1 ]; then
		[ ! -d $inst_dir/libs ] \
			&& echo -e "Install $pkg_ver!" >&2 \
			&& return 1
		update_env -e BOOST_ROOT -a "$inst_dir"
		return 0
	fi
	
	extract_url -u $url -a $apps_dir -s $pkg_ver
	[ $? -eq 1 ] && return 0
	tmp_dir=$(ls $apps_dir/downloads | grep $pkg)
	tmp_dir=$apps_dir/downloads/$tmp_dir
	mv $tmp_dir $inst_dir
	cd $inst_dir
	
	# Clear environment
	clear_env
	local CPPFLAGS LDFLAGS
	cmd=$(prep_env_cmd -a $apps_dir -p gcc Python)
	eval $cmd >&2 || return 1
	
	# Install
	cmd="./bootstrap.sh"
	[ ! -z "$CPPFLAGS" ] && cmd="$cmd CPPFLAGS=\"$CPPFLAGS\""
	[ ! -z "$LDFLAGS" ] && cmd="$cmd LDFLAGS=\"$LDFLAGS\""
	cmd="$cmd --prefix=$inst_dir"
	status=$(which python > /dev/null; echo $?)
	[ $status -eq 0 ] && cmd="$cmd --with-python=$(which python)"
	cmd="$cmd >&2 && ./b2 >&2 && ./b2 headers >&2"
	eval $cmd
	
	status=$?
	install_wrapup -s $status -i $inst_dir -d $down_dir
	return $status
	
}


src_python=1

###

