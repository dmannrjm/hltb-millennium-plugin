---
name: name-fix-review
description: Reviews name_fixes.lua for duplicates and no-ops, then removes them.
allowed-tools: Read, Edit, Bash
---

# Name Fix Review

Cleans up `backend/name_fixes.lua` by removing issues and sorting entries.

## Instructions

### Step 1: Run tests to check current state

```bash
cmd //c "busted tests/name_fixes_spec.lua"
```

Report whether tests pass or fail.

If busted is not available, see `docs/development.md` section "Running Lua Tests" for setup instructions.

### Step 2: Read and parse the file

1. Read `backend/name_fixes.lua`
2. Parse each mapping line to extract key-value pairs
3. Identify issues:
   - Duplicates: Same key appearing more than once (keep first occurrence)
   - No-ops: Key equals value byte-for-byte (mapping does nothing)
     - Be careful: Unicode apostrophes (') vs ASCII (') are different characters
     - A mapping that changes ' to ' is NOT a no-op

### Step 3: Remove issues (if any)

Use targeted Edit operations to remove specific lines:
- Remove duplicate entries (keep the first occurrence)
- Remove no-op entries

IMPORTANT: Only use Edit to delete problematic lines. Do not rewrite content.

### Step 4: Sort alphabetically

CRITICAL: Do not manually rewrite file content - this risks corrupting Unicode characters.

Use this bash pipeline to sort while preserving exact bytes:

```bash
head -n 6 backend/name_fixes.lua > backend/name_fixes_sorted.lua && \
grep '^\s*\[' backend/name_fixes.lua | sort >> backend/name_fixes_sorted.lua && \
echo "}" >> backend/name_fixes_sorted.lua && \
mv backend/name_fixes_sorted.lua backend/name_fixes.lua
```

### Step 5: Verify

Run tests again to confirm the file is valid:

```bash
cmd //c "busted tests/name_fixes_spec.lua"
```

## Output Format

```
Running tests...
[PASS/FAIL]

Found N issue(s):
- Removed duplicate: "Key Name"
- Removed no-op: "Key Name"

Sorted N entries alphabetically.

Verifying...
[PASS]

Done.
```

If no issues found and already sorted, report "No changes needed."
