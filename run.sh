#!/bin/bash

set -eufo pipefail

readonly main="src/main.ss"

usage() {
    cat <<EOS
usage: $0 [--help] {all,chez,chezd,guile,racket} args ...

Runs $main using the given Scheme implementation.
EOS
}

run_all() {
    printf "Chez   ... "
    run_chez "$@"
    printf "Guile  ... "
    run_guile "$@"
    printf "Racket ... "
    run_racket "$@"
}

run_chez() {
    ln -sf chez.ss src/compat/active.ss
    chez --program "$main" "$@"
}

run_chezd() {
    ln -sf chez.ss src/compat/active.ss
    chez --debug-on-exception --program "$main" "$@"
}

run_guile() {
    ln -sf guile.ss src/compat/active.ss
    guile -q --r6rs -L . -x .ss -l src/compat/guile-init.ss "$main" "$@"
}

run_racket() {
    ln -sf racket.ss src/compat/active.ss
    PLTCOLLECTS="$(pwd):" raco make -v "$main"
    PLTCOLLECTS="$(pwd):" racket "$main" "$@"
}

if [[ $# -eq 0 ]]; then
    usage
    exit
fi

readonly arg=$1
shift

if ! [[ -t 1 ]] || [[ -n ${NO_COLOR+x} ]]; then
    set -- "--no-color" "$@"
fi

cd "$(dirname "$0")"

case $arg in
    -h|--help) usage; exit ;;
    all|chez|chezd|guile|racket) "run_$arg" "$@" ;;
    *) usage >&2; exit 1 ;;
esac
