#!/usr/bin/env bash

set -eu

stacks_url="http://catchenlab.life.illinois.edu/stacks/source/stacks-2.0Beta4.tar.gz"
install_directory="$(readlink -f .)"

# download stacks to a temporary directory
dl_dir="$(mktemp -p . -td XXXXX)"
stacks_archive="${dl_dir}/stacks.tar.gz"

curl -o "${stacks_archive}" "${stacks_url}"
tar -zxpf "${stacks_archive}" -C  "${dl_dir}"

# change into the src directory and build stacks
stacks_src="$(find "${dl_dir}" -maxdepth 1 -mindepth 1 -type d -name "*stacks*")"
printf "stacks_src:\t%s\n" "${stacks_src}"
export stacks_src
export install_directory
(
    printf "subshell\nstacks_src:\t%s\n" "${stacks_src}"
    source /opt/rh/devtoolset-6/enable
    printf "SCL\nstacks_src:\t%s\n" "${stacks_src}"
    cd "${stacks_src}" || exit 1
    ./configure "--prefix=${install_directory}"
    make
    make install
)

# remove the temporary directory
rm -rf "${dl_dir}"
