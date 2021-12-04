#!/usr/bin/bash

UDIR=../ursus
export UDIR

COQV="8.13.0"
export COQV

OCAML="4.12.0"
export OCAML

function clean() {
    rm -rf $UDIR
    sudo apt remove -y opam
}

function clonerepos() {
    PWDD="$(pwd)"
    for i in `cat repos-list` ; do
	cd $UDIR
	REPODIR=`echo $i | sed -e 's/[^/]*\/\([^.]*\).*$/\1/'`
	if [ -d "$REPODIR" ] ; then
	    cd $REPODIR
	    git pull origin master
	    if [ $? -ne 0 ] ; then
		echo "Pull failed $i"
		exit 255
	    fi
	else
	    git clone $i
	    if [ $? -ne 0  ] ; then
		echo "Bad repository $i"
		exit 255
	    fi 
	fi
	cd "$PWDD"
    done
}

function createrepos() {
    if [ ! -d "$UDIR" ] ; then
	mkdir $UDIR
    fi
    clonerepos
}

function exists() {
    type "$1" >/dev/null 2>/dev/null
}

function installcc() {
    exists cc
    if [ $? -ne "0" ] ; then
	sudo apt-get -y install gcc
    fi
}


function installopam() {
    exists opam
    if [ $? -ne "0" ] ; then
	echo "Installing opam"
	sudo add-apt-repository -y ppa:avsm/ppa
	sudo apt -y update
	sudo apt -y install opam
	opam -y init
	eval $(opam env)
	opam switch create --jobs=1 with-coq $OCAML
	opam switch with-coq
    fi
    opam update
    opam upgrade
}

function installcoq() {
    opam pin add -y coq $COQV
}

if [[ -n "$1" ]] && [[ $1 == "clean" ]] ; then
    clean
    exit
fi

createrepos && installcc && installopam && installcoq