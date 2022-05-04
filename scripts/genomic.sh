#!/bin/sh

[ ! -z $src_genomic ] && [ $src_genomic -eq 1 ] \
	&& return 0

[ -z "$git_dir" ] && git_dir=$(cd $(dirname $BASH_SOURCE)/../..; pwd)

for fn in install; do
	. $git_dir/baSHic/scripts/$fn.sh
done

# Installation functions
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
install_strelka2(){
	local version v1 pkg pkg_ver apps_dir status cmd
	local url inst_dir down_dir load_env tmp_dir
	
	install_args $@ -p strelka -d 2.9.10; status=$?
	[ $status -eq 2 ] && return 0; [ ! $status -eq 0 ] && return 1
	url=https://github.com/Illumina/strelka/releases/download
	url=$url/v$version/strelka-$version.release_src.tar.bz2
	
	# Load environment
	if [ $load_env -eq 1 ]; then
		if [ ! -f $inst_dir/bin/configureStrelkaSomaticWorkflow.py ] \
			|| [ ! -f $inst_dir/bin/configureStrelkaGermlineWorkflow.py ]; then
			echo -e "Install $pkg_ver" >&2 \
				&& return 1
		fi
		update_env -e PATH -a "$inst_dir/bin"
		return 0
	fi
	
	extract_url -u $url -a $apps_dir -s $pkg_ver
	[ $? -eq 1 ] && return 0
	tmp_dir=$(ls $apps_dir/downloads | grep $pkg)
	tmp_dir=$apps_dir/downloads/$tmp_dir
	mv $tmp_dir $down_dir
	new_mkdir $inst_dir
	cd $inst_dir
	
	# Set environment
	clear_env
	local CPPFLAGS LDFLAGS
	cmd=$(prep_env_cmd -a $apps_dir -p gcc libtool \
		zlib cmake boost)
	eval $cmd >&2 || return 1
	
	# Install
	cmd="$down_dir/configure"
	cmd="$cmd --prefix=$inst_dir"
	status=$(which cmake > /dev/null; echo $?)
	[ $status -eq 0 ] && cmd="$cmd --with-cmake=$(which cmake)"
	# cmd="$cmd && make -C $inst_dir >&2"
	cmd="$cmd >&2 && make install >&2"
	eval $cmd
	
	status=$?
	install_wrapup -s $status -i $inst_dir -d $down_dir
	[ ! $status -eq 0 ] && return 1
	
	# Run demos for somatic/germline workflows to double check everything
	echo -e "${cyan}Run Strelka2 test ...${NC}" >&2
	local test_dir=$HOME/strelka_test
	new_rm $test_dir
	new_mkdir $test_dir
	cd $test_dir
	bash $inst_dir/bin/runStrelkaSomaticWorkflowDemo.bash >&2 \
		&& bash $inst_dir/bin/runStrelkaGermlineWorkflowDemo.bash >&2
	status=$?
	if [ $status -eq 0 ]; then
		echo -e "${cyan}Strelka2 test complete${NC}" >&2
		cd
		new_rm $test_dir && return $status
	else
		echo -e "${red}Error with Strelka2 demos!${NC}" >&2 \
			&& return $status
	fi
	
}

