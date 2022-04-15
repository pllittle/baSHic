# Local R installation

To install R locally, follow the steps below.

```Shell
# Make github dir
cd $HOME
[ ! -d github ] && mkdir github

# Clone/Pull repo
cd github
[ ! -d baSHic ] && git clone https://github.com/pllittle/baSHic.git
[ -d baSHic ] && git pull

# Source environment script
. ~/github/baSHic/scripts/getEnv.sh
	# If there's an error here, getEnv.sh needs to be updated

# Source R and dependency function scripts
. ~/github/baSHic/scripts/install_R.sh

# Install R
install_R
```

If there are errors, follow the output or drop me an issue

