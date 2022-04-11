#!/bin/sh

[ ! -z $src_perl ] && [ $src_perl -eq 1 ] \
	&& return 0

for fn in install; do
	. $HOME/github/baSHic/scripts/$fn.sh
done

# Perl Functions
install_cpanm(){
	# For installing perl modules easily
	local perl_dir
	
	while [ ! -z $1 ]; do
		case $1 in
			-p | --perl_dir )
				shift
				perl_dir="$1"
				;;
		esac
		shift
	done
	 
	[ -z $perl_dir ] && echo "Add -p <perl_dir>" >&2 && return 1
	[ ! -f $perl_dir/bin/cpan ] && install_perl
	[ ! -f $perl_dir/bin/cpanm ] && $perl_dir/bin/cpan App::cpanminus >&2
}
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
		# update_env -e PATH -a "$inst_dir/bin"
		eval "$($inst_dir/bin/perl -I $inst_dir/lib/perl5 -Mlocal::lib=$inst_dir)"
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
	install_wrapup -s $status -i $inst_dir -d $down_dir
	return $status
	
}
install_perl_modules(){
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
	
	# Install Perl modules
	[ ! -f $inst_dir/bin/perl ] && install_perl -v $version >&2 && return 1
	[ ! -f $inst_dir/bin/cpanm ] && install_cpanm -p $inst_dir >&2 && return 1
	
	# Load environment
	install_perl -v $version -e \
		|| return 1
	
	for module in "${mods[@]}"; do
		echo -e "\n\nInstall module = $module" >&2
		$inst_dir/bin/cpanm --local-lib=$inst_dir $module >&2
		status=$?
		if [ ! $status -eq 0 ]; then
			echo -e "Failed: module = $module" >&2 && return 1
		else
			echo -e "Success: module = $module" >&2
		fi
	done
	
	return 0
}
uninstall_perl_modules(){
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

