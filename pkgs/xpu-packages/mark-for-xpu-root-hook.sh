# shellcheck shell=bash

# Based on mark-for-cuda-root-hook.

(( ${hostOffset:?} == -1 && ${targetOffset:?} == 0)) || return 0


markForXPU_ROOT() {
    mkdir -p "${prefix:?}/nix-support"
    local markerPath="$prefix/nix-support/include-in-xpu-root"

    [[ -f "$markerPath" ]] && return 0
    touch "$markerPath"

    [[ -n "${strictDeps-}" ]] && return 0

    echo "${name:?}-${output:?}" > "$markerPath"

    # export compiler bin/lib/include
    if [[ -d "$prefix/oneapi/compiler/latest/bin" ]]; then
        echo "XPU_COMPILER_BIN=$prefix/oneapi/compiler/latest/bin" >> "$markerPath"
    fi
    if [[ -d "$prefix/oneapi/compiler/latest/lib" ]]; then
        echo "XPU_COMPILER_LIB=$prefix/oneapi/compiler/latest/lib" >> "$markerPath"
    fi
    if [[ -d "$prefix/oneapi/compiler/latest/include" ]]; then
        echo "XPU_COMPILER_INCLUDE=$prefix/oneapi/compiler/latest/include" >> "$markerPath"
    fi
    # export MKL bin/lib/include
    if [[ -d "$prefix/oneapi/mkl/latest/bin" ]]; then
        echo "XPU_MKL_BIN=$prefix/oneapi/mkl/latest/bin" >> "$markerPath"
    fi
    if [[ -d "$prefix/oneapi/mkl/latest/lib" ]]; then
        echo "XPU_MKL_LIB=$prefix/oneapi/mkl/latest/lib" >> "$markerPath"
    fi
    if [[ -d "$prefix/oneapi/mkl/latest/include" ]]; then
        echo "XPU_MKL_INCLUDE=$prefix/oneapi/mkl/latest/include" >> "$markerPath"
    fi
}

fixupOutputHooks+=(markForXPU_ROOT)