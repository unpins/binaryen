# Changelog

## [Unreleased]

Initial release — Binaryen 132 as a single self-contained binary, built natively
for Linux, macOS, and Windows.

### Added

- Builds for Linux (x86_64, aarch64, armv7l, i686, ppc64le, riscv64), macOS
  (x86_64, aarch64), and Windows.
- All fourteen programs in one binary: `wasm-opt`, `wasm-as`, `wasm-dis`,
  `wasm2js`, `wasm2c`, `wasm-ctor-eval`, `wasm-emscripten-finalize`,
  `wasm-merge`, `wasm-metadce`, `wasm-reduce`, `wasm-shell`, `wasm-split`,
  `wasm-fuzz-types` and `wasm-fuzz-lattices`.
- Upstream's test suite runs during the build on the platforms that can execute
  what they built. Binaryen ships no man pages, so none are embedded; each
  program documents itself under `--help`.
