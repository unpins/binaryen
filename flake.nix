{
  description = "the Binaryen WebAssembly compiler and toolchain programs as a single self-contained binary";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  # Binaryen ships fourteen executables (wasm-opt, wasm-as, wasm-dis, …) and no
  # flagship among them, so the dispatcher carries the package name and a bare
  # `binaryen` lists — the naming rule, not a `defaultProgram`.
  #
  # Upstream publishes release tarballs, but each tool is a separate copy of the
  # whole of libbinaryen: the Linux tarball is 14 binaries of ~17 MB (250 MB
  # unpacked) and the macOS one links every tool against a companion
  # libbinaryen.dylib, which is the shipped-alongside library this catalog
  # exists to remove. Here the fourteen share one binary and one libbinaryen.
  #
  # Plain portable C++20 CMake with no external dependency, so every target
  # builds from the same expression. The DWARF support is a vendored copy of
  # llvm-project inside the tarball, not a submodule.
  outputs = { self, unpins-lib }:
    let
      ulib = unpins-lib.lib;

      # The WebAssembly spec testsuite, linked over the empty submodule dir so
      # the `spec` suite has something to run. Same rev nixpkgs uses, which is
      # also what binaryen 132 pins.
      testsuiteFor = pkgs: pkgs.fetchFromGitHub {
        owner = "WebAssembly";
        repo = "testsuite";
        rev = "4b24564c844e3d34bf46dfcb3c774ee5163e31cc";
        hash = "sha256-8VirKLRro0iST58Rfg17u4tTO57KNC/7F/NB43dZ7w4=";
      };

      # nixpkgs is at 129; this is 132, the current release. Same derivation,
      # newer source.
      binaryenFor = pkgs: scope:
        let
          # Run upstream's own suite wherever the build host can execute what it
          # just built — never under qemu, so the crosses skip it. nixpkgs' own
          # condition (isLinux || isDarwin) would demand it on all nine targets.
          doCheck = scope.stdenv.buildPlatform.canExecute scope.stdenv.hostPlatform;
        in
        scope.binaryen.overrideAttrs (old: {
          inherit doCheck;

          version = "132";
          src = pkgs.fetchFromGitHub {
            owner = "WebAssembly";
            repo = "binaryen";
            rev = "version_132";
            hash = "sha256-di/M4QidDwa1doomy79yfN7chCng9VcDB2KgmaEunDc=";
          };

          # The test drivers are BUILD tools, but `pkgsStatic` is a native set,
          # so nativeCheckInputs resolve inside it: `filecheck` then drags a
          # musl-static python3, whose --with-lto configure step fails under the
          # engine's clang (`llvm-ar is required for a --with-lto build`). Take
          # them from the ordinary set instead — they only have to run here.
          nativeCheckInputs = [ pkgs.lit pkgs.nodejs pkgs.filecheck ];

          # 132 dropped the wasm-lld suite: `scripts/test/lld.py` is gone and
          # `lld` is no longer a suite in check.py. nixpkgs still patches that
          # file (`--replace-fail` → "file does not exist", configure dies) and
          # still asks for the suite, so both are restated here. The rest is
          # nixpkgs' recipe: vendored gtest out, system gtest in, and the spec
          # testsuite linked in place of the submodule — at the very rev 132's
          # own .gitmodules pins, which is still the one nixpkgs fetches.
          #
          # The vendored-gtest cut has to take gmock with it: 132 declares gmock
          # and gmock_main next to gtest, out of the same unfetched googletest
          # submodule, so deleting only the gtest lines leaves CMake looking for
          # `googletest/googlemock/src/gmock-all.cc` and generate fails. Both
          # come from the system gtest in checkInputs instead.
          #
          # Branched in nix and not in shell on purpose: `${testsuiteFor pkgs}`
          # inside one string makes the spec testsuite an input of every cross
          # too — fetched on all six targets that never run a test.
          preConfigure =
            if doCheck then ''
              sed -i '/gtest/d;/gmock/d' third_party/CMakeLists.txt
              rmdir test/spec/testsuite
              ln -s ${testsuiteFor pkgs} test/spec/testsuite
            '' else ''
              cmakeFlagsArray+=(-DBUILD_TESTS=0)
            '';

          # nixpkgs' set minus `lld` (gone), `spec` and `wasm2js`. Those two are
          # thousands of cases each and carried the whole 48 min the full run
          # cost here — on every native target, since a check that runs is a
          # check that runs in CI too. What is left still drives each program
          # end to end.
          tests = [
            "version"
            "wasm-opt"
            "wasm-dis"
            "crash"
            "dylink"
            "ctor-eval"
            "wasm-metadce"
            "wasm-reduce"
            "gtest"
          ] ++ pkgs.lib.optionals scope.stdenv.hostPlatform.isLinux [
            "example"
            "validator"
          ];
        });
    in
    ulib.mkStandaloneFlake {
      inherit self;
      name = "binaryen";

      # Multicall: no applet is named `binaryen`, so CI smokes through the
      # explicit selector on the canonical program. The version banner prints
      # the tool's own compiled-in name, not argv[0].
      smoke = [ "--unpin-program=wasm-opt" "--version" ];
      smokePattern = "^wasm-opt version ";

      engine = "unpin-llvm";
      multicall = {
        windows = true;
        # Binaryen installs no man pages at all — every tool documents itself
        # through `--help`.
        programs = [
          { name = "wasm-opt"; noMan = true; }
          { name = "wasm-as"; noMan = true; }
          { name = "wasm-dis"; noMan = true; }
          { name = "wasm2js"; noMan = true; }
          { name = "wasm2c"; noMan = true; }
          { name = "wasm-ctor-eval"; noMan = true; }
          { name = "wasm-emscripten-finalize"; noMan = true; }
          { name = "wasm-merge"; noMan = true; }
          { name = "wasm-metadce"; noMan = true; }
          { name = "wasm-reduce"; noMan = true; }
          { name = "wasm-shell"; noMan = true; }
          { name = "wasm-split"; noMan = true; }
          { name = "wasm-fuzz-types"; noMan = true; }
          { name = "wasm-fuzz-lattices"; noMan = true; }
        ];
        # C++20 throughout; requires.cxx folds libc++ into the multicall link.
        requires.cxx = true;

        # libbinaryen is one archive every program links, and the default fold
        # puts a private, internalized copy of it in EACH program's module:
        # measured 14 copies of every libbinaryen symbol in module.bc (340 MB)
        # and a 137 MB binary, against 145 MB for the fourteen upstream
        # executables — no sharing at all. Every tool drags essentially the
        # whole library, because the pass registry is a global initializer that
        # names all of them. Fold the shared archive ONCE instead.
        foldSharedArchives = true;
      };

      build = pkgs: binaryenFor pkgs pkgs.pkgsStatic;
      windowsBuild = pkgs: binaryenFor pkgs (ulib.mingwStaticCross pkgs);
    };
}
