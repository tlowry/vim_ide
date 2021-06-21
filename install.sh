#!/bin/bash

# find the current location of this script
SCRIPT_DIR=`dirname ${BASH_SOURCE[0]-$0}`
CUR_LOC=`cd $SCRIPT_DIR && pwd`

MAIN_CONFS=(
	vim/vim_ide.vimrc 
)

MAIN_BUNDLES=(
    ale
)

JAVA_BUNDLES=(
    vim-Javacomplete2
)

append_if_missing(){
    grep -qxF "$1" "$2" || echo "$1" >> "$2"
}

create_and_append(){
 touch -c "$2"
 append_if_missing "$1" "$2"
}

ul () {
    [ -L "$1" ] && unlink "$1"
}

make_link () {
    dest_dir=`dirname $2` 2> /dev/null
    [ -f $dest_dir ] || mkdir -p $dest_dir
    ul "$2"
    [ -L $2 ] || ln -s $1 $2
}

# Remove a literal line from a file (no regex)
# e.g del_lit_line "hello" hello.txt - creates hello.txt.bak
del_lit_line () {
    num=`fgrep -n "$1" "$2" | cut -d':' -f1`
    [ -z "$num" ] || sed -i.bak -e "$num"d "$2"
}

ul_bin () {
    bin_dir="$HOME/.local/bin"
    dots_bin="$CUR_LOC/bin"
    for file in $bin_dir/*
    do
        readlink -f "$file" | grep -q "$dots_bin" && ul "$bin_dir/$file"
    done
}

# make user scripts available system wide
ln_bin () {
    
    bin_dir="$HOME/.local/bin"
    mkdir -p "$bin_dir" 2> /dev/null
    
    if [ `ls -lA $CUR_LOC/bin | wc -l` -gt 3 ]; then
        for file in $CUR_LOC/bin/*
        do
            dest_file="$bin_dir/"`basename $file`
            make_link "$file" "$dest_file"
        done

        make_link "$CUR_LOC"/bin/lib "$bin_dir"/lib
    else
        echo "no binaries to link"
    fi
}

ul_apps () {
    app_dir="$XDG_DATA_HOME/applications"
    dot_apps="$CUR_LOC/share/applications"
    for file in $app_dir/*
    do
        [ -L "$file" ] && readlink -f "$file" | grep -q "$dot_apps" && unlink "$file"
    done
}

# install apps
ln_apps () {

    app_dir="$XDG_DATA_HOME/applications"
    mkdir -p "$app_dir" 2> /dev/null

    if [ `ls -lA $CUR_LOC/share/applications | wc -l` -gt 3 ]; then
        for file in $CUR_LOC/share/applications/*
        do
            dest_file="$app_dir/"`basename $file`
            ul "$dest_file"
            make_link "$file" "$dest_file"
        done
    else
        echo "no applications to link"
    fi
}

ln_conf () {
    dest=`echo $1 | sed 's/.*\/config\///g'`
    dest=$XDG_CONFIG_HOME/$dest
    make_link "$1" "$dest"
}

ul_conf () {
    dest=`echo $1 | sed 's/.*\/config\///g'`
    dest=$XDG_CONFIG_HOME/$dest
    ul "$dest"
}

ul_bundle () {
    echo "ul bundle $1"
    dest=`echo $1 | sed 's/.*\/config\/vim//g'`
    dest="$HOME/.vim/bundle/$dest"
    ul "$dest"
}

# common install for all platforms
install_base () {
    echo "install base"

    # Don't overwrite existing config (create if missing and source)
    create_and_append ":so $HOME/.config/vim/vim_ide.vimrc" ~/.vimrc 

    # soft link config to standard location
    # vim pathogen plugins
    mkdir -p ~/.vim/bundle
   
    # pull down any plugins stored as submodules
    git submodule update --init

    for x in ${MAIN_BUNDLES[@]};do
        x1="$CUR_LOC/config/vim/bundle/$x"
        x2=~/.vim/bundle/"${x##*/}"
        echo "linking $x1 -> $x2"
        make_link "$CUR_LOC/config/vim/bundle/$x" ~/.vim/bundle/"${x##*/}"
    done
    
    # more straightforward directory mapped configs
    for x in ${MAIN_CONFS[@]};do
        ln_conf "$CUR_LOC/config/$x"
    done

    # necessary components for rust completion
    rust_extra=`which rls`
    [ -z "$rust_extra" ] && rustup component add rls rust-analysis rust-src
    
    # python components
    pyr='which pyright'
    [ -z "$pyr" ] || `npm install -g pyright`
}

ul_vim () {
    #ul ~/.vim/autoload/pathogen.vim

    # unlink any installed plugins

    for x in ${MAIN_BUNDLES[@]};do
        ul_bundle "$x"
    done
}

uninstall () {
    echo "uninstall"
    del_lit_line ":so $HOME/.config/vim/vim_ide.vimrc" ~/.vimrc 
    
    for x in ${MAIN_CONFS[@]};do
        ul_conf "$x"
    done

    ul_vim
}

usage () {
    echo "use install.sh < -r optional to uninstall >"
}

while [ "$1" != "" ]; do
    case $1 in
        -r | --remove )         REMOVE=1
                ;;
        -h | --help )           usage
                                exit
                ;;
        * )                     ;; 
    esac
    shift
done

# sudo/su workaround
if [[ "$USER" != "root" ]] && echo "$XDG_CONFIG_HOME" | grep -q "root"
then
	export XDG_CONFIG_HOME=~/.config
	export XDG_DATA_HOME="$HOME/.local/share"
	export XDG_CACHE_HOME="$HOME/.cache"
	export XDG_BIN_HOME="$HOME/.local/bin"
else
    [ -z "$XDG_CONFIG_HOME" ] && export XDG_CONFIG_HOME=~/.config
	[ -z "$XDG_DATA_HOME" ] && export XDG_DATA_HOME="$HOME/.local/share"
	[ -z "$XDG_CACHE_HOME" ] && export XDG_CACHE_HOME="$HOME/.cache"
	[ -z "$XDG_BIN_HOME" ] && export XDG_BIN_HOME="$HOME/.local/bin"
fi

[ -d "$XDG_CONFIG_HOME" ] || mkdir -p "$XDG_CONFIG_HOME"
[ -d "$XDG_DATA_HOME/applications" ] || mkdir -p "$XDG_DATA_HOME/applications"
[ -d "$XDG_CACHE_HOME" ] || mkdir -p "$XDG_CACHE_HOME"
[ -d "$XDG_BIN_HOME" ] || mkdir -p "$XDG_BIN_HOME"

if [ -z "$REMOVE" ]; then install_base ; else uninstall ; fi
