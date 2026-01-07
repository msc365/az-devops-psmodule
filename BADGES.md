# Badge Setup Instructions

## Overview
Dynamic badges have been configured to display:
- **Test Count Badge**: Shows number of passing tests (e.g., "42/45 passing")
- **Code Analysis Badge**: Shows PSScriptAnalyzer results (e.g., "passing" or "0 errors, 2 warnings")

## Setup Required

### 1. Create a GitHub Gist
1. Go to <https://gist.github.com/>
2. Create a new **secret** gist with any content (it will be overwritten)
3. Copy the gist ID from the URL (e.g., `https://gist.github.com/MSc365Admin/abc123def456` → ID is `abc123def456`)

### 2. Create a Personal Access Token (PAT)
1. Go to GitHub Settings → Developer Settings → Personal Access Tokens → Tokens (classic)
2. Generate a new token with the **`gist`** scope only
3. Copy the token value (you won't be able to see it again)

### 3. Add Repository Secrets
In your repository settings (Settings → Secrets and variables → Actions):

1. Add secret `GIST_TOKEN`:
   - Value: The PAT you created in step 2

2. Add secret `GIST_ID`:
   - Value: The gist ID you copied in step 1

### 4. Update README.md
Replace `GIST_ID` in the README.md badge URLs with your actual gist ID:

**Before:**
```markdown
[![pester-tests](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/MSc365Admin/GIST_ID/raw/az-devops-psmodule-test-badge.json)]
[![code-analysis](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/MSc365Admin/GIST_ID/raw/az-devops-psmodule-analysis-badge.json)]
```

**After (example):**
```markdown
[![pester-tests](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/MSc365Admin/abc123def456/raw/az-devops-psmodule-test-badge.json)]
[![code-analysis](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/MSc365Admin/abc123def456/raw/az-devops-psmodule-analysis-badge.json)]
```

## How It Works

1. When the workflow runs on the `main` branch:
   - PSScriptAnalyzer captures error and warning counts
   - Pester tests capture total, passed, and failed counts

2. Badge data is generated and uploaded to the gist using the `schneegans/dynamic-badges-action`

3. Shields.io endpoint badges read the gist JSON files and display them

4. Badges update automatically on every main branch workflow run

## Badge Examples

### Test Badge
- ✅ `42/42 passing` (green) - All tests passed
- ❌ `40/42 passing` (red) - Some tests failed

### Code Analysis Badge
- ✅ `passing` (green) - No errors or warnings
- ⚠️ `0 errors, 3 warnings` (yellow) - Only warnings
- ❌ `2 errors, 5 warnings` (red) - Has errors

## Troubleshooting

**Badges not updating?**
- Verify secrets are set correctly
- Check workflow runs for errors
- Ensure workflow runs on `main` branch (badges only update there)
- Wait a few minutes and clear your browser cache

**Badge shows "invalid"?**
- Check that the gist ID in README matches your actual gist ID
- Verify the gist filenames match those in the workflow
- Ensure the gist is accessible (should be secret, not private)

## Alternative: Simple Workflow Status Badge

If you prefer a simpler solution without dynamic counts, you can use the standard workflow status badge:

```markdown
[![tests](https://github.com/msc365/az-devops-psmodule/actions/workflows/pr-code-testing.yml/badge.svg?branch=main)](https://github.com/msc365/az-devops-psmodule/actions/workflows/pr-code-testing.yml)
```

This shows simple pass/fail status but not test counts.
