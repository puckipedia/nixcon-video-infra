{ stdenv, lib, fetchFromGitHub, cmake }:

# This was originally called mkl-dnn, then it was renamed to dnnl, and it has
# just recently been renamed again to oneDNN. See here for details:
# https://github.com/oneapi-src/oneDNN#oneapi-deep-neural-network-library-onednn
stdenv.mkDerivation rec {
  pname = "oneDNN";
  version = "1.5.1";

  src = fetchFromGitHub {
    owner = "oneapi-src";
    repo = "oneDNN";
    rev = "v${version}";
    sha256 = "1l66gkidldjpznp8pb01wdgrmm0rmrbndv8lzidz8fp9hf473zgl";
  };

  outputs = [ "out" "dev" "doc" ];

  nativeBuildInputs = [ cmake ];

  doCheck = true;

  cmakeFlags = [
    # oneDNN compiles with -msse4.1 by default, but not all x86_64
    # CPUs support SSE 4.1.
    "-DDNNL_ARCH_OPT_FLAGS="
  ];

  # The test driver doesn't add an RPath to the build libdir
  preCheck = ''
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH''${LD_LIBRARY_PATH:+:}$PWD/src
    export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH''${DYLD_LIBRARY_PATH:+:}$PWD/src
  '' + lib.optionalString stdenv.isx86_64 ''
    # Use baseline SIMD in case CPU features get misdetected.
    export DNNL_MAX_CPU_ISA=SSE41
  '';

  # The cmake install gets tripped up and installs a nix tree into $out, in
  # addition to the correct install; clean it up.
  postInstall = ''
    rm -r $out/nix
  '';

  meta = with lib; {
    description = "oneAPI Deep Neural Network Library (oneDNN)";
    homepage = "https://01.org/oneDNN";
    changelog = "https://github.com/oneapi-src/oneDNN/releases/tag/v${version}";
    license = licenses.asl20;
    platforms = platforms.all;
    maintainers = with maintainers; [ alexarice bhipple ];
  };
}