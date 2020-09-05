directory1=$1
directory2=$2
processed_directory=$3
reject_directory=$4    
colalted_directory=$5 
pdftk_container=pdftk
temp_file=

log() {
    echo "[+] $1"
}

error() {
    echo "[-] $1"
}

get_directory_listing() {
 ls -1dt $1/*.pdf 
}

get_most_recent_side1() {
    echo $( get_directory_listing $1 2>/dev/null  | head -1 )
    return $( get_directory_listing $1 2>/dev/null  | wc -l )
}

get_more_recent_side_2() {
    for f in $(get_directory_listing $directory2); do
        [ "$f" -nt $1 ] && echo $f
    done
}

get_page_count() {
    docker run  --mount type=bind,src="$directory1",target=/var/pdftk  $pdftk_container pagecount  "/var/pdftk/$(basename $1)" 2>/dev/null
    if [[ $? -ne 0 ]]; then
        error "unable to get page count of $1"
        return 1 
    fi
}

rotate() {
    angle=$1
    input=$2
    output=$3
    docker run --mount type=bind,src="$directory1",target=/var/tesseract  $pdftk_container  rotate $angle $input $output
    if [[ $? -ne 0 ]]; then
        rm -f $output
        error "unable to rotate $2 by $1"
        return 1
    fi
}

right_way_up() {
    log "right way up $1 $2 $3 $4"
    input_filename=/var/tesseract/$(basename $1)
    output_filename=/var/tesseract/$(basename $2)
    func=$3
    pagecount=$4
    angle=$( docker run --mount type=bind,src=$directory1,target=/var/tesseract tesseract $func $pagecount $input_filename   )
    if [[ $? -ne 0 ]]; then
        error "unable to determine angle of text"
        return 1
    fi
    log "angle: $angle"
    if [[ $angle -eq 180 ]] || [[ $angle -eq 90 ]] || [[ $angle -eq 270 ]]; then
        rotate $angle $input_filename $output_filename
        if [[ $? -ne 0 ]]; then
            rm -f $output_filename
            error "unable to rotate $1"
            return 1
        fi 
        rm -f $1
    else
        mv $1 $2
    fi
}

right_way_up_first() {
    indoc=$1
    outdoc=$2
    func=wayup_first
    pagecount=1
    right_way_up $indoc $outdoc $func $pagecount
}

right_way_up_last() {
    indoc=$1
    outdoc=$2
    func=wayup_last
    pagecount=$3
    right_way_up $indoc $outdoc $func $pagecount
}

collate() {
    log "collate $1 and $2"
    input_filename1=/var/pdftk/$(basename $1)
    input_filename2=/var/pdftk/$(basename $2)
    output_filename=/var/pdftk/$(basename $3)
    docker run  --mount type=bind,src="$directory1",target=/var/pdftk  $pdftk_container interleave  $input_filename1 $input_filename2 $output_filename 
    if [[ $? -ne 0 ]]; then
        rm -f $output_filename
        error "unable to interleave $1 and $2"
        return 1
    fi
    rm -f $1
    rm -f $2
}

ocr() {
    log "performing ocr on first page"
    input_filename=/var/tesseract/$(basename $1)
    output_filename=/var/tesseract/$(basename $1).txt
    docker run --mount type=bind,src=$directory1,target=/var/tesseract tesseract ocr $input_filename $output_filename 
    if [[ $? -ne 0 ]]; then
        error "unable to ocr $1"
        return 1
    fi
}


process_doc() {
    log "process $1"
    ocr $1 
    mv $1 $processed_directory
}

reject() {
    log "rejecting $@"
    mv $@ $reject_directory
}

process_side_1() {
    log "=====>> processing $1 <<====="
    doc_count=$(get_more_recent_side_2 $1 | wc -l)
    log "candidate side 2 count: $doc_count"
  
    if [[ $doc_count -gt 1 ]]; then
        log "more than 1 matching document"
        side2_docs=$( get_more_recent_side_2 $1 )
        reject $1 
        reject "$side2_docs"
        error "unable to process $1. more than one matching document"
        return 1

    elif [[ $doc_count -eq 1 ]]; then

        log "single matching document"
        side2_doc=$( get_more_recent_side_2 $1 )
        log "side 2 doc is $side2_doc"
        page_count_1=$( get_page_count $1 )
        if [[ $? -ne 0 ]]; then
            reject $1
            reject $side2_doc
            error "unable to get page count for $1"
            return 1
        fi

        mv $side2_doc "$1.2"  
        page_count_2=$( get_page_count $1.2 )
        if [[ $? -ne 0 ]]; then
            reject $1
            mv "$1.2" $side2_doc  
            reject $side2_doc
            error "unable to get page count for $1"
            return 1
        fi

        log "pagecount 1: $page_count_1"
        log "pagecount 2: $page_count_2"

        if [[ $page_count_1 -ne $page_count_2 ]]; then
            reject $1
            mv "$1.2" $side2_doc  
            reject $side2_doc
            error "unable to process $1. page numbers differ"
            return 1
        fi

        right_way_up_first "$1" "$1.o" 
        if [[ $? -ne 0 ]]; then
            reject $1
            mv "$1.2" $side2_doc  
            reject $side2_doc
            error "unable to rightwayup side 1"  
            return 1
        fi

        right_way_up_last "$1.2" "$1.2.o" $page_count_2
        if [[ $? -ne 0 ]]; then
            reject "$1.o"
            mv "$1.2" $side2_doc  
            reject $side2_doc
            error "unable to rightwayup side 2"  
            return 1  
        fi

        collate "$1.o" "$1.2.o" "$1.o.c.pdf"
        if [[ $? -ne 0 ]]; then
            reject "$1.o"
            reject "$1.2.o"
            error "unable to collate documents"
            return 1
        fi

        process_doc "$1.o.c.pdf"
        if [[ $? -ne 0 ]]; then
            error "unable to index document"
        fi
    else
        log "no matching documents"
        right_way_up_first $1 "$1.o.pdf"
        if [[ $? -ne 0 ]]; then
            reject "$1"
            error "unable to rightwayup doc (single sided)"  
            return 1  
        fi

        process_doc "$1.o.pdf"    
        return 0
    fi
}

side1=$(get_most_recent_side1 $directory1 )
while [[  $? > 0 ]]; do
    process_side_1 $side1
    # read -p "press any key"
    side1=$(get_most_recent_side1 $directory1 )  
done
log "done"