DOCKER_CONTAINERS="tesseract pdftk"

build_image() {
    pushd $1
    docker build --network host  -t $1 .
    popd    
}

for im in $DOCKER_CONTAINERS; do
    build_image $im
done 
