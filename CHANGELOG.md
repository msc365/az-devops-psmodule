# Changelog
<!-- markdownlint-disable MD024 -->

All notable changes to this project will be documented in this file.

<!-- ## [v0.0.1] - YYYY-MM-DD

### Summary
- _None_

### What's Changed
- feat: Add or update feature
- fix: Fixed issue
- chore: Common tasks
- docs: Add or update documentation

### Breaking Changes
- _None_

<br> -->

## [UNRELEASED]

### Summary
- _None_

### What's Changed
- feat(Get-AdoUser): Add user support (#124)
- feat(Get-AdoGroup): Add `domain` property to output (#126)
- fix(Get-AdoUserEntitlement): Correct error handling (#128)

### Breaking Changes
- _None_

<br>

## [0.4.0] - 2026-02-13

### Summary
Feature release adding repository initialization support, enhanced user entitlement data, and improved check/approval resource management.

### What's Changed
- feat(Get-AdoUserEntitlement): Add `dateCreated` property to output
- feat: Add `ResourceId` parameter to all Check and Approval cmdlets
- feat: Add `New-AdoPushInitialCommit` cmdlet for creating initial commits in Azure DevOps repositories
- chore: Using namespace `System.Collections.Generic` declaration at the module root
- chore(Build.ps1): Update module version to 0.4.0

### Breaking Changes
- _None_

<br>

## [0.3.0] - 2026-02-05

### Summary
In this feature release we focused on member entitlement management, unified pagination across collection-aware cmdlets, and reliability fixes for project and check creation scenarios.

### What's Changed
- refactor!: Align ContinuationToken process with `Get-AdoUserEntitlement` cmdlet
- feat(pr-code-testing): Enhance badge creation steps (#110)
- feat(Get-AdoUserEntitlement): Add user entitlement support (#106)
- fix(New-AdoProject): Update `Get-AdoProcess` call to include `CollectionUri` parameter ¹
- fix(New-AdoCheckBranchControl): Update `Get-AdoCheckConfiguration` call to include `CollectionUri` and `ProjectName` parameters ¹
- fix(New-AdoCheckBusinessHours): Update `Get-AdoCheckConfiguration` call to include `CollectionUri` and `ProjectName` parameters ¹
- chore(ReadMe): Add note about unreleased changes
- chore(Build.ps1): Update module version to 0.3.0

¹ Workaround: use `Set-AdoDefault -Organization 'devops-org-name' -Project 'devops-project-name'` before calling cmdlet.

### Breaking Changes
- `Get-AdoEnvironment`, `Get-AdoGroup`, `Get-AdoPolicyConfiguration`, `Get-AdoProject` and `Get-AdoUserEntitlement` no longer exposes the `ContinuationToken` parameter; pagination is now handled internally by the cmdlet.

### Contributors
Special thanks to [@Antiohne](https://github.com/Antiohne) for the `Get-AdoUserEntitlement` feature in this release.

<br>

## [0.2.3] - 2026-01-25

### Summary

Hotfix release focused on bug fixes and code quality improvements. Achieved 100% code coverage, resolved CollectionUri parameter logic issues, and standardized output property names for team iteration cmdlets. Includes a breaking change to output naming for better consistency.

### What's Changed
- fix: CollectionUri parameter default value logic issue (#100)
- chore: Update and improve code to achieve 100% code coverage (#101)
- fix: Bug `Set-AdoTeamSettings` backlog iteration not updating (#103)
- fix!: Update output names for consistency in `Add-AdoTeamIteration` and `Get-AdoTeamIteration` cmdlets (#103)  
  BREAKING CHANGE: Output team and project not available anymore, use teamName and projectName
- fix: Update property names in test assertions for in `Add-AdoTeamIteration` and `Get-AdoTeamIteration` cmdlets (#103)
- chore: Update CHANGELOG to reflect recent changes and fixes
- chore: Update build version to 0.2.3

### Breaking Changes
- With the output names update in `Add-AdoTeamIteration` and `Get-AdoTeamIteration` cmdlets the output names `team` and `project` are not available anymore, use `teamName` and `projectName` instead.

<br>

## [0.2.2] - 2026-01-23

### Summary

Maintenance release focused on removing unnecessary ShouldProcess support from cmdlets to simplify execution and improve usability. Updated API versions and fixed parameter usage in examples.

### What's Changed

- fix: Remove ShouldProcess support from multiple cmdlets to simplify execution flow (#92)
- fix: Update multiple test files to eliminate the use of the `-Confirm:$false` parameter (#92)
- fix: Update private test files to eliminate the use of the `-Confirm:$false` parameter (#93)
- fix: Remove ShouldProcess support from private cmdlets to simplify execution flow (#93)
- fix: Update default API version in Get-AdoMembership tests to '7.1-preview.1' (#94)
- fix: Update default API version in Get-AdoMembership cmdlet to '7.1-preview.1' (#94)
- fix: Update ScopeDescriptor parameter to use $projectDescriptor in Get-AdoGroup cmdlet example (#94)
- fix: Remove ShouldProcess logic from Get-AdoClassificationNode function (#95)
- chore: Update build version to 0.2.2 and improve script analyzer settings (#95)
- chore: Update CHANGELOG to reflect recent changes and fixes (#95)

### Breaking Changes
- _None_

<br>

## [0.2.1] - 2026-01-12

### Summary
This is a maintenance release focused on improving _Environment_ and _FeatureState_ cmdlet usability and output consistency. Enhanced parameter flexibility and enriched response objects for better integration scenarios.

### What's Changed
- fix: Update `Set-AdoEnvironment` Name param from mandatory to optional (#81)
- fix: Update `*-AdoEnvironment` cmdlets to return full user objects for `createdBy` and `lastModifiedBy` (#82)
- fix: Enhance output structure for `*-AdoFeatureState` cmdlets; update unit tests (#84)
- chore: Update CHANGELOG for v0.2.1 maintenance release (#85)
- chore: Update build version to 0.2.1 (#85)

### Breaking Changes
- _None_

<br>

## [0.2.0] - 2026-01-10

### Summary
Major feature release introducing pipeline approvals and checks, session defaults management, comprehensive unit testing, and CI/CD workflows. This release consolidates all alpha improvements with enhanced cmdlet functionality, standardized error handling, and improved documentation.

### What's Changed
- feat: Add pipeline Approvals and Checks support with multiple check types
- feat: Add session defaults management (`Set-AdoDefault`, `Get-AdoDefault`, `Remove-AdoDefault`)
- feat: Add `New-AdoCheckApproval`, `New-AdoCheckBranchControl` and `New-AdoCheckBusinessHours` with fine-grained control parameters
- feat: Add `Resolve-AdoDefinitionRef` helper function
- feat: Add CI/CD testing workflows with code analysis
- feat: Rename `New-AdoGroupAsMember` to `Add-AdoGroupMember` for clarity
- test: Add 750+ comprehensive Pester unit test files (all 757 tests passing)
- refactor: Standardized API version to `7.1` and `7.2-preview.1` when preview was required
- refactor: Enhanced parameter handling and validation across all cmdlets
- refactor: Standardized error handling with consistent exception messages
- refactor: Performance optimizations using Generic.List
- docs: Updated all cmdlet documentation with consistent formatting
- docs: Consolidated command documentation into single categorized table
- chore: Improved testing infrastructure with configurable Pester output

### Breaking Changes
- Removed `Get-AdoGroupList`, `Get-AdoProjectList`, `Get-AdoEnvironmentList` cmdlets (functionality merged into base cmdlets)
- Renamed `New-AdoGroupAsMember` to `Add-AdoGroupMember`
- Changed `Remove-AdoProject` to use _Name_ parameter instead of _Id_
- Changed `Set-AdoEnvironment` _EnvironmentId_ parameter from string to int32
- Updated `Get-AdoProject` parameter sets (ListProjects/ByNameOrId)

### Contributors
Special thanks to [@Antiohne](https://github.com/Antiohne) for the feature request, detailed feedback, and testing suggestions that shaped this release

<br>

## [0.2.0-alpha4] - 2026-01-05

### Summary
Added CI/CD testing workflows and cmdlet improvements for better clarity.

### What's Changed
- feat: Rename cmdlet `New-AdoGroupAsMember` into `Add-AdoGroupMember` (#29)
- feat: Add analysis and testing workflow (#30)
- chore: Remove push trigger from code analysis and testing workflow (#31)
- chore: Add badge for code analysis and testing workflow (#32)
- chore: Update workflow path triggers for code tests (#33)
- chore: Add changelog and update to `alpha4` in Build.ps1 (#34)

### Breaking Changes
- Renamed `New-AdoGroupAsMember` to `Add-AdoGroupMember` for clarity

<br>

## [0.2.0-alpha3] - 2025-12-20

### Summary
Enhanced approval check configurations with fine-grained control parameters.

### What's Changed
- feat: Enhanced `New-AdoCheckApproval` with _MinRequiredApprovers_, _ExecutionOrder_, and _RequesterCannotBeApprover_ parameters
- docs: Added comprehensive examples and parameter descriptions for approval configurations
- test: Added 9 new unit tests (all 28 tests passing)

### Breaking Changes
- _None_

<br>

## [0.2.0-alpha2] - 2025-12-10

### Summary
Comprehensive quality improvements through extensive unit testing and standardized documentation.

### What's Changed
- feat: Added `Resolve-AdoDefinitionRef` helper function for check definition resolution
- test: Added 30+ comprehensive Pester unit test files covering all cmdlets
- refactor: Enhanced cmdlet parameter handling and validation across _Core_, _Git_, _Graph_, and _Pipeline_ cmdlets
- refactor: Standardized error handling with consistent exception messages
- docs: Consolidated command documentation into single table with categories
- docs: Updated all cmdlet documentation with consistent formatting
- chore: Improved testing infrastructure with configurable Pester output levels

### Breaking Changes
- Renamed `New-AdoGroup` to `New-AdoGroupAsMember` for clarity
- Changed `Remove-AdoProject` to use _Name_ parameter instead of _Id_ for better consistency

<br>

## [0.2.0-alpha1] - 2025-12-01

### Summary
Major feature release introducing pipeline approvals, checks support, and session defaults management.

### What's Changed
- feat: Added pipeline Approvals and Checks support (`New-AdoCheckApproval`, `New-AdoCheckBranchControl`, `New-AdoCheckBusinessHours`)
- feat: Introduced session defaults management (`Set-AdoDefault`, `Get-AdoDefault`, `Remove-AdoDefault`)
- feat: Enhanced cmdlets with array support for bulk operations
- refactor: Standardized API version to `7.2-preview.1`
- refactor: Improved parameter naming consistency (_CollectionUri_, _ProjectName_ with _ProjectId_ alias)
- refactor: Performance optimizations using Generic.List instead of array concatenation
- docs: Updated documentation with Azure account authentication requirements

### Breaking Changes
- Removed `Get-AdoGroupList`, `Get-AdoProjectList`, `Get-AdoEnvironmentList` cmdlets (functionality merged into base cmdlets)
- Changed `Set-AdoEnvironment` _EnvironmentId_ parameter from string to int32
- Updated `Get-AdoProject` parameter sets (ListProjects/ByNameOrId)
- API version upgraded from `7.1` to `7.2-preview.1` for most endpoints

### Contributors
Special thanks to [@Antiohne](https://github.com/Antiohne) for the feature request, detailed feedback, and testing suggestions that shaped this release

<br>

## [0.1.1] - 2025-11-01

### Summary
Maintenance release with API improvements and documentation updates.

### What's Changed
- fix: Refactored API request body and headers for improved developer experience
- fix: Updated cmdlet descriptions and parameter details for clarity
- docs: Added missing cmdlet documentation
- docs: Updated badge colors in README for better visibility
- chore: Updated build version to 0.1.1

### Breaking Changes
- Changed input parameter type from `object` to `string` (JSON) for `New-AdoPolicyConfiguration`, `Set-AdoPolicyConfiguration`, and `Set-AdoTeamSettings`

<br>

## [0.1.0] - 2025-10-15

### Summary
Initial stable release with core Azure DevOps REST API cmdlets.

### What's Changed
- feat: Initial stable release
- feat: Core Azure DevOps REST API cmdlets
- feat: Authentication with Workload Identity Federation

### Breaking Changes
- _None_

<br>

---

For detailed release notes from previous versions, see the [releases page](https://github.com/msc365/az-devops-psmodule/releases).
