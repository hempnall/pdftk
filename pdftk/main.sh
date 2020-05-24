#! /usr/bin/env bash
rotate() {
    if [ 90 -eq "$1" ]; then
        angle=east
    elif [ 180 -eq "$1" ]; then
        angle=south
    elif [ 270 -eq "$1" ]; then
        angle=west
    elif [ 360 -eq "$1" ]; then
        angle=north
    else
        echo "[-] invalid angle specified $1"
        exit 1
    fi
    echo "[+] rotate $2 by $1 degrees -> $3"
    pdftk "$2" cat 1-end$angle output "$3"
}

interleave() {
    echo "[+] interleaving $1 and $2 -> $3"
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
        echo "[-] invalid command line option"
        exit 1
        ;;
esac

echo "[+] done"
exit 0