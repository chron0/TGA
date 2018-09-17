#!/bin/bash -e

select_file(){

    read -e -p "Enter Filename, use tab for completion: " PDF
    echo -e "\n"
    echo -e "Selected File: " "\e[34m\033[1m$PDF\033[0m\e[0m"
    echo -e "\n"
    read -r -p "Continue? [y/n] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]] ; then
        read -p "Enter the number of pages: " NUM

    else
        echo -e "\n\033[1m\e[31mTry again\e[0m\033[0m \n"
        exit 0
    fi
}

echo -e "\033[1mUsage\033[0m: Enter the file name and the number of pages. \n\e[2mIf you want to cancel type \e[4mCtrl+C\e[24m at any moment\e[22m\n"

select_file

# setup temp workspace
folder=$(echo $PDF | cut -f 1 -d '.')_OCR
new_folder="${folder// /_}"

mkdir ./$new_folder
cp "$PDF" ./$new_folder
cd ./$new_folder

# Split pages with pdftk and run tesseract

for PAGE in $(seq -f "%05g" 1 $NUM); do
    echo "Processing page $PAGE"
    pdftk "$PDF" cat $PAGE output temp.pdf
    echo "Split PDF"
    convert -density 300 temp.pdf -depth 8 -fill white -draw 'rectangle 10,10 20,20' -background white -flatten +matte -alpha Off temp.tiff
    #gs -dSAFER -sDEVICE=png16m -dINTERPOLATE -dNumRenderingThreads=8 -dFirstPage=1 -dLastPage=1 -r300 -o ./output\_image.png -c 30000000 setvmthreshold -f my\_pdf.pdf
    echo "Converted to TIFF"
    tesseract -l eng temp.tiff tmp.pdf_"${PAGE}" pdf quiet
    rm -f temp.tiff temp.pdf
    echo "Temp files removed"
done

# Cleanup
pdftk tmp.pdf_*.pdf output "$folder".pdf  && rm -f tmp.pdf_*.pdf
cp "$folder".pdf ../
cd ../
rm -rf "$new_folder"
echo -e "\n\033[1m\e[32mOutput written succesfully\e[0m\033[0m\n"
