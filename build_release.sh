printf '<!doctype html><script>' >build/main.html
terser src/main.js --mangle --compress passes=4 --toplevel --ie8 --compress-props --output build/compressed.js
cat build/compressed.js >>build/main.html
printf '</script>' >>build/main.html