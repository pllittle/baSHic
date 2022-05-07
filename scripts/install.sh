#!/bin/sh

[ ! -z $src_install ] && [ $src_install -eq 1 ] \
	&& return 0

[ -z "$git_dir" ] && git_dir=$(cd $(dirname $BASH_SOURCE)/../..; pwd)

for fn in base colors getEnv; do
	. $git_dir/baSHic/scripts/$fn.sh
done

# Fundamental install functions
install_prompt(){
	local inst_dir=$1
	local resp prog
	
	prog=`echo -e $inst_dir | sed 's|/|\n|g' | tail -n 1`
	
	if [ -d $inst_dir ]; then
		while true; do
			make_menu -y -c "\e[38;5;11m" \
				-p "Do you want to re-install $prog?"; read resp
			if [ -z $resp ]; then
				print_noInput
			elif check_array $resp 1 2; then
				[ $resp -eq 1 ] \
					&& echo "Removing build directory ..." >&2 \
					&& new_rm $inst_dir
				break
			else
				print_notOpt
			fi
		done
	else
		resp=1
	fi
	
	[ $resp -eq 1 ] && echo install
	[ $resp -eq 2 ] && echo cancel
	
}
extract_url(){
	local url apps_dir soft_dir status
	local inst_fn inst_dir src_dir cpress
	
	while [ ! -z $1 ]; do
		case $1 in
			-u | --url )
				shift
				url="$1"
				;;
			-a | --apps_dir )
				shift
				apps_dir="$1"
				;;
			-s | --soft_dir )
				shift
				soft_dir="$1"
				;;
			-r | --src_dir )
				shift
				src_dir="$1"
				;;
			-h | --help )
				make_help -f help_runConf -n extract_url \
					-o "u|url|url|Url link" \
					"a|apps_dir|apps_dir|Directory to install application to" \
					"s|soft_dir|soft_dir|Name of application's directory"
				return 0
				;;
		esac
		shift
	done
	
	[ -z $apps_dir ] && apps_dir=$HOME/apps
	[ -z $soft_dir ] && echo "Add -s <install_dir_name>" >&2 && return 1
	
	new_mkdir $apps_dir
	inst_fn=`echo $url | sed 's|/|\n|g' | tail -n 1` # e.g. program.tar.gz
	
	if [ `echo $inst_fn | grep ".tar.gz" | wc -l` -eq 1 ]; then
		cpress=.tar.gz
	elif [ `echo $inst_fn | grep ".tgz" | wc -l` -eq 1 ]; then
		cpress=.tgz
	elif [ `echo $inst_fn | grep ".tar.bz2" | wc -l` -eq 1 ]; then
		cpress=.tar.bz2
	elif [ `echo $inst_fn | grep ".xz" | wc -l` -eq 1 ]; then
		cpress=.xz
	elif [ `echo $inst_fn | grep ".tar.lz" | wc -l` -eq 1 ]; then
		cpress=.tar.lz
	else
		print_notOpt
		return 1
	fi
	[ -z $cpress ] && echo "Add code for cpress" >&2 && return 1
	
	inst_dir=$apps_dir/$soft_dir
	[ `install_prompt $inst_dir` == "cancel" ] && return 1
	new_mkdir $apps_dir/downloads
	cd $apps_dir/downloads
	
	# Check url exists
	echo -e "${purple}Checking URL exists ...${NC}" >&2
	status=$(curl --head --silent --fail $url &> /dev/null; echo $?)
	[ ! $status -eq 0 ] && echo "URL doesn't work, update it!" >&2 && return 1
	
	# If install source directory exists, skip url down
	[ -z $src_dir ] && src_dir=$(echo $inst_fn | sed "s|$cpress||")
	[ -d $src_dir ] \
		&& echo "Skipping download, source directory exists" >&2 \
		&& return 0
	[ ! -f $inst_fn ] && wget --no-check-certificate $url >&2
	
	echo -e "`date`: Decompress downloaded file ..." >&2
	if check_array $cpress .tar.gz .tgz; then
		tar -zxf $inst_fn >&2
	elif check_array $cpress .xz .lz .tar.bz2; then
		tar -xf $inst_fn >&2
	else
		print_notOpt
		return 0
	fi
	
	echo -e "`date`: Delete downloaded file ..." >&2
	[ -f $inst_fn ] &&  rm -rf $inst_fn
	return 0
	
}
pull_app_repo(){
	local apps_dir url repo
	
	while [ ! -z $1 ]; do
		case $1 in
			-u | --url )
				shift
				url="$1"
				;;
			-a | --apps_dir )
				shift
				apps_dir="$1"
				;;
		esac
		shift
	done
	
	[ -z $apps_dir ] && apps_dir=$HOME/apps
	repo=`echo $url | sed 's|/|\n|g' | tail -n 1 | sed 's|.git||g'`
	
	cd $apps_dir
	[ ! -d $repo ] && git clone $url >&2
	
	cd $repo
	git pull >&2
	
}
show_exist_pkg(){
	local pkg apps_dir
	while [ ! -z $1 ]; do
		case $1 in
			-p | --pkg )
				shift
				pkg="$1"
				;;
			-a | --apps_dir )
				shift
				apps_dir="$1"
				;;
		esac
		shift
	done
	
	[ -z $pkg ] && echo "Missing pkg!" >&2 && exit 0
	[ -z $apps_dir ] && echo "Missing apps_dir!" >&2 && exit 0
	
	if [ `ls $apps_dir | grep -w $pkg | wc -l` -gt 0 ]; then
		ls $apps_dir | grep -w $pkg
	fi
}
install_args(){
	local default status resp work_dir
	
	load_env=0
	while [ ! -z $1 ]; do
		case $1 in
			-v | --version )
				shift
				version="$1"
				;;
			-d | --default )
				shift
				default="$1"
				;;
			-a | --apps_dir )
				shift
				apps_dir="$1"
				;;
			-e | --load_env )
				load_env=1
				;;
			-p | --pkg )
				shift
				pkg="$1"
				;;
		esac
		shift
	done
	
	[ -z $pkg ] && echo "Add -p <package>" >&2 && return 1
	[ -z $apps_dir ] && apps_dir=$HOME/apps
	
	work_dir=$apps_dir/downloads
	new_mkdir $apps_dir $work_dir
	
	if [ -z $version ]; then
		show_exist_pkg -p $pkg -a $apps_dir >&2
		if [ -z "$default" ]; then
			make_menu -p "Which $pkg version?"
		else
			make_menu -p "Which $pkg version? (e.g. $default)"
		fi
		read version
	fi
	status=$(which $pkg &> /dev/null; echo $?)
	if [ -z $version ]; then
		echo -e "Checking for existing $pkg: status=$status ..." >&2
		if [ ! $status -eq 0 ]; then
			make_menu -y -p "Proceed without $pkg?"; read resp
			[ ! -z $resp ] && [ $resp -eq 1 ] && return 2
			return 1
		fi
		return 2
	fi
	
	pkg_ver=${pkg}-${version}
	inst_dir=$apps_dir/$pkg_ver
	down_dir=$work_dir/$pkg_ver
	return 0
	
}
install_wrapup(){
	local inst_dir down_dir status resp2
	
	while [ ! -z $1 ]; do
		case $1 in
			-i | --inst_dir )
				shift
				inst_dir="$1"
				;;
			-d | --down_dir )
				shift
				down_dir="$1"
				;;
			-s | --status )
				shift
				status="$1"
				;;
		esac
		shift
	done
	
	# Either install succeeded or failed
	if [ $status -eq 0 ]; then
		echo -e "${cyan}`date`: Install complete${NC}" >&2
		cd $inst_dir
		[ -d $down_dir ] \
			&& echo "Removing source dir ..." >&2 \
			&& rm -rf $down_dir
	else
		echo -e "${red}`date`: Install failed${NC}" >&2
		cd $HOME
		make_menu -c ${orange} -y -p "Delete source & build dirs?"; read resp2
		[ -z $resp2 ] && return 0
		[ ! -z $resp2 ] && [ $resp2 -eq 1 ] \
			&& new_rm $inst_dir && new_rm $down_dir
	fi
	
}
uniq_FLAGS(){
	CPPFLAGS=$(echo $CPPFLAGS | sed 's| |\n|g' | sort | uniq | tr '\n' ' ')
	LDFLAGS=$(echo $LDFLAGS | sed 's| |\n|g' | sort | uniq | tr '\n' ' ')
}
inst_load_env(){
	echo "Don't use this function" >&2 && return 1
	local load_env inst_dir spec_fn pkg_ver
	local num_pc_fns pc_fn pc_fn2 pc_dir dir
	
	while [ ! -z $1 ]; do
		case $1 in
			-e | --load_env )
				shift
				load_env="$1"
				;;
			-i | --inst_dir )
				shift
				inst_dir="$1"
				;;
			-n | --pkg_ver )
				shift
				pkg_ver="$1"
				;;
			-f | --spec_fn )
				shift
				spec_fn="$1"
				;;
			-p | --pc_fn )
				shift
				pc_fn="$1"
		esac
		shift
	done
	
	[ -z $load_env ] && return 0
	[ ! -z $load_env ] && [ ! $load_env -eq 1 ] && return 0
	[ -z $pkg_ver ] && echo "Add -n $pkg_ver" >&2 && return 1
	
	# Depending on options, 
	#	Update PATH,LD_LIBRARY_PATH,PKG_CONFIG_PATH, 
	# Check specific file exists to confirm module installed
	
	# Check pc files in lib dir
	pc_dir=$inst_dir/lib/pkgconfig
	if [ -d $pc_dir ]; then
		
		num_pc_fns=$(ls $pc_dir | grep ".pc$" | wc -l)
		[ $num_pc_fns -ge 1 ] \
			&& update_env -e PKG_CONFIG_PATH -a "$inst_dir/lib/pkgconfig"
		
		# Assuming only one pc file ...
		if [ $num_pc_fns -eq 1 ]; then
			pc_fn=$(ls $pc_dir | grep ".pc$")
		fi
		[ ! -z $pc_fn ] && pc_fn2=$(echo $pc_fn | sed 's|.pc$||')
		pkg-config --exists --print-errors \
			$pc_fn2 >&2 || return 1
		
		# Update flags
		tmp_flags=`pkg-config --cflags $pc_fn2`
		[ $(echo $CPPFLAGS | grep "$tmp_flags" | wc -l) -eq 0 ] \
			&& CPPFLAGS="$CPPFLAGS $tmp_flags"
		tmp_flags=`pkg-config --libs $pc_fn2`
		[ $(echo $LDFLAGS | grep "$tmp_flags" | wc -l) -eq 0 ] \
			&& LDFLAGS="$LDFLAGS $tmp_flags"
	
	else
		[ -d $inst_dir/include ] && CPPFLAGS="$CPPFLAGS $inst_dir/include"
		for dir in `ls -l $inst_dir/include | grep "^d" | tr -s ' ' | cut -d ' ' -f9`; do
			[ $(ls $inst_dir/include/$dir | grep ".h$" | wc -l) -gt 0 ] \
				&& CPPFLAGS="$CPPFLAGS $inst_dir/include/$dir"
		done
	fi
	
	# Check specific file exists
	[ ! -z $inst_dir/$spec_fn ] && [ ! -f $inst_dir/$spec_fn ] \
		&& echo -e "Install $pkg_ver" >&2 \
		&& return 1
	
	# Update Env paths
	[ -d $inst_dir/bin ] && update_env -e PATH -a "$inst_dir/bin"
	[ -d $inst_dir/lib ] && update_env -e LD_LIBRARY_PATH -a "$inst_dir/lib"
	[ -d $inst_dir/lib64 ] && update_env -e LD_LIBRARY_PATH -a "$inst_dir/lib64"
	
	return 2
	
}
prep_env_cmd(){
	local tmp_ver nver tcmd apps_dir
	local cmd pkgs pkg status
	local verbose cnt
	
	verbose=1; cnt=0
	while [ ! -z "$1" ]; do
		case $1 in
			-a | --apps_dir )
				shift
				apps_dir="$1"
				;;
			-v | --verbose )
				verbose=0
				;;
			-p | --packages )
				while [ ! -z "$2" ]; do
					case $2 in
						-* )
							break
							;;
						* )
							pkgs[cnt]="$2"
							let cnt=cnt+1
							shift
					esac
				done
				;;
		esac
		shift
	done
	
	[ -z "$apps_dir" ] && apps_dir=$HOME/apps
	[ $verbose -eq 1 ] \
		&& echo -e "${yellow}Starting the environment command ...${NC}\t" >&2
	
	for pkg in "${pkgs[@]}"; do
		[ $verbose -eq 1 ] \
			&& echo -ne "${white}$pkg${NC}" >&2
		
		if [ "$pkg" == "tex" ]; then
			tcmd="install_tex -a $apps_dir -e"
			if [ -z "$cmd" ]; then
				cmd="$tcmd"
			else
				cmd="$cmd && $tcmd"
			fi
			echo -ne "(installed) " >&2; continue
		fi
		
		# Get available installed version(s)
		ls $apps_dir | grep -w $pkg \
			| sed "s|${pkg}-||g" > ~/pkgver.txt
		
		# Get system installed version
		status=$(which $pkg &> /dev/null; echo $?)
		nver=$(cat ~/pkgver.txt | wc -l)
		
		[ $nver -eq 0 ] && [ $status -eq 0 ] \
			&& [ $verbose -eq 1 ] \
			&& echo -ne "${orange}(detected) ${NC}" >&2 \
			&& continue
		
		if [ $nver -eq 1 ]; then
			tmp_ver=$(cat ~/pkgver.txt)
			tcmd="install_${pkg} -a $apps_dir -e -v $tmp_ver"
		elif [ $nver -eq 0 ] && [ ! $status -eq 0 ]; then
			[ $verbose -eq 1 ] && echo -ne "${red}(skipped) ${NC}" >&2
			continue
		else
			echo >&2
			echo -e "${cyan}For $pkg:" >&2
			cat ~/pkgver.txt | sort -t ',' -k1,1nr -k2,2nr -k3,3nr \
				| awk '{print "\t" $0}' >&2
			echo -ne "${NC}" >&2
			make_menu -c ${orange} -p "Pick a $pkg version"
			read tmp_ver
			tcmd="install_${pkg} -a $apps_dir -e -v $tmp_ver"
		fi
		new_rm ~/pkgver.txt
		
		if [ -z "$cmd" ]; then
			cmd="$tcmd"
		else
			cmd="$cmd && $tcmd"
		fi
		[ $verbose -eq 1 ] && echo -ne "(installed) " >&2
		
	done; echo >&2; new_rm ~/pkgver.txt
	[ $verbose -eq 1 ] \
		&& echo -e "${yellow}Completing the environment command ...${NC}" >&2
	
	echo $cmd
}

