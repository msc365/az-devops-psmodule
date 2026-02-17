<!-- omit from toc -->
# Contributing

Thanks for your interest in improving this module! We welcome fixes, features, tests, and docs from the community, and the guidelines below explain how to make contributions land smoothly.

Please read each section carefully so your contribution has the best chance of being accepted safely.

<!-- omit from toc -->
## Contents
- [Formatting guidelines](#formatting-guidelines)
- [Conventional commits](#conventional-commits)
- [Testing requirements](#testing-requirements)
- [Documentation requirements](#documentation-requirements)
- [Branching and PR workflow](#branching-and-pr-workflow)
- [Pull request expectations](#pull-request-expectations)
- [Local quality gates](#local-quality-gates)
- [Release hygiene](#release-hygiene)
- [Terminology](#terminology)
- [Markdown Styling](#markdown-styling)

## Formatting guidelines

### PowerShell

To make life a bit easier, a `.vscode/settings.json` file is configured to enforce _some_ of the syntax and style guidelines automatically. These will apply when `Saving` a file for example `ps1`, `json`, `yaml` or `md` files. For this to work you need to install the recommended `extensions` in vscode.

- Use `PascalCase` for _all_ public identifiers like module names, function names, properties, parameters, global variables and constants.
- Use `camelCase` for _all_ variables within functions (or modules) to distinguish private variables from parameters.
- Use `camelCase` for _all_ keys within Json files.
- Use `four` spaces per indentation level.
- Avoid using line continuation characters (`) in PowerShell code and examples.
- Use PowerShell [splatting](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_splatting) to reduce line length for cmdlets that have several parameters.
- Use [approved verbs](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands) for PowerShell Commands.
- Take notice of the [PowerShell development guidelines](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines) when you write modules or cmdlets.
- Take notice of the [PowerShell-Docs](https://learn.microsoft.com/en-us/powershell/scripting/community/contributing/powershell-style-guide) style guide when you write documentation content.
- Use [PlatyPS](src/PlatyPS.ps1) script with care. Do _NOT_ overwrite current docs, use a `tmp` directory to create your doc file, then adjust to align with reference documentation.
- Typed helper collections should use `[List[T]]::new()` so we can reuse small mutable lists across pagination loops without re-qualifying `System.Collections.Generic`.
  
  > Collections are supported via the module-wide `using namespace System.Collections.Generic`.

## Conventional commits

- Follow the [Conventional Commits](https://www.conventionalcommits.org/) spec so our tooling can automate the changelog (for example `feat(work): add iteration helper` or `fix(pipeline): handle PAT expiry`).
- Keep subjects under ~72 characters, use the optional body to describe context, and include `BREAKING CHANGE:` when behavior changes require user action.
- Squash or edit commits before review if needed so the final history reflects accurate types/scopes.

## Testing requirements

- Every PowerShell cmdlet must have a dedicated Pester test file that covers its primary behaviors, parameter validation, and error handling.
- You can bootstrap those tests with the GitHub agent prompt at [.github/prompts/generate-unit-tests.prompt.md](.github/prompts/generate-unit-tests.prompt.md); update or extend the generated tests so they reflect the cmdlet's current contract before opening a pull request.

## Documentation requirements

- (Re)generate the help files via [src/PlatyPS.ps1](src/PlatyPS.ps1) into a temporary folder, then hand-curate diffs before replacing existing docs to avoid accidental deletions.

## Branching and PR workflow

- Fork the repository and keep your fork updated by syncing or rebasing from upstream `main` before starting new work.
- Create feature branches in your fork (for example `feat/<area>-<summary>` or `fix/<issue>-<summary>`) and limit each branch to a single unit of work.
- Large pull requests are difficult to merge safely; split substantial changes into smaller, reviewable branches and submit separate PRs per feature or fix when possible.
- Link the related GitHub issue (or reference numbers) in your pull request description (not in title) so reviewers can trace requirements to code.
- Resolve review comments in-place and prefer incremental commits over force-pushing rewritten history so the discussion remains intact.

## Pull request expectations

- Only pull requests with passing CI builds can be merged; rerun or fix the pipeline before asking for approval.
- Confirm that you met every requirement in this guide (formatting, tests, docs, changelog) before opening the PR so reviewers can focus on the change itself.
- Opening a PR should automatically start CI; if the pipeline does not trigger or you need assistance, open an issue or start a discussion for help.

## Local quality gates

- Run `Invoke-PSake src/Build.ps1 -taskList Build` to ensure scripts compile, style checks pass, and the module still loads.
- Execute either `Invoke-PSake src/Build.ps1 -taskList Test` or the default `Test` VS Code task so Pester tests run locally before committing.
- If you touch PowerShell code, run `Invoke-ScriptAnalyzer -Settings src/PSScriptAnalyzerSettings.psd1` (or the equivalent task) to catch style or lint issues early.
- For documentation updates, preview the Markdown to verify content render properly and that any PlatyPS output matches the reference docs.

## Release hygiene

_Repository maintainers handle this section_.

- Update [CHANGELOG.md](CHANGELOG.md) with a concise summary of user-facing changes grouped under the upcoming release heading.
- Bump the module version inside [Build.ps1](src/Build.ps1) when your changes warrant a new release and keep the manifest metadata in sync.
- Confirm `src/Build.ps1 -taskList Publish` succeeds locally (or in CI) before tagging the release to ensure packaging artifacts are ready.

## Terminology
- `lowercase` - all lowercase, no word separation.
- `UPPERCASE` - all capitals, no word separation.
- `PascalCase` - capitalize the first letter of each word.
- `camelCase` - capitalize the first letter of each word _except_ the first.
- `kebab-case` - all lowercase, with dash (`-`) word separation.
- `snake_case` - all lowercase, with underscore (`_`) word separation.

## Markdown Styling

Use alerts to provide distinctive styling for significant content.

> [!NOTE]
> Useful information that users should know, even when skimming content.

> [!TIP]
> Helpful advice for doing things better or more easily.

> [!IMPORTANT]
> Key information users need to know to achieve their goal.

> [!WARNING]
> Urgent info that needs immediate user attention to avoid problems.

> [!CAUTION]
> Advises about risks or negative outcomes of certain actions.
