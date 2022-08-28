#!/bin/sh

[ ! -z $src_R ] && [ $src_R -eq 1 ] && return 0

[ -z "$git_dir" ] && git_dir=$(cd $(dirname $BASH_SOURCE)/../..; pwd)

for fn in install linux_latex \
	linux_perl linux_python; do
	. $git_dir/baSHic/scripts/$fn.sh
done

# Installation
chk_CRAN(){
	local url cmd tmp_cnt orig_dir
	
	orig_dir=$(pwd)
	cd $HOME
	url=https://cran.r-project.org/src/base/R-4/
	cmd="curl '$url' --fail -s -L -D header.txt -o body.html"
	eval $cmd >&2
	[ ! $? -eq 0 ] && cd $orig_dir \
		&& echo -e "${red}Error with curl${NC}" >&2 && return 1
	
	# Check header
	tmp_cnt=$(grep "^HTTP" header.txt | tail -n 1 \
		| grep "200 OK" | wc -l)
	[ ! $tmp_cnt -eq 1 ] && echo -e "${red}Error with curl header${NC}" >&2 \
		&& new_rm header.txt body.html && cd $orig_dir && return 1
	
	# Parse body.html
	cmd="cat body.html | sed 's|^ *||g'"
	cmd="$cmd | tr '\n' ' ' | sed 's|</tr>|</tr>\n|g'"
	cmd="$cmd | sed 's|^ *<tr>|<tr>|g'"
	cmd="$cmd | grep 'tar.gz' | sed 's|</td>|</td>\n|g'"
	cmd="$cmd | sed 's|<td \(.*\)>\(.*\)</td>|<td>\\2</td>|g'"
	cmd="$cmd | grep -v nbsp | sed 's|<td>\(.*\)</td>|\\1|g'"
	cmd="$cmd | tr '\n' ' ' | sed 's|> <|><|g'"
	cmd="$cmd | sed 's|</tr>|</tr>\n|g' | sed 's|^<tr>||g'"
	cmd="$cmd | sed 's|</tr>||g' | sed 's|.tar.gz||g'"
	cmd="$cmd | sed 's|<a \(.*\)>\(.*\)</a>|\\2|g'"
	cmd="$cmd | tr -s ' ' | cut -d ' ' -f1-4 | sed 's| |\t|g'"
	# echo $cmd >&2
	echo -e "${purple}Most recent R versions${NC}" >&2
	eval $cmd | column -ts $'\t' | awk '{print "   " $0}' >&2
	new_rm header.txt body.html
	
	cd $orig_dir
	
}
install_R(){
	local version v1 pkg pkg_ver apps_dir status
	local url inst_dir down_dir ncores resp cmd
	
	chk_CRAN
	
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
	# icu
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

# Execution
run_R(){
	# Run R batch, interactive, or quick
	local script job_name job_time mem part ncores
	local R_dir cmd node enodes use apps_dir version
	job_time=01:00:00; mem=3000; ncores=1
	
	while [ ! -z "$1" ]; do
		case $1 in
			-a | --apps_dir )
				shift
				apps_dir="$1"
				;;
			-c | --ncores )
				shift
				ncores="$1"
				;;
			-e | --enodes )
				shift
				enodes="$1"
				;;
			-m | --mem )
				shift
				mem="$1"
				;;
			-n | --job_name )
				shift
				job_name="$1"
				;;
			-o | --node )
				shift
				node="$1"
				;;
			-p | --part )
				shift
				part="$1"
				;;
			-s | --script )
				shift
				script="$1"
				;;
			-t | --job_time )
				shift
				job_time="$1"
				;;
			-u | --use )
				shift
				use="$1"
				;;
			-v | --version )
				shift
				version="$1"
				;;
		esac
		shift
	done
	
	[ -z "$use" ] && echo "Add -u <R use, either batch/int/quick/script>" >&2 && return 1
	[ -z "$apps_dir" ] && apps_dir=$HOME/apps
	
	check_array $use batch int quick script
	[ ! $? -eq 0 ] && echo "Error with -u argument" >&2 && return 1
	
	# Get R version
	if [ -z "$version" ]; then
		num_Rinst=$(ls $apps_dir | grep "^R-" | wc -l)
		[ $num_Rinst -eq 0 ] && echo "Install R locally!" >&2 && return 1
		[ $num_Rinst -ge 2 ] && echo "Add -v <version>" >&2 && return 1
		version=$(ls $apps_dir | grep "^R-" | sed 's|^R-||')
	fi
	
	# Define R_dir
	if check_array $curr_host longleaf dogwood bioinf hutch; then
		[ $(echo $LD_LIBRARY_PATH | grep "gcc" | wc -l) -eq 0 ] \
			&& cmd=$(prep_env_cmd -p gcc tex libtool \
			ncurses readline bzip2 xz pcre2 zlib curl libxml2 libpng \
			freetype pixman cairo gperf fontconfig cmake) \
			&& eval $cmd >&2
			# icu
		R_dir=$apps_dir/R-$version/bin
	elif check_array $curr_host uthsc; then
		[ $(echo $LD_LIBRARY_PATH | grep "pixman" | wc -l) -eq 0 ] \
			&& cmd=$(prep_env_cmd -p gcc tex libtool \
			ncurses readline bzip2 xz pcre2 zlib curl libxml2 libpng \
			freetype pixman cairo gperf cmake Python fontconfig) \
			&& eval $cmd >&2
			# icu
		R_dir=$apps_dir/R-$version/bin
	else
		print_notOpt
		return 1
	fi
	[ ! -d $R_dir ] && echo -e "R_dir = $R_dir missing" >&2 && return 1
	[ ! -f $R_dir/R ] && echo -e "$R_dir/R missing" >&2 && return 1
	
	if [ "$use" == "batch" ]; then
		[ -z $script ] && echo "Add -s <R script>" >&2 && return 1
		[ -f $script.Rout ] && rm $script.Rout
		[ -f $script.log ] && rm $script.log
		[ -z "$job_name" ] && echo "Add -n <R job name>" >&2 && return 1
		
		# Run job
		if check_array $curr_host longleaf dogwood diamond \
			bioinf hutch uthsc uthsc_compute; then
			
			cmd="sbatch --nodes=1 --ntasks=1 -c $ncores"
			[ ! -z "$part" ] && cmd="$cmd -p $part"
			[ ! -z "$job_time" ] && cmd="$cmd -t ${job_time}"
			[ ! -z "$node" ] && [ "$node" != "none" ] && cmd="$cmd -w $node"
			[ "$node" == "none" ] && [ ! -z "$enodes" ] && cmd="$cmd -x $enodes"
			cmd="$cmd --mem=${mem} -o $script.log --job-name='$job_name'"
			cmd="$cmd $R_dir/R --vanilla CMD BATCH --quiet --no-save $script.R $script.Rout"
			# echo $cmd >&2
			eval $cmd
			
		elif [ "$curr_host" == "killdevil" ]; then
			
			bsub -R "span[hosts=1]" -n $ncores -M $mem -q $job_time \
				-J $job_name -o $script.log $R_dir/R --vanilla CMD BATCH \
				--quiet --no-save $script.R $script.Rout
		
		else
			print_notOpt
			return 1
		fi
		
	elif [ "$use" == "int" ]; then
		mem=; ncores=;
		make_menu -p "How much memory in megabytes? (e.g. 1000,5000)"; read mem
		make_menu -p "How many threads/cores? (e.g. 1,5,10)"; read ncores
		
		[ -z $mem ] && mem=3000
		[ -z $ncores ] && ncores=1
		job_name=Rint
		
		# Set part and job_time
		if [ "$curr_host" == "longleaf" ]; then
			part=interact; job_time=8:00:00
		elif [ "$curr_host" == "dogwood" ]; then
			part=cleanup_queue; job_time=1-00:00:00
		elif [ "$curr_host" == "bioinf" ]; then
			part=allnodes; job_time=8:00:00
		elif [ "$curr_host" == "diamond" ]; then
			part=int; job_time=8:00:00
		elif [ "$curr_host" == "hutch" ]; then
			part=campus-new; job_time=02-00:00:00
		elif check_array $curr_host uthsc; then
			part=node; job_time=07-00:00:00
		else
			print_notOpt
			return 1
		fi
		
		srun -N 1 -n 1 -c $ncores --time=$job_time \
			--mem="$mem" --job-name="$job_name" \
			--pty -p $part $R_dir/R --vanilla
	
	elif [ "$use" == "quick" ]; then
		
		$R_dir/R --vanilla
	
	elif [ "$use" == "script" ]; then
		
		$R_dir/R --vanilla CMD BATCH $script.R $script.Rout
		
	fi
	
}


src_R=1

###
