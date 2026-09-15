# binaryen

[Binaryen](https://github.com/WebAssembly/binaryen) — the WebAssembly optimizer
and toolchain library, plus the programs built on it: `wasm-opt` and friends
optimize, assemble, disassemble, merge, split and translate `.wasm` modules. A
single self-contained binary, built natively for Linux, macOS, and Windows.

[![CI](https://github.com/unpins/binaryen/actions/workflows/binaryen.yml/badge.svg)](https://github.com/unpins/binaryen/actions)
![Linux](https://img.shields.io/badge/Linux-✓-success?logo=linux&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-✓-success?logo=apple&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-✓-success?logo=windows&logoColor=white)

Part of the [unpins](https://unpins.org) catalog; install it with [`unpin`](https://github.com/unpins/unpin): `unpin install binaryen`.

## Usage

Run one of the programs with [unpin](https://github.com/unpins/unpin):

```bash
unpin binaryen --unpin-program=wasm-opt -O3 module.wasm -o out.wasm   # optimize
unpin binaryen --unpin-program=wasm-as module.wat -o module.wasm      # text -> binary
unpin binaryen --unpin-program=wasm-dis module.wasm                   # binary -> text
unpin binaryen --unpin-program=wasm-metadce --graph-file g.json module.wasm -o out.wasm
```

`binaryen` is the name of the collection, not of a program, so running it on its
own lists what is inside instead of picking one for you.

To put every command — `wasm-opt`, `wasm-as`, `wasm-dis`, `wasm-merge` and the
ten others — onto your PATH:

```bash
unpin install binaryen
wasm-opt -O3 module.wasm -o out.wasm
```

`unpin info binaryen` lists them all.

## Programs

| command | what it does |
| --- | --- |
| `wasm-opt` | read, optimize and write a module — the optimizer itself |
| `wasm-as` | assemble WebAssembly text (`.wat`) into a binary module |
| `wasm-dis` | disassemble a binary module back to text |
| `wasm2js` | compile a module into JavaScript |
| `wasm2c` | translate a module into C source you can compile and link |
| `wasm-ctor-eval` | run a module's constructors ahead of time and bake in the result |
| `wasm-emscripten-finalize` | apply Emscripten's final fixups to a linked module |
| `wasm-merge` | merge several modules into one, wiring imports to exports |
| `wasm-metadce` | drop everything the program cannot reach, module and JS graph together |
| `wasm-reduce` | shrink a module down to a minimal case that still misbehaves |
| `wasm-shell` | run a module or a spec test script in the interpreter |
| `wasm-split` | split a module into a primary part and one loaded on demand |
| `wasm-fuzz-types` | fuzz the type system and check its invariants |
| `wasm-fuzz-lattices` | fuzz the analysis lattices the optimizer relies on |

Every program describes its own options under `--help`; Binaryen ships no man
pages.

## Build locally

```bash
nix build github:unpins/binaryen
./result/bin/binaryen --unpin-program=wasm-opt --version
```

Or run directly:

```bash
nix run github:unpins/binaryen -- --unpin-program=wasm-opt --version
```

A plain `./result/bin/binaryen` prints the list of programs it holds.

The first invocation will offer to add the [unpins.cachix.org](https://unpins.cachix.org) substituter so most pulls come pre-built.

## Manual download

The [Releases](https://github.com/unpins/binaryen/releases) page has standalone binaries for manual download.

## Build notes

- All fourteen programs live in one binary and share the single copy of
  libbinaryen they all link. `binaryen` itself is not one of them: run bare, it
  lists what it carries.
- **No man pages** — Binaryen ships none upstream, so none are embedded. Every
  program documents its own options under `--help`.
- **Windows** is built with mingw: Binaryen is portable C++20 with no external
  dependency, so it cross-compiles as-is.
- Upstream's tests run during the build on every platform whose binaries the
  build machine can execute: all of them except the WebAssembly spec suite and
  the `wasm2js` suite, which together take most of an hour.
