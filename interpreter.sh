#!/bin/bash

# expand all arguments to full filepath before changing directories
array=()
for arg in "$@"; do
    array+=$(readlink -f "$arg")
done

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $DIR
ruby interpreter/main.rb "${array[@]}"
