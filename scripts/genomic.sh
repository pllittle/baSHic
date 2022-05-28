#!/bin/sh

[ ! -z $src_genomic ] && [ $src_genomic -eq 1 ] \
	&& return 0

[ -z "$git_dir" ] && git_dir=$(cd $(dirname $BASH_SOURCE)/../..; pwd)

for fn in install linux_perl; do
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
	cmd=$(prep_env_cmd -a $apps_dir -p gcc libtool \
		bzip2 xz zlib curl)
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
install_VEP(){
	# Source: https://m.ensembl.org/info/docs/tools/vep/script/vep_download.html
	local url apps_dir inst_dir perl_dir status
	local release module resp cmd
	
	while [ ! -z "$1" ]; do
		case $1 in
			-a | --apps_dir )
				shift
				apps_dir="$1"
				;;
			-g | --genome )
				shift
				genome="$1"
				;;
			-r | --release )
				shift
				release="$1"
				;;
		esac
		shift
	done
	
	[ -z $apps_dir ] 	&& apps_dir=$HOME/apps
	if [ -z $release ]; then
		make_menu -p "Which release of VEP to install on? (e.g. 105, 106)"
		read release
	fi
	[ -z "$release" ] && echo "Error release missing, exitting" >&2 && return 1
	inst_dir=$apps_dir/vep-$release
	
	cd $apps_dir
	if [ ! -d $inst_dir ]; then
		git clone https://github.com/Ensembl/ensembl-vep.git >&2
		mv $apps_dir/ensembl-vep $inst_dir
	fi
	
	cd $inst_dir
	git pull >&2
	git checkout release/$release >&2
	
	if [ 1 -eq 2 ]; then
		$perl_dir/bin/perl -I $perl_dir/lib/perl5 -Mlocal::lib=$perl_dir
		eval "$($perl_dir/bin/perl -I $perl_dir/lib/perl5 -Mlocal::lib=$perl_dir)"
		
		module=DBD::mysql
		
		# Remove one module
		$perl_dir/bin/cpanm --uninstall --local-lib=$perl_dir $module
		
		# Install one module
		$perl_dir/bin/cpanm --local-lib=$perl_dir $module
		
		# Check if module successfully installed and location
		$perl_dir/bin/perl -I $perl_dir/lib/perl5 -e "use $module" # check for error
		$perl_dir/bin/perldoc -l $module # location
		
	fi
	
	# Install Perl modules
	install_perl_modules -a $apps_dir \
		-d expat db bzip2 xz zlib curl htslib \
		-m DBI DBD::mysql Try::Tiny XML::Parser XML::Twig \
		XML::DOM ExtUtils::CBuilder DB_File DB_File::HASHINFO \
		BioPerl Test::Warnings Bio::DB::HTS
		# Archive::Zip
	status=$?
	[ ! $status -eq 0 ] && echo -e "${red}Some perl module failed${NC}" >&2 \
		&& return 1
	
	# Set environment
	clear_env
	local CPPFLAGS LDFLAGS
	cmd=$(prep_env_cmd -a $apps_dir -p gcc libtool perl \
		bzip2 xz zlib curl expat db htslib)
	eval $cmd >&2 || return 1
	
	# VEP install and download cached database files (# 460) and plugins (gnomad)
	cd $inst_dir
	cmd="perl INSTALL.pl --NO_HTSLIB --CACHEDIR $inst_dir"
	eval $cmd >&2
	[ ! $? -eq 0 ] && echo -e "Error in VEP installation" >&2 && return 1
	
	return 0
	
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
	
	[ ! $($strelka_dir/bin/configureStrelkaSomaticWorkflow.py -h > /dev/null; echo $?) -eq 0 ] \
		&& echo "Error: Strelka2 not properly installed or environment isn't setup yet" >&2 \
		&& return 1
	
	new_mkdir $out_dir
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
down_cosmic(){
	local genome version email pw url authstr downurl out_fn out_dir
	local tmp_fn=~/.down
	
	while [ ! -z $1 ]; do
		case $1 in
			-g | --genome )
				shift
				genome="$1"
				;;
			-v | --version )
				shift
				version="$1"
				;;
			-o | --out_dir )
				shift
				out_dir="$1"
				;;
		esac
		shift
	done
	
	[ -z $genome ] 	&& echo "Add -g <genome>, like GRCh37" >&2 && return 1
	[ -z $version ] && echo "Add -v <version>, like 90" >&2 && return 1
	[ -z $out_dir ] && echo "Add -o <out dir>" >&2 && return 1
	new_mkdir $out_dir
	cd $out_dir
	
	url=https://cancer.sanger.ac.uk/cosmic/file_download
	url=$url/$genome/cosmic/v$version/VCF/CosmicCodingMuts.vcf.gz
	# out_fn=`echo $url | sed 's|/|\n|g' | tail -n 1`
	out_fn=CosmicCodingMuts_${genome}_v${version}.vcf.gz
	
	if [ ! -f $out_fn ]; then
		make_menu -p "COSMIC/Sanger Email? (e.g. abc@gmail.com)"; read email
		make_menu -p "COSMIC/Sanger Password?"; read -s pw
		echo >&2
		authstr=`echo -e "${email}:${pw}" | base64`
		curl -H "Authorization: Basic ${authstr}" ${url} > $tmp_fn
		downurl=`cat $tmp_fn | tail -n 1 | sed 's|"||g' \
			| cut -d ':' --complement -f1 \
			| sed 's|}$||g'`
		rm $tmp_fn
		echo $downurl > cosmic_downurl.txt
		curl "${downurl}" -o $out_fn >&2
		[ ! $? -eq 0 ] && echo -e "${red}Error in COSMIC download${NC}" >&2 && return 1
		new_rm cosmic_downurl.txt
	fi
	
}
get_COSMIC_canonical(){
	local genome version cosm_dir
	local hts_dir cosmic_fn
	
	while [ ! -z $1 ]; do
		case $1 in
			-g | --genome )
				shift
				genome="$1"
				;;
			-v | --version )
				shift
				version="$1"
				;;
			-c | --cosm_dir )
				shift
				cosm_dir="$1"
				;;
			-h | --hts_dir )
				shift
				hts_dir="$1"
				;;
		esac
		shift
	done
	
	[ -z $genome ] 		&& echo "Add -g <genome>, e.g. GRCh37/GRCh38" >&2 && return 1
	[ -z $version ] 	&& echo "Add -v <version>, e.g. 94/95" >&2 && return 1
	[ -z $hts_dir ] 	&& echo "Add -h <hts_dir>" >&2 && return 1
	[ -z $cosm_dir ] 	&& echo "Add -c <COSMIC dir>" >&2 && return 1
	
	down_cosmic -g $genome -v $version -o $cosm_dir
	cosmic_fn=$cosm_dir/CosmicCodingMuts_${genome}_v${version}
	
	if [ ! -f $hts_dir/bin/bgzip ] \
		|| [ ! -f $hts_dir/bin/tabix ]; then
		echo "Install htslib!" >&2 && return 1
	fi
	
	if [ ! -f ${cosmic_fn}_canonical.vcf.gz ] \
		|| [ ! -f ${cosmic_fn}_canonical.vcf.gz.tbi ]; then
		
		[ ! -f $cosmic_fn.vcf.gz ] \
			&& down_cosmic -g $genome -v $version -o $cosm_dir
		
		echo -e "`date`: Removing some rows" >&2
		zgrep -v "GENE=.*_ENST[0-9]*;" $cosmic_fn.vcf.gz \
			> ${cosmic_fn}_canonical.vcf
		
		echo -e "`date`: Running bgzip ..." >&2
		$hts_dir/bin/bgzip -c ${cosmic_fn}_canonical.vcf \
			> ${cosmic_fn}_canonical.vcf.gz
		[ ! $? -eq 0 ] && echo "Error with bgzip" >&2 && return 1
		
		echo -e "`date`: Running tabix ..." >&2
		$hts_dir/bin/tabix -p vcf ${cosmic_fn}_canonical.vcf.gz
		[ ! $? -eq 0 ] && echo "Error with tabix" >&2 && return 1
		new_rm ${cosmic_fn}_canonical.vcf $cosmic_fn.vcf.gz
		
		echo -e "`date`: Finished downloading/processing COSMIC file for VEP" >&2
		
	else
		echo -e "`date`: File already available ^_^" >&2
		
	fi
	
	return 0
}
run_VEP(){
	local fasta_fn vep_dir genome status vep_rel cmd
	local input_fn output_fn vep_fields cosmic_fn ncores
	local vep_cache0 vep_cache vep_cache_dir
	
	ncores=1
	while [ ! -z "$1" ]; do
		case $1 in
			-c | --cosmic_fn )
				shift
				cosmic_fn="$1"
				;;
			-f | --fasta_fn )
				shift
				fasta_fn="$1"
				;;
			-g | --genome )
				shift
				genome="$1"
				;;
			-i | --input_fn )
				shift
				input_fn="$1"
				;;
			-n | --ncores )
				shift
				ncores="$1"
				;;
			-o | --output_fn )
				shift
				output_fn="$1"
				;;
			-r | --vep_rel )
				shift
				vep_rel="$1"
				;;
			-v | --vep_dir )
				shift
				vep_dir="$1"
				;;
			-a | --vep_cache )
				shift
				vep_cache="$1"
				;;
		esac
		shift
	done
	
	# Check inputs
	[ -z $cosmic_fn ] && echo "Add -c <cosmic_fn>" >&2 && return 1
	[ -z $fasta_fn ] 	&& echo "Add -f <fasta_fn>" >&2 && return 1
	[ -z $genome ] 		&& echo "Add -g <genome, e.g. GRCh37>" >&2 && return 1
	[ -z $input_fn ] 	&& echo "Add -i <input_fn>" >&2 && return 1
	[ -z $output_fn ] && echo "Add -o <output_fn>" >&2 && return 1
	[ -z $vep_dir ] 	&& echo "Add -v <vep_dir>" >&2 && return 1
	[ -z $vep_rel ] 	&& echo "Add -r <vep release number>" >&2 && return 1
	
	# Check VEP installed
	[ ! -d $vep_dir/vep ] && echo "Error: VEP missing" >&2 && return 1
	[ ! $($vep_dir/vep --help > /dev/null; echo $?) -eq 0 ] \
		&& echo "Error: VEP not installed or environment not setup" >&2 \
		&& return 1
	
	if [ -z "$vep_cache" ]; then
		make_menu -c ${yellow} -p "Which cache? Select a number:" \
			-o "1) VEP" "2) RefSeq" "3) Merged = VEP + RefSeq"
		read -t 10 vep_cache0
		[ -z "$vep_cache0" ] && echo "Error: missing input" >&2 && return 1
		check_array $vep_cache0 1 2 3
		[ ! $? -eq 0 ] && echo "Error: not a valid cache option" >&2 && return 1
		[ $vep_cache0 -eq 1 ] && vep_cache="vep"
		[ $vep_cache0 -eq 2 ] && vep_cache="refseq"
		[ $vep_cache0 -eq 3 ] && vep_cache="merged"
	fi
	check_array $vep_cache vep refseq merged
	[ ! $? -eq 0 ] && echo "Error: Not a valid cache" >&2 && return 1
	
	# Check cache+release+db exists
	vep_cache_dir=$vep_dir/homo_sapiens
	[ "$vep_cache" != "vep" ] && vep_cache_dir="${vep_cache_dir}_${vep_cache}"
	[ ! -d $vep_cache_dir ] && echo "Error: VEP cache species missing" >&2 && return 1
	[ ! $(ls $vep_cache_dir | grep "^${vep_rel}_${genome}$" | wc -l) -eq 1 ] \
		&& echo -e "Error: ${vep_rel}_${genome} missing" >&2 && return 1
	
	# If output file exists, done
	[ -f $output_fn.gz ] && echo "Final output already exists" >&2 && return 0
	
	echo -e "`date`: Start VEP" >&2
	
	# Run VEP
	vep_fields=IMPACT,Consequence,SYMBOL,HGVSc,HGVSp,AF
	vep_fields="$vep_fields,gnomAD_AF,COSMIC,COSMIC_CNT"
	vep_fields="$vep_fields,COSMIC_LEGACY_ID"
	
	export OMP_NUM_THREADS=$ncores
	cmd="$vep_dir/vep --format vcf --species homo_sapiens"
	cmd="$cmd -i $input_fn -o $output_fn --fork $ncores"
	cmd="$cmd --cache --dir_cache $vep_dir --cache_version $vep_rel"
	[ "$vep_cache" != "vep" ] && cmd="$cmd --$vep_cache"
	cmd="$cmd --assembly $genome --fasta $fasta_fn --force_overwrite"
	cmd="$cmd --no_stats --domains --hgvs --af --af_gnomad --vcf"
	cmd="$cmd --custom $cosmic_fn,COSMIC,vcf,exact,0,CNT,LEGACY_ID"
	cmd="$cmd --fields \"$vep_fields\""
	eval $cmd >&2
	status=$?
	
	if [ ! $status -eq 0 ]; then
		echo "Error in VEP" >&2
		new_rm $output_fn
		return 1
	fi
	echo -e "`date`: End VEP" >&2
	
	export OMP_NUM_THREADS=1
	[ ! $(which gzip > /dev/null; echo $?) -eq 0 ] && echo "No gzip found" >&2 && return 1
	echo -e "`date`: gzip VEP annotation" >&2
	gzip $output_fn
	new_rm $output_fn
	
	return 0
	
}


src_genomic=1

###

