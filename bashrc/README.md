Just my own .bashrc.

# Setup

1. clone this repository on your machine
2. use `stow` to symlink the bashinit scripts into `~/.config/bashinit/`
3. add `source ~/.config/bashinit/bashinit.sh` script to your `~/.bashrc` or `~/.bash_profile` - or whatever

### Installation

You can install the bashinit dotfiles and configure your `.bashrc` using the `just` command. This method ensures idempotency, meaning it will only make changes if necessary.

```bash
just install-bashinit
```

Alternatively, for manual installation:

```bash
cd /path/to/bashrc/
stow --dotfiles -t ~ -S bashinit
cat <<EOF >> ~/.bashrc
source ~/.config/bashinit/bashinit.sh
EOF
```

### On Mac OS
`.bashrc` needs to be added to the `.profile` file in Mac OS. This is because OS X does not read `.bashrc` on start. Instead it reads the following (in order):
1.  /etc/profile
2.  ~/.bash_profile
3.  ~/.bash_login
4.  ~/.profile

Execute the following to add to `.profile`

    echo "source ~/.bashrc" >> .profile

### VirtualEnvWrapper

This includes the shell startup lines for python virtualenvwrapper. You can read more about virtualenvwrapper here: http://virtualenvwrapper.readthedocs.io/en/latest/install.html
