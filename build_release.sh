printf '' > main.html
printf '<script>' >> main.html
terser main.js --mangle --compress passes=4 --toplevel --ie8 --compress-props --output compressed.js
cat compressed.js >> main.html
printf '</script>' >> main.html