#! /usr/bin/env bash
show_usage() {
    echo "Usage: $0 [wayup|ocr] [options]"
    echo "  wayup [filename]"
    echo "    - outputs angle required to correct orientation (e.g. 90,180,270)"
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
    convert -density $DENSITY $1[0] $2
}

wayup() {
    log "wayup"
    page1_png=$1.0.png
    page1_png_output=$page1_png.output
    convert_to_png $1 $page1_png
    log "png created"
    tesseract --psm 0 $page1_png $page1_png_output 
    cat $page1_png_output.osd | grep Rotate | awk -F ':' '{ print $2 }' 
}

ocr() {
    log "ocr"
    page1_png=$1.0.png
    convert_to_png $1 $page1_png
    tesseract $page1_png $1.ocr
    log "ocr done -> $1.ocr.txt"
    mv $1.ocr.txt $2 
}


subcommand=$1
shift

case $subcommand in
    wayup)
        log "wayup"
        input_file=$1
        wayup $input_file
        ;;
    ocr)
        input_file=$1
        output_file=$2
        ocr $input_file $output_file 
        ;;
    *) 
        log "invalid command line option"
        show_usage
        exit 1
        ;;
esac

log "done"
exit 0