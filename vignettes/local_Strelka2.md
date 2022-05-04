<div align="left">
<img src="https://img.shields.io/badge/Script-%23121011.svg?style=square&logo=gnu-bash&logoColor=green&label=Strelka2" height="100" />
</div>

To install Strelka2 locally, follow the steps below. My code is based on [this link](https://github.com/Illumina/strelka/blob/v2.9.x/docs/userGuide/quickStart.md).

```Shell
# Set your working directory
work_dir=
[ -z "$work_dir" ] && echo "Set work_dir!" && return 1
[ ! -d $work_dir ] && mkdir $work_dir

# Make github/app directories
git_dir=$work_dir/github
[ ! -d $git_dir ] && mkdir $git_dir

apps_dir=$work_dir/apps
[ ! -d $apps_dir ] && mkdir $apps_dir

# Clone/Pull repo
cd $git_dir
[ ! -d baSHic ] && git clone https://github.com/pllittle/baSHic.git
[ -d baSHic ] && cd baSHic && git pull

# Source environment script
. $git_dir/baSHic/scripts/getEnv.sh
[ ! $? -eq 0 ] && echo "Some error at getEnv" && return 1
	# If there's an error here, getEnv.sh needs to be updated

# Source genomic script
. $git_dir/baSHic/scripts/genomic.sh

# Install/Test Strelka2
install_strelka2 -a $apps_dir
```

If there are errors, follow the output or drop me an issue.

# Common Errors

