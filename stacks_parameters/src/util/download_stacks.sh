#!/usr/bin/env bash

set -eu

stacks_url="http://catchenlab.life.illinois.edu/stacks/source/stacks-2.0Beta7c.tar.gz"

# we're going to install stacks into the virtual environment
activate="$(readlink -f "$(find . -type f -name "activate")")"
install_directory="$(readlink -f "$(dirname "$(find . -type d -name "bin")")")"

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
export activate
(
    set +u
    source /opt/rh/devtoolset-6/enable
    source "${activate}"
    cd "${stacks_src}" || exit 1
    ./configure "--prefix=${install_directory}"
    make -j
    make install
)

# remove the temporary directory
rm -rf "${dl_dir}"
