#!/bin/bash
#
#                              Copyright (C) 2015 by Rafael Santiago
#
# This is free software. You can redistribute it and/or modify under
# the terms of the GNU General Public License version 2.
#
# "snail.sh"
#       by Rafael Santiago
#
# Description: a simple script which scans ELF dependencies.
#

SNAIL_TEMP_DIR=".snail"

SNAIL_LD_LINUX_32=""

SNAIL_LD_LINUX_64=""

SHOULD_REMOVE_INTERP=0

INTERP_PATH=""

function snail_find_app_deps() {
    printf "\t\t@@@ - Inspecting %s's dependencies...\n" $1
    for libpath in $(LD_TRACE_LOADED_OBJECTS=1 $1 | grep ".*/" | sed s/.*=\>// | sed s/\(.*//)
    do
	filename=$(echo ${libpath} | sed s/.*\\///)
	file_exists=$(ls -1 ${SNAIL_TEMP_DIR}/${filename} 2>/dev/null | wc -l)
	if [ ${file_exists} -eq 0 ] ; then
	    printf "\t\t\t@@@ - copying: %s... " ${filename}
    	    cp ${libpath} ${SNAIL_TEMP_DIR}/ &>/dev/null
    	    if [ $? -eq 0 ] ; then
    		printf "copied.\n"
    	    else
    		printf "copy error... aborting.\n"
    		fini_snail
    		exit 1
    	    fi
    	else
    	    printf "\t\t\t@@@ - already copied: %s.\n" ${filename}
	fi
    done
    printf "\t\t@@@ - done.\n"
}

function snail_find_so_deps() {
    ld_so=${SNAIL_LD_LINUX_32}
    if [ $(get_platform_arch) -eq 64 ] ; then
        ld_so=${SNAIL_LD_LINUX_64}
    fi
    printf "\t\t@@@ - Inspecting %s's dependencies...\n" $1
    for libpath in $(LD_TRACE_LOADED_OBJECTS=1 ${ld_so} ./$1 | grep ".*/" | sed s/.*=\>// | sed s/\(.*//)
    do
        filename=$(echo ${libpath} | sed s/.*\\///)
        file_exists=$(ls -1 ${SNAIL_TEMP_DIR}/${filename} 2>/dev/null | wc -l)
        if [ ${file_exists} -eq 0 ] ; then
            printf "\t\t\t@@@ - copying: %s... " ${filename}
            cp ${libpath} ${SNAIL_TEMP_DIR}/ &>/dev/null
            if [ $? -eq 0 ] ; then
                printf "copied.\n"
            else
                printf "copy error... aborting.\n"
                fini_snail
                exit 1
            fi
        else
            printf "\t\t\t@@@ - already copied: %s.\n" ${filename}
        fi
    done
    printf "\t\t@@@ - done.\n"
    filename=$(echo ${ld_so} | sed s/.*\\///)
    file_exists=$(ls -1 ${SNAIL_TEMP_DIR}/${filename} 2>/dev/null | wc -l)
    if [ ${file_exists} -eq 0 ] ; then
        printf "\t\t@@@ - copying: %s... " ${filename}
        if [ $? -eq 0 ] ; then
            printf "copied.\n"
        else
            printf "copy error... aborting.\n"
            fini_snail
            exit 1
        fi
    fi
}

function is_a_so() {
    retval=0
    if [ $(file $1 | grep ".*: ELF.*shared object," | wc -l) -eq 1 ] ; then
        retval=1
    fi
    echo ${retval}
}

function get_elf_arch() {
    retval=32
    if [ $(file $1 | grep ".*: ELF 64-bit" | wc -l) -eq 1 ] ; then
        retval=64
    fi
    echo ${retval}
}

function find_ld_linux32() {
    SNAIL_LD_LINUX_32=$(find / -name "ld-linux.so.2" -executable | tail -1)
}

function find_ld_linux64() {
    SNAIL_LD_LINUX_64=$(find / -name "ld-linux-x86-64.so.2" -executable | tail -1)
}

function get_platform_arch() {
    retval=32
    if [ $(uname -a | grep ".*x86_64" | wc -l) -eq 1 ] ; then
        retval=64
    fi
    echo ${retval}
}

function init_snail() {
    rm -rf ${SNAIL_TEMP_DIR}
    mkdir ${SNAIL_TEMP_DIR}
    find_ld_linux32
    if [ $(get_platform_arch) -eq 64 ] ; then
        find_ld_linux64
    fi
    setup_interp $1
}

function setup_interp() {
    interp_path=""
    for filename in $(ls -1 $1)
    do
        if [ $(file $1/${filename} | grep ".*: ELF" | wc -l) -eq 1 ] ; then
            if [ $(is_a_so $1/${filename}) -ne 1 ] ; then
                interp_path=$(readelf -l $1/${filename} | grep "\\[.*:.*\\]" | sed s/.*\\[// | sed s/.*:// | sed s/\\].*//)
            fi
        fi
    done
    if [ ! -z ${interp_path} ] ; then
        filename=$(echo ${interp_path} | sed s/.*\\///)
        INTERP_PATH=$(echo ${interp_path} | sed s/${filename}//)
        if [ -f ${interp_path} ] ; then
            SHOULD_REMOVE_INTERP=0
        else
            SHOULD_REMOVE_INTERP=1
            mkdir -p ${INTERP_PATH}
            if [ $(get_platform_arch) -eq 32 ] ; then
                cp ${SNAIL_LD_LINUX_32} ${filepath} &>/dev/null
            else
                cp ${SNAIL_LD_LINUX_64} ${filepath} &>/dev/null
            fi
        fi
    fi
}

function fini_snail() {
    rm -rf ${SNAIL_TEMP_DIR}
    if [ ${SHOULD_REMOVE_INTERP} -eq 1 ] ; then
        rm -rf ${INTERP_PATH} &>/dev/null
    fi
}

function zip_deps() {
    printf "@@@ - Zipping all collected dependency into %s... " $1
    rm $1 &>/dev/null
    zip -j $1 ${SNAIL_TEMP_DIR}/* &>/dev/null
    if [ $? -eq 0 ] ; then
        printf "ok.\n"
    else
        printf "zip error... aborting.\n"
        fini_snail
        exit 1
    fi
    printf "@@@ - done.\n"
}

function snail() {
    printf "@@@@@@@@@@@@@@@@@@@@@\n"
    printf "@@@ - S n a i l - @@@\n"
    printf "@@@@@@@@@@@@@@@@@@@@@\n\n"
    printf "@@@ - Initialising...\n"
    init_snail $1
    printf "@@@ - done.\n\n"
    printf "@@@ - Now, looking for ELFs in directory %s...\n" $1
    for filename in $(ls -1 $1)
    do
        if [ $(file $1/${filename} | grep ".*: ELF" | wc -l) -eq 1 ] ; then
            if [ $(is_a_so $1/${filename}) -eq 1 ] ; then
                printf "\t@@@ - Shared object: %s\n" $1/${filename}
                snail_find_so_deps $1/${filename}
            else
                printf "\t@@@ - Executable found: %s\n" $1/${filename}
                snail_find_app_deps $1/${filename}
            fi
        fi
    done
    printf "@@@ - done.\n"
    zip_deps $2
    fini_snail

}

# main() {

directory=""
output=""

while test -n "$1"
do
    case "$1" in
        -d | --directory)
            shift
            directory="$1"
            ;;

        -o | --output)
            shift
            output="$1"
            ;;

        -h | --help)
            printf "use: $0 --directory <directory containing your binaries> --output <output file path>\n"
            exit 1
            ;;
    esac
    shift
done

if [ -z ${directory} ] ; then
    printf "error: --directory option is missing.\n"
    exit 1
fi

if [ -z ${output} ] ; then
    printf "error: --output option is missing.\n"
    exit 1
fi

snail ${directory} ${output}

# }
