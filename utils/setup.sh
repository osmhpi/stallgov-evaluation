set -e
set -x

cd memory-bound
cargo build --release
cd ..
if [[ ! -e "workload-pointer-chasing" ]]; then
  ln -s "memory-bound/target/release/memory-bound" "workload-pointer-chasing"
fi

cd dumb-primes
mkdir -p build
cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
cmake --build .
cd ../..
if [[ ! -e "workload-primes" ]]; then
  ln -s "dumb-primes/build/dumb-primes" "workload-primes"
fi
