# shellcheck shell=bash

# Based on setup-cuda-hook.

# Only run the hook from nativeBuildInputs
(( "$hostOffset" == -1 && "$targetOffset" == 0)) || return 0

guard=Sourcing
reason=

[[ -n ${xpuSetupHookOnce-} ]] && guard=Skipping && reason=" because the hook has been propagated more than once"

if (( "${NIX_DEBUG:-0}" >= 1 )) ; then
    echo "$guard hostOffset=$hostOffset targetOffset=$targetOffset setup-xpu-hook$reason" >&2
else
    echo "$guard setup-xpu-hook$reason" >&2
fi

[[ "$guard" = Sourcing ]] || return 0

declare -g xpuSetupHookOnce=1
declare -Ag xpuHostPathsSeen=()
declare -Ag xpuOutputToPath=()

extendXpuHostPathsSeen() {
    local markerPath="$1/nix-support/include-in-xpu-root"

    [[ ! -f "${markerPath}" ]] && return 0
    [[ -v xpuHostPathsSeen[$1] ]] && return 0

    xpuHostPathsSeen["$1"]=1

    # read mark, export the env
    while IFS= read -r line; do
        if [[ "$line" == XPU_COMPILER_BIN=* ]]; then
            export PATH="${PATH:-}:${line#XPU_COMPILER_BIN=}"
        elif [[ "$line" == XPU_COMPILER_LIB=* ]]; then
            export LD_LIBRARY_PATH="${line#XPU_COMPILER_LIB=}:${LD_LIBRARY_PATH:-}"
        elif [[ "$line" == XPU_COMPILER_INCLUDE=* ]]; then
            export CPATH="${line#XPU_COMPILER_INCLUDE=}:${CPATH:-}"
        elif [[ "$line" == XPU_MKL_BIN=* ]]; then
            export PATH="${PATH:-}:${line#XPU_MKL_BIN=}"
        elif [[ "$line" == XPU_MKL_LIB=* ]]; then
            export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}:${line#XPU_MKL_LIB=}"
        elif [[ "$line" == XPU_MKL_INCLUDE=* ]]; then
            export CPATH="${line#XPU_MKL_INCLUDE=}:${CPATH:-}"
        fi
    done < "$markerPath"
}
addEnvHooks "$targetOffset" extendXpuHostPathsSeen
