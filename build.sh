printf '<!doctype html><script>' > build/main.html
cat src/main.js >> build/main.html
printf '</script>' >> build/main.html