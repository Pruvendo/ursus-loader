#!/usr/bin/bash

REPO="https://github.com/Pruvendo/pruvendo-flex-contract.git"
BRANCH="main"

function loadrepo() {
    REPODIR=`echo $REPO | sed -e 's/^.*\/\([^.]*\)[^/]*$/\1/'`
    PPWD=`pwd`
    if [ -d "../$REPODIR" ] ; then
        cd ../$REPODIR
	git stash
	git pull origin $BRANCH
	if [ $? -ne "0" ] ; then
	    echo "Pulling error $REPO"
	    exit 255
	fi
    else
	cd ..
	git clone $REPO
	if [ $? -ne "0" ] ; then
	    echo "Error cloning $REPO"
	    exit 255
	fi
	cd $REPODIR
	git checkout $BRANCH
    fi
    cd $PPWD
}

function compileit() {
    REPODIR=`echo $REPO | sed -e 's/^.*\/\([^.]*\)[^/]*$/\1/'`
    cp ./Makefile.flex ../$REPODIR/Makefile
    cd ../$REPODIR
    #dune clean && dune build && opam install -y .
    eval $(opam env)
    find . -name "*.v" -print >> _CoqProject
    make
    if [ $? -ne "0" ] ; then
	echo "Compilation error"
    fi
}

bash ./ursus-loader.sh && loadrepo && compileit