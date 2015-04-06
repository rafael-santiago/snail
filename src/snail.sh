#
# "snail.sh"
#       by Rafael Santiago
#
# Description: a simple script which scans ELF dependencies.
#

SNAIL_TEMP_DIR=".snail"

SNAIL_LD_LINUX_32=""

SNAIL_LD_LINUX_64=""

function snail_find_app_deps() {
#    for lib in $(LD_TRACE_LOADED_OBJECTS=1 $1 | grep ".*/" | sed s/.*=\>// | sed s/\(.*//)
#    do
#
#    done
    printf "\t\t@@@ - Inspecting %s's dependencies...\n" $1
    printf "\t\t@@@ - done.\n"
}

function snail_find_so_deps() {
    printf "\t\t@@@ - Inspecting %s's dependencies...\n" $1
    printf "\t\t@@@ - done.\n"
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
    SNAIL_LD_LINUX_64=$(find / -name "ld-linux-x86_64.so.2" -executable | tail -1)
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
}

function fini_snail() {
    rm -rf ${SNAIL_TEMP_DIR}
}

# snail "dir" "deps.zip"
function snail() {
    printf "@@@@@@@@@@@@@@@@@@@@@\n"
    printf "@@@ - S n a i l - @@@\n"
    printf "@@@@@@@@@@@@@@@@@@@@@\n\n"
    printf "@@@ - Initialising...\n"
    init_snail
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
    fini_snail
    printf "@@@ - done.\n"
}

snail "." "temp.zip"
