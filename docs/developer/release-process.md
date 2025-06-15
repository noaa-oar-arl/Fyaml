# Release Process

This document outlines the release process for the FYAML library.

## Version Numbering

FYAML follows [Semantic Versioning](https://semver.org/) (SemVer) with version numbers in the format of MAJOR.MINOR.PATCH:

- **MAJOR**: Incremented for incompatible API changes
- **MINOR**: Incremented for new functionality in a backward-compatible manner
- **PATCH**: Incremented for backward-compatible bug fixes

## Release Preparation

### 1. Update Version Information

Update version information in the following files:

- `src/fyaml_constants.f90`: Update the version constants
  ```fortran
  integer, parameter :: FYAML_VERSION_MAJOR = X
  integer, parameter :: FYAML_VERSION_MINOR = Y
  integer, parameter :: FYAML_VERSION_PATCH = Z
  ```

- `CMakeLists.txt`: Update the project version
  ```cmake
  project(fyaml VERSION X.Y.Z LANGUAGES Fortran)
  ```

### 2. Update Changelog

Ensure `docs/CHANGELOG.md` is up-to-date with all notable changes since the previous release. Follow the format:

```markdown
# Changelog

## [X.Y.Z] - YYYY-MM-DD

### Added
- New feature A
- New feature B

### Changed
- Change to existing functionality A
- Change to existing functionality B

### Fixed
- Bug fix A
- Bug fix B

### Removed
- Deprecated feature A
- Deprecated feature B
```

### 3. Run Full Test Suite

Verify all tests pass with multiple compilers:

```bash
# Build and test with gfortran
mkdir -p build-gfortran && cd build-gfortran
FC=gfortran cmake .. -DCMAKE_BUILD_TYPE=Release -DFYAML_BUILD_TESTS=ON
make
ctest
cd ..

# Build and test with Intel Fortran (if available)
mkdir -p build-ifort && cd build-ifort
FC=ifort cmake .. -DCMAKE_BUILD_TYPE=Release -DFYAML_BUILD_TESTS=ON
make
ctest
cd ..
```

### 4. Documentation Review

- Ensure all API documentation is up-to-date
- Rebuild the documentation and check for any warnings or errors
- Review user guides for correctness
- Check for broken links

```bash
cd docs
mkdocs build --strict
```

### 5. Performance Benchmarking

Run performance tests to ensure there are no significant regressions:

```bash
cd build-gfortran
ctest -R test_large_file
```

## Release Process

### 1. Create a Release Branch

```bash
git checkout -b release-vX.Y.Z
```

### 2. Final Version Updates

Make any final version-related updates in the release branch.

### 3. Create Pull Request

Open a pull request from the release branch to the main branch for final review.

### 4. Code Review

Have at least one maintainer review the release changes.

### 5. Merge the Release Branch

Once approved, merge the release branch into the main branch.

### 6. Create Git Tag

```bash
git checkout main
git pull
git tag -a vX.Y.Z -m "FYAML version X.Y.Z"
git push origin vX.Y.Z
```

### 7. Create GitHub Release

Create a new release on GitHub:
- Use the tag `vX.Y.Z`
- Title: "FYAML X.Y.Z"
- Description: Copy the relevant section from CHANGELOG.md
- Attach any binary artifacts if applicable

### 8. Update Documentation

Ensure the documentation is updated for the new release:

```bash
cd docs
mkdocs gh-deploy
```

### 9. Announce the Release

Announce the new release in appropriate channels:
- Project README
- Project website
- Relevant community forums or mailing lists

## Post-Release

### 1. Update Development Version

Update the version in the main branch to the next development version:

```fortran
integer, parameter :: FYAML_VERSION_MAJOR = X
integer, parameter :: FYAML_VERSION_MINOR = Y + 1
integer, parameter :: FYAML_VERSION_PATCH = 0
character(len=*), parameter :: FYAML_VERSION_SUFFIX = "-dev"
```

### 2. Create Milestone for Next Release

Create a new milestone in GitHub for the next release.

## Hotfix Releases

For urgent bug fixes that need to be released before the next planned release:

### 1. Create a Hotfix Branch

```bash
git checkout vX.Y.Z
git checkout -b hotfix-vX.Y.(Z+1)
```

### 2. Apply the Fix

Make the necessary changes in the hotfix branch.

### 3. Update Version and Changelog

Update the version number and changelog for the hotfix release.

### 4. Test the Fix

Run tests to ensure the fix works correctly and doesn't cause regressions.

### 5. Release Process

Follow the regular release process from step 3 onwards.

## Release Checklist

### Pre-Release Checklist
- [ ] All tests pass on all supported compilers
- [ ] Version information updated in all files
- [ ] CHANGELOG.md updated with all notable changes
- [ ] Documentation is up-to-date and builds without errors
- [ ] Performance benchmarks show no significant regressions

### Release Checklist
- [ ] Release branch created
- [ ] Pull request opened and approved
- [ ] Release branch merged to main
- [ ] Git tag created and pushed
- [ ] GitHub release created with release notes
- [ ] Documentation updated and deployed
- [ ] Release announced

### Post-Release Checklist
- [ ] Development version updated in main branch
- [ ] New milestone created for next release
- [ ] Close completed milestone
- [ ] Update roadmap if necessary
