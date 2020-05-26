# OCR

## Orientation Detection





## Text Extraction

```
convert -density 600 "The 7 Habits of Highly Ineffective People - Mind Cafe - Medium.pdf"[0] out.png
tesseract out.png  out -l eng pdf
```