# Ready install functions
install_gcc(){
	local version pkg pkg_ver apps_dir status
	local url down_dir inst_dir ncores load_env
	
	install_args $@ -p gcc -d "9.4.0, 10.2.0"; status=$?
	[ $status -eq 2 ] && return 0; [ ! $status -eq 0 ] && return 1
	url=ftp://ftp.gnu.org/gnu/gcc/gcc-$version/${pkg}-$version.tar.gz
	
	# Load environment
	if [ $load_env -eq 1 ]; then
		[ ! -f $inst_dir/bin/gcc ] \
			&& echo -e "Run command 'install_gcc'" >&2 \
			&& return 1
		update_env -e PATH -a "$inst_dir/bin"
		update_env -e LD_LIBRARY_PATH -a "$inst_dir/lib"
		update_env -e LD_LIBRARY_PATH -a "$inst_dir/lib64"
		export CC=$inst_dir/bin/gcc
		export CXX=$inst_dir/bin/g++
		return 0
	fi
	
	extract_url -u $url -a $apps_dir -s $pkg_ver
	[ $? -eq 1 ] && return 0
	new_mkdir $inst_dir
	cd $inst_dir
	
	# Set environment
	clear_env
	local CPPFLAGS LDFLAGS; # CPPFLAGS=; LDFLAGS=;
	ncores=`get_ncores`; [ -z $ncores ] && ncores=1
	export OMP_NUM_THREADS=$ncores
	
	# Install prereqs
	cd $down_dir
	./contrib/download_prerequisites \
		--directory=$apps_dir >&2 \
		|| return 1
	rm -rf $apps_dir/*tar.bz2 $apps_dir/*tar.gz
	
	# Install
	cd $inst_dir
	# --enable-languages=c,c++,objc,obj-c++,java,fortran,ada,go,lto
	# --enable-languages=c,c++,objc,obj-c++,java,fortran,go,lto
	$down_dir/configure --prefix=$inst_dir \
		--enable-languages=c,c++,objc,obj-c++,fortran,go,lto \
		--disable-multilib --enable-bootstrap --enable-shared \
		--enable-threads=posix --enable-checking=release \
		--with-system-zlib --enable-__cxa_atexit --disable-libunwind-exceptions \
		--enable-gnu-unique-object --enable-linker-build-id \
		--with-linker-hash-style=gnu --enable-plugin --enable-initfini-array \
		--disable-libgcj --enable-gnu-indirect-function --with-tune=generic \
		--with-arch_32=x86-64 --build=x86_64-redhat-linux >&2 \
		&& make -j $ncores >&2 && make -j $ncores install >&2
	
	status=$?
	install_wrapup -s $status -i $inst_dir -d $down_dir
	return $status
	
	# Check if openmp features configured with installed compiler
	# echo | cpp -fopenmp -dM | grep -i open
	
}
install_libtool(){
	local version pkg pkg_ver apps_dir status cmd
	local url inst_dir down_dir load_env
	
	install_args $@ -p libtool -d 2.4.6; status=$?
	[ $status -eq 2 ] && return 0; [ ! $status -eq 0 ] && return 1
	url=https://ftpmirror.gnu.org/$pkg/libtool-$version.tar.gz
	
	# Load environment
	if [ $load_env -eq 1 ]; then
		[ ! -f $inst_dir/bin/libtool ] \
			&& echo -e "Install $pkg_ver" >&2 \
			&& return 1
		update_env -e PATH -a "$inst_dir/bin"
		update_env -e LD_LIBRARY_PATH -a "$inst_dir/lib"
		update_env -e CPATH -a "$inst_dir/include"
		# export CPATH=$inst_dir/include
		return 0
	fi
	
	extract_url -u $url -a $apps_dir -s $pkg_ver
	[ $? -eq 1 ] && return 0
	new_mkdir $inst_dir
	cd $inst_dir
	
	# Set environment
	clear_env
	local CPPFLAGS LDFLAGS; # CPPFLAGS=; LDFLAGS=;
	cmd=$(prep_env_cmd -a $apps_dir -p gcc)
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
install_ncurses(){
	local version v1 pkg pkg_ver apps_dir status
	local url inst_dir down_dir load_env cmd
	
	install_args $@ -p ncurses -d 6.2; status=$?
	[ $status -eq 2 ] && return 0; [ ! $status -eq 0 ] && return 1
	url=https://ftp.gnu.org/pub/gnu/ncurses/ncurses-${version}.tar.gz
	v1=$(echo $version | cut -d '.' -f1)
	
	# Load environment
	if [ $load_env -eq 1 ]; then
		[ ! -f $inst_dir/lib/ncurses.pc ] \
			&& return 1
		update_env -e PKG_CONFIG_PATH -a "$inst_dir/lib"
		pkg-config --exists --print-errors ncurses >&2 \
			|| return 1
		[ ! -f $inst_dir/bin/ncurses${v1}-config ] \
			&& echo -e "Install $pkg_ver" >&2 \
			&& return 1
		CPPFLAGS="$CPPFLAGS `pkg-config --cflags ncurses`"
		LDFLAGS="$LDFLAGS `pkg-config --libs ncurses`"
		update_env -e PATH -a "$inst_dir/bin"
		update_env -e LD_LIBRARY_PATH -a "$inst_dir/lib"
		return 0
	fi
	
	extract_url -u $url -a $apps_dir -s $pkg_ver
	[ $? -eq 1 ] && return 0
	new_mkdir $inst_dir
	cd $inst_dir
	
	# Set environment
	clear_env
	local CPPFLAGS LDFLAGS; # CPPFLAGS=; LDFLAGS=;
	cmd=$(prep_env_cmd -a $apps_dir -p gcc libtool)
	eval $cmd >&2 || return 1
	
	# Install
	cmd="$down_dir/configure"
	[ ! -z "$CPPFLAGS" ] && cmd="$cmd CPPFLAGS=\"$CPPFLAGS\""
	[ ! -z "$LDFLAGS" ] && cmd="$cmd LDFLAGS=\"$LDFLAGS\""
	cmd="$cmd --prefix=$inst_dir --with-libtool --enable-pc-files"
	cmd="$cmd --with-pkg-config-libdir=$inst_dir/lib >&2"
	cmd="$cmd && make >&2 && make install >&2"
	eval $cmd
	
	status=$?
	install_wrapup -s $status -i $inst_dir -d $down_dir
	return $status
	
}
install_readline(){
	local version pkg pkg_ver apps_dir status cmd
	local url inst_dir down_dir ncores load_env
	
	install_args $@ -p readline -d 6.0,8.0,8.1.2; status=$?
	[ $status -eq 2 ] && return 0; [ ! $status -eq 0 ] && return 1
	url=https://ftp.gnu.org/gnu/readline/readline-${version}.tar.gz
	
	# Load environment
	if [ $load_env -eq 1 ]; then
		CPPFLAGS="$CPPFLAGS -I$inst_dir/include -I$inst_dir/include/readline"
		LDFLAGS="$LDFLAGS -L$inst_dir/lib"
		update_env -e PKG_CONFIG_PATH -a "$inst_dir/lib/pkgconfig"
		update_env -e LD_LIBRARY_PATH -a "$inst_dir/lib"
		return 0
	fi
	
	extract_url -u $url -a $apps_dir -s $pkg_ver
	[ $? -eq 1 ] && return 0
	new_mkdir $inst_dir
	cd $inst_dir
	
	# Set environment
	clear_env
	local CPPFLAGS LDFLAGS; # CPPFLAGS=; LDFLAGS=;
	cmd=$(prep_env_cmd -a $apps_dir -p gcc libtool \
		ncurses)
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
install_xz(){
	local version pkg pkg_ver apps_dir status cmd
	local url inst_dir down_dir load_env
	
	install_args $@ -p xz -d 5.2.5; status=$?
	[ $status -eq 2 ] && return 0; [ ! $status -eq 0 ] && return 1
	url=https://tukaani.org/xz/xz-${version}.tar.gz
	
	# Load environment
	if [ $load_env -eq 1 ]; then
		[ ! -f $inst_dir/lib/pkgconfig/liblzma.pc ] \
			&& return 1
		update_env -e PKG_CONFIG_PATH -a "$inst_dir/lib/pkgconfig"
		pkg-config --exists --print-errors liblzma >&2 \
			|| return 1
		[ ! -f $inst_dir/bin/xz ] \
			&& echo -e "Install $pkg_ver" >&2 \
			&& return 1
		CPPFLAGS="$CPPFLAGS `pkg-config --cflags liblzma`"
		LDFLAGS="$LDFLAGS `pkg-config --libs liblzma`"
		update_env -e PATH -a "$inst_dir/bin"
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
	cmd=$(prep_env_cmd -a $apps_dir -p gcc libtool)
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
install_bzip2(){
	local version pkg pkg_ver apps_dir status
	local url inst_dir down_dir ncores load_env
	
	# Source: https://github.com/libimobiledevice/sbmanager/issues/1
	
	install_args $@ -p bzip2 -d 1.0.6; status=$?
	[ $status -eq 2 ] && return 0; [ ! $status -eq 0 ] && return 1
	url=https://sourceware.org/pub/bzip2/bzip2-$version.tar.gz
	
	# Load environment
	if [ $load_env -eq 1 ]; then
		[ ! -d $inst_dir/lib/pkgconfig ] \
			&& echo -e "pkgconfig issue for $pkg_ver" >&2 \
			&& return 1
		[ ! -f $inst_dir/bin/bzip2 ] \
			&& echo -e "Install $pkg_ver" >&2 \
			&& return 1
		update_env -e PKG_CONFIG_PATH -a "$inst_dir/lib/pkgconfig"
		pkg-config --exists --print-errors bzip2 >&2 \
			|| return 1
		CPPFLAGS="$CPPFLAGS `pkg-config --cflags bzip2`"
		LDFLAGS="$LDFLAGS `pkg-config --libs bzip2`"
		update_env -e PATH -a "$inst_dir/bin"
		update_env -e LD_LIBRARY_PATH -a "$inst_dir/lib"
		update_env -e CPATH -a "$inst_dir/include"
		return 0
	fi
	
	extract_url -u $url -a $apps_dir -s $pkg_ver
	[ $? -eq 1 ] && return 0
	cd $down_dir
	[ ! -f bzip2-1.0.6-install_docs-1.patch ] \
		&& wget https://gist.githubusercontent.com/steakknife/946f6ee331512a269145b293cbe898cc/raw/bzip2-1.0.6-install_docs-1.patch >&2
	[ ! -f bzip2recover-CVE-2016-3189.patch ] \
		&& wget https://gist.githubusercontent.com/steakknife/eceda09cae0cdb4900bcd9e479bab9be/raw/bzip2recover-CVE-2016-3189.patch >&2
	[ ! -f bzip2-man-page-location.patch ] \
		&& wget https://gist.githubusercontent.com/steakknife/42feaa223adb4dd7c5c85f288794973c/raw/bzip2-man-page-location.patch >&2
	[ ! -f bzip2-shared-make-install.patch ] \
		&& wget https://gist.githubusercontent.com/steakknife/94f8aa4bfa79a3f896a660bf4e973f72/raw/bzip2-shared-make-install.patch >&2
	[ ! -f bzip2-pkg-config.patch ] \
		&& wget https://gist.githubusercontent.com/steakknife/4faee8a657db9402cbeb579279156e84/raw/bzip2-pkg-config.patch >&2
	patch -u < bzip2-1.0.6-install_docs-1.patch >&2 \
		&& patch -u < bzip2recover-CVE-2016-3189.patch >&2 \
		&& patch -u < bzip2-man-page-location.patch >&2 \
		&& patch -u < bzip2-shared-make-install.patch >&2 \
		&& patch -u < bzip2-pkg-config.patch >&2
	[ ! $? -eq 0 ] && echo "Patch error, quitting" >&2 \
		&& return 1
	
	# Set environment
	clear_env
	local CPPFLAGS LDFLAGS; # CPPFLAGS=; LDFLAGS=;
	cmd=$(prep_env_cmd -a $apps_dir -p gcc libtool)
	eval $cmd >&2 || return 1
	
	# Install
	cd $down_dir
	make install PREFIX=$inst_dir >&2 \
		&& make clean >&2 \
		&& make -f Makefile-libbz2_so >&2
	status=$?
	
	mv bzip2-shared $inst_dir/bin/
	mv libbz2.so.${version} $inst_dir/lib/
	ln -s $inst_dir/lib/libbz2.so.${version} $inst_dir/lib/libbz2.so.1.0
	ln -s $inst_dir/lib/libbz2.so.${version} $inst_dir/lib/libbz2.so
	
	install_wrapup -s $status -i $inst_dir -d $down_dir
	return $status
	
}
install_pcre2(){
	local version pkg pkg_ver apps_dir status cmd
	local url inst_dir down_dir load_env
	
	install_args $@ -p pcre2 -d 10.37; status=$?
	[ $status -eq 2 ] && return 0; [ ! $status -eq 0 ] && return 1
	url=https://github.com/PhilipHazel/pcre2/releases
	url=$url/download/pcre2-${version}/pcre2-${version}.tar.gz
	
	# Load environment
	if [ $load_env -eq 1 ]; then
		[ ! -d $inst_dir/lib/pkgconfig ] \
			&& return 1
		update_env -e PKG_CONFIG_PATH -a "$inst_dir/lib/pkgconfig"
		pkg-config --exists --print-errors libpcre2-8 >&2 \
			|| return 1
		[ ! -f $inst_dir/bin/pcre2-config ] \
			&& echo -e "Install $pkg_ver" >&2 \
			&& return 1
		CPPFLAGS="$CPPFLAGS `pkg-config --cflags libpcre2-8`"
		LDFLAGS="$LDFLAGS `pkg-config --libs libpcre2-8`"
		update_env -e PATH -a "$inst_dir/bin"
		update_env -e LD_LIBRARY_PATH -a "$inst_dir/lib"
		return 0
	fi
	
	extract_url -u $url -a $apps_dir -s $pkg_ver
	[ $? -eq 1 ] && return 0
	new_mkdir $inst_dir
	cd $inst_dir
	
	# Set environment
	clear_env
	local CPPFLAGS LDFLAGS; # CPPFLAGS=; LDFLAGS=;
	cmd=$(prep_env_cmd -a $apps_dir -p gcc libtool)
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
install_zlib(){
	local version pkg pkg_ver apps_dir status cmd
	local url inst_dir down_dir load_env
	
	install_args $@ -p zlib -d 1.2.11; status=$?
	[ $status -eq 2 ] && return 0; [ ! $status -eq 0 ] && return 1
	# url=http://www.zlib.net/zlib-${version}.tar.gz
	url=https://ftp.osuosl.org/pub/libpng/src/zlib/zlib-${version}.tar.gz
	
	# Load environment
	if [ $load_env -eq 1 ]; then
		[ ! -f $inst_dir/lib/pkgconfig/zlib.pc ] \
			&& return 1
		update_env -e PKG_CONFIG_PATH -a "$inst_dir/lib/pkgconfig"
		pkg-config --exists --print-errors zlib >&2 \
			|| return 1
		[ ! -f $inst_dir/include/zlib.h ] \
			&& echo -e "Install $pkg_ver" >&2 \
			&& return 1
		CPPFLAGS="$CPPFLAGS `pkg-config --cflags zlib`"
		LDFLAGS="$LDFLAGS `pkg-config --libs zlib`"
		update_env -e LD_LIBRARY_PATH -a "$inst_dir/lib"
		return 0
	fi
	
	extract_url -u $url -a $apps_dir -s $pkg_ver
	[ $? -eq 1 ] && return 0
	new_mkdir $inst_dir
	cd $inst_dir
	
	# Set environment
	clear_env
	local CPPFLAGS LDFLAGS; # CPPFLAGS=; LDFLAGS=;
	cmd=$(prep_env_cmd -a $apps_dir -p gcc libtool)
	eval $cmd >&2 || return 1
	
	# Install
	$down_dir/configure --prefix=$inst_dir \
		&& make >&2 && make test >&2 \
		&& make install >&2
	
	status=$?
	install_wrapup -s $status -i $inst_dir -d $down_dir
	return $status
	
}
install_curl(){
	local version pkg pkg_ver apps_dir status cmd
	local url inst_dir down_dir load_env
	
	install_args $@ -p curl -d 7.72.0; status=$?
	[ $status -eq 2 ] && return 0; [ ! $status -eq 0 ] && return 1
	url=https://curl.haxx.se/download/curl-$version.tar.gz
	
	# Load environment
	if [ $load_env -eq 1 ]; then
		[ ! -f $inst_dir/lib/pkgconfig/libcurl.pc ] \
			&& return 1
		update_env -e PKG_CONFIG_PATH -a "$inst_dir/lib/pkgconfig"
		pkg-config --exists --print-errors libcurl >&2 \
			|| return 1
		[ ! -f $inst_dir/bin/curl-config ] \
			&& echo -e "Install $pkg_ver" >&2 \
			&& return 1
		CPPFLAGS="$CPPFLAGS `pkg-config --cflags libcurl`"
		LDFLAGS="$LDFLAGS `pkg-config --libs libcurl`"
		update_env -e PATH -a "$inst_dir/bin"
		update_env -e LD_LIBRARY_PATH -a "$inst_dir/lib"
		return 0
	fi
	
	extract_url -u $url -a $apps_dir -s $pkg_ver
	[ $? -eq 1 ] && return 0
	new_mkdir $inst_dir
	cd $inst_dir
	
	# Set environment
	clear_env
	local CPPFLAGS LDFLAGS; # CPPFLAGS=; LDFLAGS=;
	cmd=$(prep_env_cmd -a $apps_dir -p gcc libtool zlib)
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
install_libxml2(){
	local version pkg pkg_ver apps_dir status cmd
	local url inst_dir down_dir load_env
	
	install_args $@ -p libxml2 -d 2.9.2; status=$?
	[ $status -eq 2 ] && return 0; [ ! $status -eq 0 ] && return 1
	url=ftp://xmlsoft.org/libxml2/libxml2-${version}.tar.gz
	
	# Load environment
	if [ $load_env -eq 1 ]; then
		[ ! -f $inst_dir/lib/pkgconfig/libxml-2.0.pc ] \
			&& return 1
		update_env -e PKG_CONFIG_PATH -a "$inst_dir/lib/pkgconfig"
		pkg-config --exists --print-errors libxml-2.0 >&2 \
			|| return 1
		[ ! -f $inst_dir/bin/xml2-config ] \
			&& echo -e "Install $pkg_ver" >&2 \
			&& return 1
		CPPFLAGS="$CPPFLAGS `pkg-config --cflags libxml-2.0`"
		LDFLAGS="$LDFLAGS `pkg-config --libs libxml-2.0`"
		update_env -e PATH -a "$inst_dir/bin"
		return 0
	fi
	
	extract_url -u $url -a $apps_dir -s $pkg_ver
	[ $? -eq 1 ] && return 0
	new_mkdir $inst_dir
	cd $inst_dir
	
	# Set environment
	clear_env
	local CPPFLAGS LDFLAGS
	cmd=$(prep_env_cmd -a $apps_dir -p gcc libtool zlib xz)
	eval $cmd >&2 || return 1
	
	# Install
	cmd="$down_dir/configure --without-python"
	[ ! -z "$CPPFLAGS" ] && cmd="$cmd CPPFLAGS=\"$CPPFLAGS\""
	[ ! -z "$LDFLAGS" ] && cmd="$cmd LDFLAGS=\"$LDFLAGS\""
	cmd="$cmd --prefix=$inst_dir >&2"
	cmd="$cmd && make >&2 && make install >&2"
	eval $cmd
	
	status=$?
	install_wrapup -s $status -i $inst_dir -d $down_dir
	return $status
	
}
install_libpng(){
	local version pkg pkg_ver apps_dir status cmd
	local url inst_dir down_dir ncores load_env
	
	install_args $@ -p libpng -d 1.6.37; status=$?
	[ $status -eq 2 ] && return 0; [ ! $status -eq 0 ] && return 1
	url=https://download.sourceforge.net/libpng/libpng-${version}.tar.gz
	
	# Load environment
	if [ $load_env -eq 1 ]; then
		[ ! -f $inst_dir/lib/pkgconfig/libpng16.pc ] \
			&& return 1
		update_env -e PKG_CONFIG_PATH -a "$inst_dir/lib/pkgconfig"
		pkg-config --exists --print-errors libpng >&2 \
			|| return 1
		[ ! -f $inst_dir/bin/libpng16-config ] \
			&& echo -e "Install $pkg_ver" >&2 \
			&& return 1
		CPPFLAGS="$CPPFLAGS `pkg-config --cflags libpng`"
		LDFLAGS="$LDFLAGS `pkg-config --libs libpng`"
		update_env -e PATH -a "$inst_dir/bin"
		update_env -e LD_LIBRARY_PATH -a "$inst_dir/lib"
		return 0
	fi
	
	extract_url -u $url -a $apps_dir -s $pkg_ver
	[ $? -eq 1 ] && return 0
	new_mkdir $inst_dir
	cd $inst_dir
	
	# Set environment
	clear_env
	local CPPFLAGS LDFLAGS; # CPPFLAGS=; LDFLAGS=;
	cmd=$(prep_env_cmd -a $apps_dir -p gcc libtool)
	eval $cmd >&2 || return 1
	
	# Install
	$down_dir/configure CPPFLAGS="$CPPFLAGS" \
		LDFLAGS="$LDFLAGS" --prefix=$inst_dir >&2 \
		&& make >&2 && make install >&2
	
	status=$?
	install_wrapup -s $status -i $inst_dir -d $down_dir
	return $status
	
}
install_freetype(){
	local version pkg pkg_ver apps_dir status cmd
	local url inst_dir down_dir ncores load_env
	
	install_args $@ -p freetype -d 2.11.1; status=$?
	[ $status -eq 2 ] && return 0; [ ! $status -eq 0 ] && return 1
	url=http://download-mirror.savannah.gnu.org/releases
	url=$url/freetype/${pkg}-${version}.tar.gz
	
	# Load environment
	if [ $load_env -eq 1 ]; then
		[ ! -f $inst_dir/lib/pkgconfig/freetype2.pc ] \
			&& return 1
		update_env -e PKG_CONFIG_PATH -a "$inst_dir/lib/pkgconfig"
		pkg-config --exists --print-errors freetype2 >&2 \
			|| return 1
		CPPFLAGS="$CPPFLAGS `pkg-config --cflags freetype2`"
		LDFLAGS="$LDFLAGS `pkg-config --libs freetype2`"
		update_env -e PATH -a "$inst_dir"
		update_env -e LD_LIBRARY_PATH -a "$inst_dir/lib"
		return 0
	fi
	
	extract_url -u $url -a $apps_dir -s $pkg_ver
	[ $? -eq 1 ] && return 0
	new_mkdir $inst_dir
	cd $inst_dir
	
	# Set environment
	clear_env
	local CPPFLAGS LDFLAGS; # CPPFLAGS=; LDFLAGS=;
	cmd=$(prep_env_cmd -a $apps_dir -p gcc libtool)
	eval $cmd >&2 || return 1
	
	# Install
	$down_dir/configure CPPFLAGS="$CPPFLAGS" \
		LDFLAGS="$LDFLAGS" --prefix=$inst_dir >&2 \
		&& make >&2 && make install >&2
	
	status=$?
	install_wrapup -s $status -i $inst_dir -d $down_dir
	return $status
	
}
install_pixman(){
	local version pkg pkg_ver apps_dir status cmd
	local url inst_dir down_dir ncores load_env
	
	install_args $@ -p pixman -d 0.40.0; status=$?
	[ $status -eq 2 ] && return 0; [ ! $status -eq 0 ] && return 1
	url=https://www.cairographics.org/releases/pixman-${version}.tar.gz
	
	# Load environment
	if [ $load_env -eq 1 ]; then
		[ ! -f $inst_dir/lib/pkgconfig/pixman-1.pc ] \
			&& return 1
		update_env -e PKG_CONFIG_PATH -a "$inst_dir/lib/pkgconfig"
		pkg-config --exists --print-errors pixman-1 >&2 \
			|| return 1
		CPPFLAGS="$CPPFLAGS `pkg-config --cflags pixman-1`"
		LDFLAGS="$LDFLAGS `pkg-config --libs pixman-1`"
		update_env -e LD_LIBRARY_PATH -a "$inst_dir/lib"
		return 0
	fi
	
	extract_url -u $url -a $apps_dir -s $pkg_ver
	[ $? -eq 1 ] && return 0
	new_mkdir $inst_dir
	cd $inst_dir
	
	# Set environment
	clear_env
	ncores=`get_ncores`; [ -z $ncores ] && ncores=1
	local CPPFLAGS LDFLAGS
	cmd=$(prep_env_cmd -a $apps_dir -p gcc libtool)
	eval $cmd >&2 || return 1
	
	# Install
	$down_dir/configure CPPFLAGS="$CPPFLAGS" \
		LDFLAGS="$LDFLAGS" --prefix=$inst_dir >&2 \
		&& make >&2 && make install >&2
	
	status=$?
	install_wrapup -s $status -i $inst_dir -d $down_dir
	return $status
	
}
install_cairo(){
	local version pkg pkg_ver apps_dir status cmd
	local url inst_dir down_dir ncores load_env
	
	install_args $@ -p cairo -d 1.16.0; status=$?
	[ $status -eq 2 ] && return 0; [ ! $status -eq 0 ] && return 1
	url=https://www.cairographics.org/releases/cairo-${version}.tar.xz
	
	# Load environment
	if [ $load_env -eq 1 ]; then
		[ ! -f $inst_dir/lib/pkgconfig/cairo.pc ] \
			&& return 1
		update_env -e PKG_CONFIG_PATH -a "$inst_dir/lib/pkgconfig"
		pkg-config --exists --print-errors cairo >&2 \
			|| return 1
		[ ! -f $inst_dir/bin/cairo-trace ] \
			&& return 1
		CPPFLAGS="$CPPFLAGS `pkg-config --cflags cairo`"
		LDFLAGS="$LDFLAGS `pkg-config --libs cairo`"
		update_env -e PATH -a "$inst_dir/bin"
		update_env -e LD_LIBRARY_PATH -a "$inst_dir/lib"
		return 0
	fi
	
	extract_url -u $url -a $apps_dir -s $pkg_ver
	[ $? -eq 1 ] && return 0
	new_mkdir $inst_dir
	cd $inst_dir
	
	# Set environment
	clear_env
	ncores=`get_ncores`
	[ -z $ncores ] && ncores=1
	local CPPFLAGS LDFLAGS # CPPFLAGS=; LDFLAGS=;
	cmd=$(prep_env_cmd -a $apps_dir -p gcc libtool \
		libpng freetype pixman)
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
install_cmake(){
	local version v1 pkg pkg_ver apps_dir status cmd
	local url inst_dir down_dir load_env
	
	install_args $@ -p cmake -d 3.20.3; status=$?
	[ $status -eq 2 ] && return 0; [ ! $status -eq 0 ] && return 1
	url=https://github.com/Kitware/CMake/releases
	url=${url}/download/v${version}/cmake-${version}.tar.gz
	
	# Load environment
	if [ $load_env -eq 1 ]; then
		[ ! -f $inst_dir/bin/cmake ] \
			&& echo -e "Install $pkg_ver" >&2 \
			&& return 1
		update_env -e PATH -a "$inst_dir/bin"
		return 0
	fi
	
	extract_url -u $url -a $apps_dir -s $pkg_ver
	[ $? -eq 1 ] && return 0
	new_mkdir $inst_dir
	cd $inst_dir
	
	# Set environment
	clear_env
	local CPPFLAGS LDFLAGS; # CPPFLAGS=; LDFLAGS=;
	cmd=$(prep_env_cmd -a $apps_dir -p gcc libtool)
	eval $cmd >&2 || return 1
	
	# Install
	cmd="$down_dir/bootstrap"
	[ ! -z "$CPPFLAGS" ] && cmd="$cmd CPPFLAGS=\"$CPPFLAGS\""
	[ ! -z "$LDFLAGS" ] && cmd="$cmd LDFLAGS=\"$LDFLAGS\""
	cmd="$cmd --prefix=$inst_dir >&2"
	cmd="$cmd && make >&2 && make install >&2"
	eval $cmd
	
	status=$?
	install_wrapup -s $status -i $inst_dir -d $down_dir
	return $status
	
}
install_gperf(){
	local version pkg pkg_ver apps_dir status cmd
	local url inst_dir down_dir ncores load_env
	
	install_args $@ -p gperf -d 3.1; status=$?
	[ $status -eq 2 ] && return 0; [ ! $status -eq 0 ] && return 1
	url=http://ftp.gnu.org/pub/gnu/gperf/gperf-${version}.tar.gz
	
	# Load environment
	if [ $load_env -eq 1 ]; then
		[ ! -f $inst_dir/bin/gperf ] \
			&& echo -e "Install $pkg_ver" >&2 \
			&& return 1
		update_env -e PATH -a "$inst_dir/bin"
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
	cmd=$(prep_env_cmd -a $apps_dir -p gcc libtool)
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
install_expat(){
	local version v1 pkg pkg_ver apps_dir status
	local url inst_dir down_dir load_env cmd
	
	install_args $@ -p expat -d 2.4.1; status=$?
	[ $status -eq 2 ] && return 0; [ ! $status -eq 0 ] && return 1
	v1=$(echo $version | sed 's|\.|_|g')
	url=https://github.com/libexpat/libexpat/releases
	url=$url/download/R_$v1/expat-${version}.tar.gz
	
	# Load environment
	if [ $load_env -eq 1 ]; then
		[ ! -f $inst_dir/lib/pkgconfig/expat.pc ] \
			&& return 1
		update_env -e PKG_CONFIG_PATH -a "$inst_dir/lib/pkgconfig"
		pkg-config --exists --print-errors expat >&2 \
			|| return 1
		[ ! -f $inst_dir/bin/xmlwf ] \
			&& echo -e "Install $pkg_ver" >&2 \
			&& return 1
		CPPFLAGS="$CPPFLAGS `pkg-config --cflags expat`"
		LDFLAGS="$LDFLAGS `pkg-config --libs expat`"
		update_env -e PATH -a "$inst_dir/bin"
		update_env -e LD_LIBRARY_PATH -a "$inst_dir/lib"
		export EXPATLIBPATH=$inst_dir/lib
		export EXPATINCPATH=$inst_dir/include
		return 0
	fi
	
	extract_url -u $url -a $apps_dir -s $pkg_ver
	[ $? -eq 1 ] && return 0
	new_mkdir $inst_dir
	cd $inst_dir
	
	# Set environment
	clear_env
	local CPPFLAGS LDFLAGS; # CPPFLAGS=; LDFLAGS=;
	cmd=$(prep_env_cmd -a $apps_dir -p gcc libtool)
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


src_install=1

###