# Execution functions
run_strelka2_soma(){
	local gatk_dir strelka_dir nbam tbam ref out_dir ncores
	local regions confirm config_fn var_dir status
	
	confirm=0
	while [ ! -z $1 ]; do
		case $1 in
			-s | --strelka_dir )
				shift
				strelka_dir="$1"
				;;
			-g | --gatk_dir )
				shift
				gatk_dir="$1"
				;;
			-t | --tbam )
				shift
				tbam="$1"
				;;
			-n | --nbam )
				shift
				nbam="$1"
				;;
			-r | --ref )
				shift
				ref="$1"
				;;
			-o | --out_dir )
				shift
				out_dir="$1"
				;;
			-c | --ncores )
				shift
				ncores="$1"
				;;
			--regions )
				shift
				regions="$1"
				;;
			--confirm )
				confirm=1
				;;
			--config_fn )
				shift
				config_fn="$1"
				;;
		esac
		shift
	done
	
	# Check inputs
	[ -z $strelka_dir ] && echo "Add -s <Strelka2 dir>" >&2 && return 1
	[ -z $gatk_dir ] 		&& echo "Add -g <GATK dir>" >&2 && return 1
	[ -z $tbam ] 				&& echo "Add -t <tumor bam>" >&2 && return 1
	[ -z $nbam ] 				&& echo "Add -n <normal bam>" >&2 && return 1
	[ -z $ref ] 				&& echo "Add -r <reference genome>" >&2 && return 1
	[ -z $out_dir ] 		&& echo "Add -o <output dir>" >&2 && return 1
	[ -z $ncores ] 			&& echo "Add -c <number of threads/cores>" >&2 && return 1
	var_dir=$out_dir/results/variants
	[ -s $out_dir/somatic.vcf.gz ] && return 0
	
	# Prepare regions
	[ ! -z "$regions" ] \
		&& regions=$(echo $regions | sed 's|^|,|g' | sed 's|,| --region |g' | sed 's|^ ||g')
	
	# Clear out any older stuff
	new_rm $out_dir/results $out_dir/workspace \
		$out_dir/runWorkflow* $out_dir/workflow*
	
	# Configure strelka stuff
	local cmd
	cmd="$strelka_dir/bin/configureStrelkaSomaticWorkflow.py"
	cmd="$cmd --normalBam $nbam --tumorBam $tbam --referenceFasta $ref"
	cmd="$cmd --disableEVS --exome"
	[ ! -z $config_fn ] && cmd="$cmd --config $config_fn"
	[ ! -z "$regions" ] && cmd="$cmd $regions"
	cmd="$cmd --runDir $out_dir >&2"
	
	if [ $confirm -eq 1 ]; then
		local resp
		echo -e "`date`: Strelka Command:\n\n$cmd\n\n" >&2
		make_menu -y -p "Does this look good?"; read resp
		[ -z $resp ] && return 1
		[ ! -z $resp ] && [ ! $resp -eq 1 ] && return 1
	fi
	
	# Run variant calling
	if [ ! -f $var_dir/somatic.snvs.vcf.gz ] || [ ! -f $var_dir/somatic.indels.vcf.gz ]; then
		eval $cmd
		status=$?
		[ ! $status -eq 0 ] && echo -e "`date`: Strelka configure error" >&2 && return 1
	
		export OMP_NUM_THREADS=$ncores
		$out_dir/runWorkflow.py -m local -j $ncores >&2
		status=$?
		[ $status -eq 0 ] \
			&& echo -e "`date`: Strelka2 completed" >&2 \
			|| echo -e "`date`: Strelka2 incomplete" >&2
		[ ! $status -eq 0 ] && return 1
	fi
	
	# Merge SNV and INDEL vcfs
	export OMP_NUM_THREADS=1
	$gatk_dir/gatk MergeVcfs \
		--INPUT $var_dir/somatic.snvs.vcf.gz \
		--INPUT $var_dir/somatic.indels.vcf.gz \
		--OUTPUT $out_dir/somatic.vcf.gz >&2
	status=$?
	[ ! $status -eq 0 ] && echo -e "`date`: Error with MergeVcfs" >&2 && return 1
	if [ ! -s $out_dir/somatic.vcf.gz ]; then
		new_rm $out_dir/somatic.vcf.gz
		echo -e "`date`: Empty vcf" >&2 && return 1
	fi
	
	# Clean up Strelka stuff
	new_rm $out_dir/results $out_dir/workspace \
		$out_dir/runWorkflow* $out_dir/workflow*
	
	return 0
	
}


src_genomic=1

###

