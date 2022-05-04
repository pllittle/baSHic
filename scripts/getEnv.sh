#!/bin/sh

[ ! -z "$curr_host" ] && return 0

[ -z "$git_dir" ] && git_dir=$(cd $(dirname $BASH_SOURCE)/../..; pwd)

for fn in base; do
	. $git_dir/baSHic/scripts/$fn.sh
done

get_host(){
	local cluster
	
	case $HOSTNAME in
		*lbgcluster* )
			cluster=LBG
			;;
		*killdevil* )
			cluster=killdevil
			;;
		*longleaf* )
			cluster=longleaf
			;;
		*bioinf* )
			cluster=bioinf
			;;
		*diamond* )
			cluster=diamond
			;;
		*dogwood* )
			cluster=dogwood
			;;
		*rhino* | *gizmo* )
			cluster=hutch
			;;
		*snail* )
			cluster=snail
			;;
		*compute-0* )
			cluster=uthsc_compute
			;;
		*login0* )
			cluster=uthsc
			;;
		*instance* )
			cluster=instcbio
			;;
		*ip-172-31-4-89* )
			cluster=instAWScbio
			;;
	esac
	
	if [ -z $cluster ] && [ ! -z $CLUSTER ]; then
		cluster=$CLUSTER
	fi
	
	if [ -z $cluster ]; then
			case $HOME in
				*nas/longleaf* )
					cluster=longleaf
					;;
			esac
	fi
	
	if [ -z $cluster ]; then
		chk_srun=$(which srun &> /dev/null; echo $?)
		chk_sbatch=$(which sbatch &> /dev/null; echo $?)
		cluster="slurm"
	fi
	
	if [ -z $cluster ]; then
		echo "No code for this cluster!" >&2
		sleep 2; exit 1
	fi
	
	echo $cluster
	
}
[ -z "$curr_host" ] && curr_host=$(get_host)

update_env(){
	local path_fn env_var addpaths rmpaths path cmd
	local input_var out_var cnt add_stat reset_path
	reset_path=0
	
	while [ ! -z $1 ]; do
		case $1 in
			-f | --path_fn )
				shift
				path_fn="$1"
				;;
			-e | --env_var )
				shift
				env_var="$1"
				;;
			-a | --addpaths )
				cnt=0
				while [ ! -z "$2" ]; do
					case $2 in
						-* )
							break
							;;
						* )
							addpaths[cnt]=`echo $2 | sed 's|~|$HOME|'`
							let cnt=cnt+1
							shift
							;;
					esac
				done
				;;
			# later add a case to remove directories from variable
			-r | --rmpaths )
				cnt=0
				while [ ! -z "$2" ]; do
					case $2 in
						-* )
							break
							;;
						* )
							rmpaths[cnt]=`echo $2 | sed 's|~|$HOME|'`
							let cnt=cnt+1
							shift
							;;
					esac
				done
				;;
			-n | --reset )
				shift
				reset_path=1
				;;
		esac
		shift
	done
	
	# Reset path
	if [ $reset_path -eq 1 ]; then
		# echo -e "`date`: Start reset env paths" >&2
		local rPATH
		rPATH=`echo $PATH | sed 's|:|\n|g' \
			| grep -v -E "$HOME/anaconda|$HOME/apps|/app/software" \
			| tr '\n' ':' | sed 's|:$||g'`
		export PATH="$rPATH"
		
		rPATH=`echo $LD_LIBRARY_PATH | sed 's|:|\n|g' \
			| grep -v -E "$HOME/anaconda|$HOME/apps" \
			| tr '\n' ':' | sed 's|:$||g'`
		export LD_LIBRARY_PATH="$rPATH"
		# echo -e "`date`: Finish reset env paths" >&2
		return 0
	fi
	
	[ -z $env_var ] && echo "Add -e <env var>" >&2 && return 1
	# [ -z $path_fn ] && echo "Add -f <path filename>" >&2 && return 1
	if [ -z $path_fn ]; then
		check_array $curr_host longleaf dogwood \
			bioinf uthsc uthsc_compute hutch \
			&& path_fn=~/.${SLURM_JOB_NAME}.paths
		[ -z $path_fn ] && echo "Add code for path_fn in update_env!" >&2 && return 1
	fi
	
	# Write to path_fn
	if check_array $env_var PATH LD_LIBRARY_PATH PYTHONPATH \
		LIBRARY_PATH PKG_CONFIG_PATH CPATH MANPATH BOOST_ROOT; then
		cmd="input_var=\$$env_var"
		eval $cmd
	else
		print_notOpt
		return 1
	fi
	
	echo $input_var | sed 's|:|\n|g' \
		| sed "s|~|$HOME|g" | sed '/^$/d' \
		| uniq > $path_fn
	
	# Add to environmental variable
	add_stat=0
	if [ ${#addpaths[@]} -gt 0 ]; then
		for path in "${addpaths[@]}"; do
			if [ `grep -w "^$path$" $path_fn | wc -l` -gt 0 ]; then
				# path already in env_var, don't change
				continue
			else
				# path not in env_var, change by appending to the top of path_fn
				if [ `cat $path_fn | wc -l` -eq 0 ]; then
					echo -e "$path" > $path_fn
				else
					sed -i "1s|^|$path\n|" $path_fn
				fi
				add_stat=1
			fi
		done
	fi
	
	# Remove from environmental variable
	rm_stat=0
	if [ ${#rmpaths[@]} -gt 0 ]; then
		for path in "${rmpaths[@]}"; do
			if [ `grep -w "$path" $path_fn | wc -l` -gt 0 ]; then
				# path in env_var, remove
				sed -i "\|$path|d" $path_fn
				rm_stat=1
			fi
		done
	fi
	
	# Set env_var
	out_var=`cat $path_fn | tr '\n' ':' | sed "s|:$||g"`
	
	# Clean up
	new_rm $path_fn
	
	# If nothing changed, exit
	[ $add_stat -eq 0 -a $rm_stat -eq 0 ] && return 0
	
	# Update env_var
	if check_array $env_var PATH LD_LIBRARY_PATH PYTHONPATH \
		LIBRARY_PATH PKG_CONFIG_PATH CPATH MANPATH BOOST_ROOT; then
		cmd="export $env_var=$out_var"
		eval $cmd
	else
		print_notOpt
		return 1
	fi
	
}
get_ncores(){
	local ncores
	
	check_array $curr_host bioinf longleaf uthsc \
		uthsc_compute slurm && ncores=$SLURM_CPUS_PER_TASK
	[ -z $ncores ] && ncores=1
	echo $ncores
}
clear_env(){
	local env_var cmd resp
	
	make_menu -y -p "Reset environment?"; read resp
	[ -z "$resp" ] && return 0
	[ ! -z "$resp" ] && [ "$resp" != "1" ] && return 0
	
	check_array $curr_host hutch && ml purge
	cmd="unset"
	for env_var in PKG_CONFIG_PATH PYTHONPATH CPPFLAGS \
		LDFLAGS CC CXX CPATH PERL5LIB PERL_LOCAL_LIB_ROOT \
		PERL_MB_OPT PERL_MM_OPT MANPATH BOOST_ROOT; do
		
		cmd="$cmd $env_var"
	done
	
	eval $cmd
	update_env -n
}

###
