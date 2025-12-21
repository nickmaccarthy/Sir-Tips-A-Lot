# Version Information

## Current Version

| Field | Value |
|-------|-------|
| **Version** | 1.0.0 |
| **Build** | 1 |
| **Release Date** | December 21, 2024 |
| **Status** | Initial Release |

## Version Scheme

This project follows [Semantic Versioning](https://semver.org/):

```
MAJOR.MINOR.PATCH
```

| Component | When to Increment |
|-----------|-------------------|
| **MAJOR** | Breaking changes or major redesigns |
| **MINOR** | New features (backwards compatible) |
| **PATCH** | Bug fixes and small improvements |

## Build Number

The build number auto-increments with each build using the `scripts/increment_build.sh` script.

Format: Sequential integer (1, 2, 3, ...)

## How to Update Version

### In Xcode:
1. Select Project → Target → **General** tab
2. Update **Version** (e.g., 1.0.0 → 1.1.0)
3. Build number auto-increments

### Via Command Line:
```bash
# Set marketing version
agvtool new-marketing-version 1.1.0

# Set build number
agvtool new-version -all 42

# Check current versions
agvtool what-version
agvtool what-marketing-version
```

### Update These Files:
1. `VERSION.md` — Update the table above
2. `CHANGELOG.md` — Add release notes
3. Commit with tag: `git tag -a v1.1.0 -m "Version 1.1.0"`

## Release Checklist

- [ ] Update version in Xcode (General tab)
- [ ] Update `VERSION.md`
- [ ] Update `CHANGELOG.md` (move Unreleased to new version)
- [ ] Test on physical device
- [ ] Take new screenshots (if UI changed)
- [ ] Commit all changes
- [ ] Create git tag: `git tag -a v1.x.x -m "Version 1.x.x"`
- [ ] Push with tags: `git push origin main --tags`
- [ ] Archive and upload to App Store Connect (if publishing)

## History

| Version | Build | Date | Notes |
|---------|-------|------|-------|
| 1.0.0 | 1 | 2024-12-21 | Initial release |

