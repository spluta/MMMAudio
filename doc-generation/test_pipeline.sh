mojo doc -o intermediate-json/functions.json ../mmm_utils/functions.mojo
python mojo_to_jinja.py -i intermediate-json -o rendered-md
pandoc -i rendered-md/Print.md -o Print.pdf --pdf-engine=xelatex --toc --metadata title="MMMAudio Documentation"