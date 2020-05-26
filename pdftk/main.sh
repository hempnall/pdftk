#! /usr/bin/env bash
show_usage() {
    echo "Usage: $0 [rotate|interleave|pagecount] [options]"
    echo "  rotate [90|180|270|360] [filename] [output_filename]"
    echo "  interleave [side1_filename] [side2_filename] [output_filename]"
    echo "  pagecount [filename]"
}

log() {
    echo "[+] $1" 1>&2
}

error() {
    echo "[-] $1" 1>&2
    exit 1
}

rotate() {
    if [ "90" == "$1" ]; then
        angle=east
    elif [ "180" == "$1" ]; then
        angle=south
    elif [ "270" == "$1" ]; then
        angle=west
    elif [ "360" == "$1" ]; then
        angle=north
    else
        error "invalid angle specified $1"
    fi
    log "rotate $2 by $1 degrees -> $3"
    pdftk "$2" cat 1-end$angle output "$3"
}

interleave() {
    log "interleaving $1 and $2 -> $3"
    pdftk A="$1"  B="$2"  shuffle A Bend-1 output "$3"
}

pagecount() {
    pdftk "$1" dump_data | grep NumberOfPages | awk '{ print $2 }'
}

subcommand=$1
shift

case $subcommand in
    rotate)
        angle=$1
        filename=$2
        output_filename=$3
        rotate $angle "$filename" "$output_filename" 
        ;;
    interleave)
        side1=$1
        side2=$2
        output_filename=$3
        interleave "$side1" "$side2"  "$output_filename" 
        ;;
    pagecount)
        doc=$1
        pagecount "$doc" 
        ;;
    *) 
        log "invalid command line option"
        show_usage
        exit 1
        ;;
esac

log "done"
exit 0