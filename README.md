# LAB BOOK Owen GRIERE

## Descriptions

The reports are contained in the PDF folder. The uncompiled versions are contained in the src folder. 

## Installation des packages

You must install some package to compile reports (if you want) or just to use the reports generator (report.sh file)

The minimal installation is : 

    sudo apt update
    sudo apt install -y latexmk texlive-latex-extra texlive-fonts-recommended texlive-lang-french biber

Meanwhile the full installation is :

    sudo apt install -y texlive-full

## Using Guide

You can use latex_generator .sh to rewrite a new report knowing that you can run 

    chmod u+x latex_generator.sh
    ./latex_generator.sh --help

to understand how to use it.

After to run your latex when it's created you can run

    ./pathtoyourproject/build.sh

