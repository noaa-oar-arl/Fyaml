# Copyright 2013-2025 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *


class Fyaml(CMakePackage):
    """FYAML - A comprehensive Fortran library for parsing YAML files.

    FYAML provides an easy-to-use interface for reading YAML files in Fortran
    applications, supporting all major YAML features including nested structures,
    arrays, anchors, and aliases. The library is designed for modern Fortran
    applications in scientific computing and HPC environments.
    """

    homepage = "https://noaa-oar-arl.github.io/fyaml/"
    url = "https://github.com/noaa-oar-arl/fyaml/archive/refs/tags/v0.2.0.tar.gz"
    git = "https://github.com/noaa-oar-arl/fyaml.git"

    maintainers("fyaml-dev")

    license("Apache-2.0")

    version("main", branch="main")
    version("0.2.0", sha256="0000000000000000000000000000000000000000000000000000000000000000")

    variant("tests", default=False, description="Build and run test suite")
    variant("examples", default=True, description="Build example programs")
    variant("shared", default=True, description="Build shared libraries")

    depends_on("cmake@3.12:", type="build")
    depends_on("fortran", type=("build", "link"))

    # Compiler support - tested compilers
    conflicts("%gcc@:10", msg="FYAML requires GCC 11 or later")
    conflicts("%intel@:2021.9", msg="FYAML requires Intel 2021.10 or later")

    def cmake_args(self):
        args = [
            self.define_from_variant("BUILD_SHARED_LIBS", "shared"),
            self.define_from_variant("FYAML_BUILD_EXAMPLES", "examples"),
            self.define("CMAKE_Fortran_STANDARD", "2003"),
            self.define("CMAKE_INSTALL_LIBDIR", "lib"),
        ]

        # Enable testing if requested
        if "+tests" in self.spec:
            args.append(self.define("FYAML_BUILD_TESTS", True))

        return args

    def check(self):
        """Run the test suite if tests variant is enabled."""
        if "+tests" in self.spec:
            with working_dir(self.build_directory):
                make("test")

    @run_after("install")
    def check_install(self):
        """Basic installation check."""
        # Check that key files are installed
        fyaml_lib = find_libraries("libfyaml", root=self.prefix, shared=True, recursive=True)
        if not fyaml_lib:
            fyaml_lib = find_libraries("libfyaml", root=self.prefix, shared=False, recursive=True)

        if not fyaml_lib:
            raise InstallError("FYAML library not found after installation")

        # Check for module files
        mod_files = find_headers("*.mod", self.prefix.include, recursive=False)
        if not mod_files:
            raise InstallError("FYAML Fortran module files not found after installation")

    @property
    def headers(self):
        """Return list of header files to install."""
        return find_headers("*.mod", self.prefix.include, recursive=False)

    @property
    def libs(self):
        """Return list of libraries provided by this package."""
        shared = "+shared" in self.spec
        return find_libraries(
            "libfyaml", root=self.prefix, shared=shared, recursive=True
        )
