FROM ubuntu:latest
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/London
RUN apt update && apt install -y  automake ca-certificates g++ git libtool libleptonica-dev make pkg-config 
WORKDIR /
RUN git clone --depth 1  https://github.com/tesseract-ocr/tesseract.git
WORKDIR /tesseract
RUN ./autogen.sh 
RUN   ./configure 
RUN   make
RUN     make install
RUN     ldconfig
ENV TESSDATA_PREFIX=/usr/share/tesseract-ocr/4.00/tessdata/
RUN apt update && apt install -y imagemagick tesseract-ocr-eng
RUN mkdir -p /var/tesseract
WORKDIR /var/tesseract
RUN sed -i '/PDF/d' /etc/ImageMagick-6/policy.xml
COPY main.sh /main.sh
RUN chmod +x /main.sh
ENV DENSITY=450
ENTRYPOINT [ "/main.sh" ]
