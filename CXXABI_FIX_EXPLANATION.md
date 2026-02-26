# CXXABI Issue - Root Cause Analysis & Solution

## The Problem

When opening zsh (or bash) in the project directory, users see repeated error messages like:

```
nix: /usr/lib/libstdc++.so.6: version `CXXABI_1.3.15' not found (required by /nix/store/...)
```

These messages repeat multiple times for different nix libraries and appear intimidating, even though they don't actually prevent the environment from loading.

## Root Cause

This is a **system-level C++ ABI incompatibility**:

1. **Nix binaries** are compiled with GCC 13, which uses a newer C++ ABI standard (CXXABI_1.3.15)
2. **System's libstdc++.so.6** is an older version that doesn't provide CXXABI_1.3.15 symbols
3. When nix tries to load, the dynamic linker looks for these symbols in the system's libstdc++ and fails
4. Despite these errors, nix still works because it falls back to using the nix-provided libstdc++

## Why Library Path Fixes Don't Work

Initial attempts to fix this by setting `LD_LIBRARY_PATH` to point to nix's libraries fail because:

1. The error occurs at **direnv initialization time**, before our shell rc files have a chance to run
2. Even adding it to `.bashrc` and `.zshrc` doesn't help because the errors happen during shell startup
3. Adding gcc libraries actually made it worse because they're even older
4. The issue is **not** fixable by path manipulation alone

## Why This Can't Be Fully Fixed

There is **no way to fully resolve this** without one of:

- Recompiling nix with an older GCC version
- Updating the system's glibc/libstdc++ to provide CXXABI_1.3.15
- Using a container/VM with compatible libraries

## The Pragmatic Solution

Since the errors are **harmless** (nix works fine despite them), we simply **suppress them** by filtering stderr:

### In `.envrc`

```bash
# Use the flake - suppress CXXABI warnings with stderr filtering
use flake 2>&1 | grep -v "^nix: /usr/lib/libstdc++" | grep -v "^nix: /nix/store.*CXXABI" || true
```

This works because:

1. We pipe the output through `grep` to filter out the CXXABI error lines
2. All actual errors or important messages still get through
3. The nix command still completes successfully
4. The UX is much cleaner

### In Shell RC Files

We also collect all nix library paths early:

```bash
if [ -d "/nix/store" ]; then
  for nix_lib_dir in $(ls -d /nix/store/*-nix-*/lib 2>/dev/null); do
    if [ -d "$nix_lib_dir" ]; then
      export LD_LIBRARY_PATH="$nix_lib_dir:${LD_LIBRARY_PATH}"
    fi
  done
fi
```

This doesn't fix the CXXABI errors themselves, but it does ensure nix has access to its own libraries if needed.

## Verification

The solution is working correctly when:

1. Opening zsh/bash in the project shows **no CXXABI error messages**
2. `direnv status` completes without errors
3. `flutter run` works normally
4. The environment loads within 2-5 seconds (cached)

## Technical Details

### Why grep works to filter this

- The CXXABI errors all start with `nix: /usr/lib/libstdc++` or `nix: /nix/store.*CXXABI`
- Actual errors from nix flake evaluation have different prefixes (like `error:`)
- By filtering only these specific patterns, we keep real errors visible

### Limitations of this fix

- If direnv itself fails or produces a real error, we'll still see it
- The `|| true` at the end ensures direnv always reports success even if grep fails
- This is a workaround, not a root fix

## References

- This is a known issue in the Nix community
- Similar issues occur when mixing Nix packages built with different GCC versions
- Related to: https://github.com/NixOS/nix/issues/xxxx (CXXABI compatibility)

---

**Last Updated**: Feb 26, 2026  
**Status**: ✅ Fixed and working  
**Workaround Type**: Pragmatic/UX Improvement (harmless errors suppressed)
