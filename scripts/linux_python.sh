#!/bin/sh

[ ! -z $src_python ] && [ $src_python -eq 1 ] \
	&& return 0

for fn in install; do
	. $HOME/github/baSHic/scripts/$fn.sh
done

# Python Functions
install_Python(){
	local version v1 pkg pkg_ver apps_dir cmd status
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
	return $status
	
}
install_pip(){
	# echo "Debug code" >&2 && return 1
	local version apps_dir py_dir
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
	
	if [ -z $version ]; then
		make_menu -p "Which python version? (e.g. 2.7.6, 3.8.4)"
		read version
	fi
	[ -z $apps_dir ] && apps_dir=$HOME/apps
	
	# Set environment
	clear_env
	local PYTHONHOME
	local CPPFLAGS LDFLAGS
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
	echo "Debug code" >&2 && return 1
	
	local version apps_dir v2 py_dir pylib mod mods
	local cnt=0
	
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
	
	if [ -z $version ]; then
		make_menu -p "Which python version? (e.g. 2.7.6, 3.8.4)"
		read version
	fi
	[ -z $apps_dir ] && apps_dir=$HOME/apps
	
	py_dir=$apps_dir/Python-${version}
	if [ ! -d $py_dir ]; then
		install_python -v ${version} -a $apps_dir
	fi
	v2=`echo $version | cut -d '.' -f1-2`
	pylib=$py_dir/lib/python${v2}
	
	# Check/update pip and add python to PATH
	install_pip -v $version -a $apps_dir
	
	# Add PYTHONPATH??
	# update_env -e PYTHONPATH -a "$pylib" "$pylib/site-packages"
	
	# Install modules
	for mod in "${mods[@]}"; do
		pip install $mod >&2
	done
	
	# Remove python from PATH
	update_env -e PATH -r "$py_dir/bin"
	
	return 0
	
}




src_python=1

###

