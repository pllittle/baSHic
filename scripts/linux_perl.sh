#!/bin/sh

[ ! -z $src_perl ] && [ $src_perl -eq 1 ] \
	&& return 0

[ -z "$git_dir" ] && git_dir=$(cd $(dirname $BASH_SOURCE)/../..; pwd)

for fn in install; do
	. $git_dir/baSHic/scripts/$fn.sh
done

# Perl Functions
install_perl(){
	local version v1 pkg pkg_ver apps_dir status cmd
	local url inst_dir down_dir load_env
	
	install_args $@ -p perl -d 5.32.0; status=$?
	[ $status -eq 2 ] && return 0; [ ! $status -eq 0 ] && return 1
	v1=`echo $version | cut -d '.' -f1`
	url=https://www.cpan.org/src/${v1}.0/perl-${version}.tar.gz
	
	# Load environment
	if [ $load_env -eq 1 ]; then
		[ ! -f $inst_dir/bin/perl ] \
			&& echo "Install $pkg_ver" >&2 && return 1
		update_env -e PATH -a "$inst_dir/bin"
		eval "$($inst_dir/bin/perl -I $inst_dir/lib/perl$v1 \
			-Mlocal::lib=$inst_dir)" >&2
		[ ! $? -eq 0 ] && echo "Error loading perl" >&2 && return 1
		update_env -e LD_LIBRARY_PATH -a "$inst_dir/lib"
		return 0
	fi
	
	extract_url -u $url -a $apps_dir -s $pkg_ver
	[ $? -eq 1 ] && return 0
	mv $down_dir $inst_dir
	cd $inst_dir
	
	clear_env
	local CPPFLAGS LDFLAGS; # CPPFLAGS=; LDFLAGS=;
	cmd=$(prep_env_cmd -a $apps_dir -p gcc libtool)
	eval $cmd >&2 || return 1
	
	# Install
	cmd="./Configure -des"
	cmd="$cmd -Dprefix=$inst_dir >&2"
	cmd="$cmd && make >&2 && make test >&2"
	cmd="$cmd && make install >&2"
	eval $cmd
	
	status=$?
	[ $status -eq 0 ] && echo "Install cpanm" >&2
	[ ! -f $inst_dir/bin/cpanm ] \
		&& $inst_dir/bin/cpan App::cpanminus >&2
	status=$?
	[ ! $status -eq 0 ] && echo "Error with cpanm" >&2
	[ $status -eq 0 ] && echo "Install local::lib" >&2 \
		&& $inst_dir/bin/cpanm --local-lib=$inst_dir local::lib >&2
	status=$?
	[ ! $status -eq 0 ] && echo "Error with local::lib" >&2
	install_wrapup -s $status -i $inst_dir -d $down_dir
	return $status
	
}
install_perl_modules(){
	local apps_dir inst_dir dep deps
	local module mods cmd0 cmd cnt cnt2 status
	
	cnt=0; cnt2=0
	while [ ! -z "$1" ]; do
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
			-d | --deps )
				while [ ! -z "$2" ]; do
					case $2 in
						-* )
							break
							;;
						* )
							deps[cnt2]="$2"
							let cnt2=cnt2+1
							shift
							;;
					esac
				done
				;;
		esac
		shift
	done
	
	[ -z "$apps_dir" ] && apps_dir=$HOME/apps
	[ -z "${mods[0]}" ] && echo "Add -m <array of perl modules>" >&2 && return 1
	
	# Set environment
	clear_env
	local CPPFLAGS LDFLAGS
	cmd0="prep_env_cmd -a $apps_dir -p gcc libtool perl"
	if [ ! -z ${deps[0]} ]; then
		for dep in ${deps[@]}; do
			cmd0="$cmd0 $dep"
		done
	fi
	cmd=$($cmd0)
	eval $cmd >&2 || return 1
	inst_dir=$(cd $(which perl | sed 's|perl$||'); cd ..; pwd)
	
	# Install Perl modules
	for module in "${mods[@]}"; do
		echo -e "\n\n${white}Install module = $module${NC}" >&2
		cpanm --local-lib=$inst_dir $module >&2
		status=$?
		if [ ! $status -eq 0 ]; then
			echo -e "${red}Failed: module = $module${NC}" >&2 && return 1
		else
			echo -e "Success: module = $module" >&2
		fi
	done
	
	return 0
}
uninstall_perl_modules(){
	echo "Update this function" >&2 && return 1
	local version apps_dir inst_dir module mods
	local cnt status
	
	cnt=0
	while [ ! -z $1 ]; do
		case $1 in
			-a | --apps_dir )
				shift
				apps_dir="$1"
				;;
			-v | --version )
				shift
				version="$1"
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
	
	[ -z $apps_dir ] 	&& apps_dir=$HOME/apps
	[ -z $version ] 	&& echo "Add -v <version>" >&2 && return 1
	[ -z "$mods" ]		&& echo "Add -m <array of modules>" >&2 && return 1
	inst_dir=$apps_dir/perl-$version
	
	# Load environment
	install_perl -v $version -e \
		|| return 1
	
	for module in "${mods[@]}"; do
		echo -e "\n\nUninstall module = $module" >&2
		cpanm --uninstall $module >&2
		status=$?
		if [ ! $status -eq 0 ]; then
			echo -e "Failed: module = $module" >&2 && return 1
		else
			echo -e "Success: module = $module" >&2
		fi
	done
	
	return 0
}
remove_cpanm_module(){
	[ -z $1 ] && return 1
	local version=$1 # e.g. 5.32.0
	local module=$2
	local PATH=~/perl-${version}/bin:$PATH
	install_cpanm $version
	cpanm --uninstall $module >&2
}

src_perl=1

###

