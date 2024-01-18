# Usage

```powershell
.\Patch-V.ps1 -Path "path/to/expanded/patches"
```

1. Collect all Hyper-V binaries from "C:\Windows\WinSxS\"
2. Reverse patch & store in ".\base"
    - Can skip this process with `-SkipRev` parameter
3. Forward patched binary stored in ".\patched"
    - Or you can set output dir with `-Out` parameter