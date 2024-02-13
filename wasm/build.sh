clang main.c --no-standard-libraries --target=wasm32 -Wl,--export-all -Wl,--no-entry -Wl,-undefined,suppress --output - | base64 --wrap=0 -
#clang -O3 -c -emit-llvm main.c -o main.bc
#llc -O3 main.bc -o main.s
#wasm-ld main.s -o main.wasm --no-entry --export-all