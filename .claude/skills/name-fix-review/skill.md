---
name: name-fix-review
description: Reviews name_fixes.lua for duplicates and no-ops, then removes them.
allowed-tools: Read, Edit
---

# Name Fix Review

Reviews `backend/name_fixes.lua` for issues and cleans them up.

## Instructions

1. Read `backend/name_fixes.lua`
2. Parse each mapping line to extract key-value pairs
3. Identify issues:
   - Duplicates: Same key appearing more than once
   - No-ops: Key equals value byte-for-byte (mapping does nothing)
     - Be careful: Unicode apostrophes (') vs ASCII (') are different characters
     - A mapping that changes ' to ' is NOT a no-op
4. Report findings to user
5. Remove all identified issues from the file using the Edit tool
6. Report what was removed

## Output Format

```
Found N issue(s):

Duplicates:
- "Key Name" (lines X, Y)

No-ops:
- "Key Name" (line Z)

Removing...
Done. Removed N entries.
```

If no issues found, report "No issues found."
