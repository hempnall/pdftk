# PDFTK Docker Image

## Build instruction

```
$ docker build -t hempnall/pdftk . 
```
This will create a docker image with `pdftk` installed.

## Notes

To collate two PDF files:
```
$ pdftk A=scan10230.pdf  B=scan20097.pdf  shuffle A Bend-1 output collated.pdf
```

To rotate 180 degrees:
```
$ pdftk collated.pdf cat 1-endsouth output out.pdf
```



