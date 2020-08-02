#! /usr/bin/env bash
show_usage() {
    echo "Usage: $0 [wayup|ocr] [options]"
    echo "  wayup [filename]"
    echo "    - outputs angle required to correct orientation (e.g. 90,180,270)"
    echo "  wayup_l [page_count (1 based)] [filename]"
    echo "  ocr [filename] [output_filename]"
}

log() {
    echo "[+] $1" 1>&2
}

error() {
    echo "[-] $1" 1>&2
    exit 1
}


convert_to_png() {
    log "convert $1 -> $2"
    convert -density $DENSITY $1[$3] $2
    if [[ $? -ne 0  ]]; then
        error "unable to convert $1 to png"
    fi
}

wayup() {
    log "wayup"
    let page_index=$(( $1  - 1 ))
    page1_png=$2.$page_index.png
    page1_png_output=$page1_png.output
    convert_to_png $2 $page1_png $page_index
    log "png created"
    tesseract --psm 0 $page1_png $page1_png_output 
    if [[ $? -ne 0 ]]; then
        error "unable to detect orientation"
    fi
    cat $page1_png_output.osd | grep Rotate | awk -F ':' '{ print $2 }' 
    rm $page1_png_output.osd
    rm $page1_png
}

ocr() {
    log "ocr"
    page1_png=$1.0.png
    if [[ ! -f $page1_png  ]]; then
        convert_to_png $1 $page1_png 0
    fi
    tesseract $page1_png $1.ocr
    if [[ $? -ne 0 ]]; then
        error "unable to perform ocr"
    fi
    log "ocr done -> $1.ocr.txt"
    mv $1.ocr.txt $2 
    rm $page1_png
}

clean() {
    log "clean"
    page1_png=$1.0.png
    rm -f $page1_png
}

subcommand=$1
shift

case $subcommand in
    wayup_first)
        input_file=$2
        wayup 1 $input_file
        ;;
    wayup_last)
        input_file=$2
        wayup $1 $input_file
        ;;        
    ocr)
        input_file=$1
        output_file=$2
        ocr $input_file $output_file 
        ;;
    clean)
        input_file=$1
        clean $input_file
        ;;
    *) 
        log "invalid command line option"
        show_usage
        exit 1
        ;;
esac

log "done"
exit 0