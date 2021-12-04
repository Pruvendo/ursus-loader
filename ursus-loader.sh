#!/usr/bin/bash

UDIR=../ursus
export UDIR

COQV="8.13.2"
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
	REPODIR=`echo $i | sed -e 's/^.*\/\([^.]*\)[^/]*$/\1/'`
	if [ -d "$REPODIR" ] ; then
	    cd $REPODIR
	    git pull origin flex
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
	    cd $REPODIR
	    git checkout flex
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


function installmake() {
    exists make
    if [ $? -ne "0" ] ; then
    sudo apt-get -y install make
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
    fi
    SWITCHCOQ=`opam switch | grep "with-coq" | grep $OCAML | wc -l`
    if [ $SWITCHCOQ -eq "0"  ] ; then
	opam switch create --jobs=1 with-coq $OCAML
	opam switch with-coq
        opam update
	opam upgrade
    fi
}


function installcoq() {
    eval $(opam env)
    exists coqc
    COQCEXISTS=$?
    if [ $COQCEXISTS -eq "0" ] ; then
	CURCOQV=`coqc -v | grep Coq | sed -e 's/^[^8]*\([0-9.]*\).*$/\1/'`
	echo $CURCOQV
    fi
    if [[ $COQCEXISTS -ne "0" ]] || [[ "$COQV" != "$CURCOQV" ]] ; then
        opam pin add -y coq $COQV
	eval $(opam env)
    fi
}

function installdune() {
    exists dune
    if [ $? -ne "0" ] ; then
	opam install dune
    fi
}

function installelpi() {
    ELPI=`opam list | grep elpi | wc -l`
    if [ $ELPI -eq "0" ] ; then
	opam repo add coq-released https://coq.inria.fr/opam/released
	opam update
	opam repository add coq-released --all-switches
	opam upgrade
	opam install coq-elpi
    fi
}

function compileall() {
PWDD="$(pwd)"
    for i in `cat repos-list` ; do
	cd $UDIR
	REPODIR=`echo $i | sed -e 's/^.*\/\([^.]*\)[^/]*$/\1/'`
	cd $REPODIR
	echo "Compiling $REPODIR"
	sleep 1
	dune clean && dune build && opam install -y .
	if [ $? -ne "0" ] ; then
	    echo "Compilation failed"
	    exit 255
	fi
	cd "$PWDD"
    done

}

if [[ -n "$1" ]] && [[ $1 == "clean" ]] ; then
    clean
    exit
fi

createrepos && installcc && installmake && installopam && installcoq && installdune && installelpi && compileall && exit 0
exit 255