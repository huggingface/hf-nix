#!/usr/bin/env python3

import argparse
import json
from typing import Any, Dict, Set
from urllib import request

BASEURL = "https://repo.radeon.com/rocm/apt/{version}"

UBUNTU_VERSION_SUFFIXES = {
    "focal": "20.04",
    "jammy": "22.04",
}

parser = argparse.ArgumentParser(description="Parse ROCm repository")
parser.add_argument("version", help="ROCm version")
parser.add_argument("--ubuntu-version", help="Ubuntu version", choices=list(UBUNTU_VERSION_SUFFIXES.keys()), default='focal')


class Package:
    def __init__(self, info: Dict[str, Any], ubuntu_version: str):
        self._info = info
        self._ubuntu_version_suffix = UBUNTU_VERSION_SUFFIXES[ubuntu_version]

    def __str__(self):
        return f"{self._info['Package']} {self._info['Version']}"

    def depends(self, version: str) -> Set[str]:
        if "Depends" in self._info:
            depends = self._info["Depends"].split(", ")
            return {depend.split(" ")[0].removesuffix(version) for depend in depends}
        else:
            return set()

    @property
    def name(self) -> str:
        return self._info["Package"]

    @property
    def sha256(self) -> str:
        return self._info["SHA256"]

    @property
    def version(self) -> str:
        return self._info["Version"].removesuffix(f"~{self._ubuntu_version_suffix}")

    @property
    def filename(self) -> str:
        return self._info["Filename"]


def package_info(*, ubuntu_version:str, version: str):
    packages_url = (
        f"{BASEURL.format(version=version)}/dists/{ubuntu_version}/main/binary-amd64/Packages"
    )
    packages = request.urlopen(packages_url).read().decode("utf-8")

    info = {}
    for line in packages.split("\n"):
        line = line.rstrip()

        if len(line) == 0:
            if "Package" in info:
                yield Package(info, ubuntu_version)
            info = {}
            continue
        elif line[0] == " ":
            # We don't care about long descriptions
            continue

        parts = line.split(": ", maxsplit=1)
        if len(parts) == 2:
            info[parts[0]] = parts[1].strip()

    if len(info) > 0:
        yield Package(info)


def __main__():
    args = parser.parse_args()
    packages = {}
    for pkg in package_info(ubuntu_version=args.ubuntu_version, version=args.version):
        # Skip debug symbol packages for now.
        if "dbgsym" not in pkg.name:
            packages[pkg.name] = pkg

    filtered_packages = {}
    # Filter dupes like hip-dev vs. hip-dev6.3.4
    for name, info in packages.items():
        if name.endswith(args.version):
            name_without_version = name[: -len(args.version)]
            if name_without_version not in packages:
                filtered_packages[name_without_version] = info
        else:
            filtered_packages[name] = info
    packages = filtered_packages

    # First pass

    # Find -dev and -rpath packages that should be merged.
    dev_to_merge = {}
    for name in packages.keys():
        if name.endswith("-dev") and name[:-4] in packages:
            dev_to_merge[name] = name[:-4]
        elif name.endswith("-dev-rpath") and name[:-10] in packages:
            dev_to_merge[name] = name[:-10]
        elif name.endswith("-rpath") and name[:-6] in packages:
            dev_to_merge[name] = name[:-6]

    # Second pass: get ROCm dependencies and merge -dev packages.
    metadata = {}

    # sorted will put -dev after non-dev packages.
    for name in sorted(packages.keys()):
        info = packages[name]
        deps = {
            dev_to_merge.get(dep, dep)
            for dep in info.depends(args.version)
            if dep in packages
        }

        pkg_metadata = {
            "name": name,
            "sha256": info.sha256,
            "url": f"{BASEURL.format(version=args.version)}/{info.filename}",
            "version": info.version,
        }

        if name in dev_to_merge:
            target_pkg = dev_to_merge[name]
            metadata[target_pkg]["components"].append(pkg_metadata)
            metadata[target_pkg]["deps"].update(deps)
        else:
            metadata[name] = {
                "deps": deps,
                "components": [pkg_metadata],
                "version": info.version,
            }
    # Remove self-references and convert dependencies to list.
    for name, pkg_metadata in metadata.items():
        deps = pkg_metadata["deps"]
        deps -= {name, f"{name}-dev"}
        deps -= {name, f"{name}-rpath"}
        pkg_metadata["deps"] = list(sorted(deps))

    print(json.dumps(metadata, indent=2))


if __name__ == "__main__":
    __main__()
