# Backend Setup

## Role
Act as the Backend Engineer. Read and follow:

* [backend-developer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/backend-developer.md) 
* [save-token.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/save-token.md) 

Adopt all standards, responsibilities, and token-saving instructions.

## Action
Execute all tasks under:

[execution-plan.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/execution-plan.md) → 1.3 Development Environment Setup → Backend Setup

Complete each step in sequence without skipping.

## Context

Project: Journal Hub

Backend must support:

* Authentication
* Journal entries
* Tags
* Search & filters
* Calendar view
* Sharing
* Analytics
* Export

Strictly Follow [backend-developer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/backend-developer.md)for Technical Standards and Responsibilities.

## Execute

For each completed step, provide:

* Task completed
* Files created/updated
* Validation performed
* Next step

Follow [save-token.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/save-token.md)  throughout the execution and continue until all Backend Setup tasks in Section 1.3 are complete.

----

# Database Setup

## Role
Act as the Backend Engineer. Read and follow:

* [backend-developer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/backend-developer.md) 
* [save-token.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/save-token.md) 

Adopt all standards, responsibilities, and token-saving instructions.

## Action
Execute all tasks under:

[execution-plan.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/execution-plan.md) → Phase 2: Database Design

Complete each step in sequence without skipping.

## Context

Project: Journal Hub

Backend must support:

* Authentication
* Journal entries
* Tags
* Search & filters
* Calendar view
* Sharing
* Analytics
* Export

Strictly Follow:
[backend-developer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/backend-developer.md)for Technical Standards and Responsibilities. 


## Execute

For each completed step, provide:

* Task completed
* Files created/updated
* Validation performed
* Next step

Follow [save-token.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/save-token.md)  throughout the execution and continue until all Backend Setup tasks in Section 1.3 are complete.

----

# Flutter Frontend Setup

## Role
Act as the Frontend Flutter Engineer. Read and follow:

*  [flutter-developer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/flutter-developer.md) 
* [save-token.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/save-token.md) 

Adopt all standards, responsibilities, and token-saving instructions.

## Action
Execute all tasks under:

[execution-plan.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/execution-plan.md) → 1.3 Development Environment Setup -> Frontend Setup

Complete each step in sequence without skipping.

## Context

Project: Journal Hub
Folder Path : outputs/frontend

Strictly Follow:
[flutter-developer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/flutter-developer.md) for Technical Standards and Responsibilities. 


## Execute

For each completed step, provide:

* Task completed
* Files created/updated
* Validation performed
* Next step

Follow [save-token.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/save-token.md)  throughout the execution and continue until all Frontend Setup task completed.


----

# Flutter UI Implementation with Mock Data

## Role
Act as a Senior Flutter Developer.

Read and follow:

* [flutter-developer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/flutter-developer.md) 
* [save-token.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/save-token.md) 

Adopt all coding standards, architecture guidelines, and token-saving practices.

## Action

Implement the Stitch-generated UI screens into the Flutter project.

For this phase:

1. Build all UI screens and navigation flows.
2. Create reusable widgets and layouts.
3. Connect screens using mock repositories/services only.
4. Populate screens with realistic mock data.
5. Simulate loading, success, empty, and error states.
6. Do NOT implement real API integration.
7. Do NOT implement backend business logic.
8. Focus on validating the complete user workflow.

## Context

The goal is to verify the end-to-end user experience before backend integration.

Use mock data for:

* Authentication
* User profile
* Journal entries
* Tags
* Search results
* Calendar data
* Analytics dashboard
* Shared entries

The application should feel fully functional from a user's perspective.

@mcp:StitchMCP:get_project:1171524168852387012

Screen ID: Digital Journal System

## Execute

For each screen:

* Implement UI from Stitch design.
* Create mock models and repositories if needed.
* Connect navigation and user flows.
* Verify screen responsiveness.
* Test happy path and edge states.

After each completed screen provide:

* Files created/updated
* Mock data added
* Navigation connected
* UI validation performed
* Next screen to implement

Goal: Complete a clickable, testable MVP UI with mock data so the entire journal workflow can be tested before API integration.

---


# Flutter Email Verification Bypass in SignUp Flow

## Role
Act as a Senior Flutter Developer.

## Action
Remove email verification functionality in SignUp Flow

## Context
Currently, the QA team is blocked from testing the complete user workflow because the backend email verification mechanism is not yet implemented. To unblock testing, we need to bypass this step.

Execute:
Provide the updated Flutter code for the modified navigation/authentication flow and the mock data setup, ensuring it is ready for QA to compile and test immediately.

Goal: Modify the authentication flow to remove the email verification blocking step and deliver a fully clickable, testable end-to-end MVP UI with mock data.

---

# Fixing Flutter UI Implementation

## Role
Act as a Senior Flutter Developer.

## Action
Debug the route cause and fix the Settings flow.

## Context
QA team found the issue while testing the settings flow, Settings functionality is not working as expected.

Execute:
Provide the updated Flutter code for the modified navigation/settings flow and the mock data setup, ensuring it is ready for QA to compile and test immediately.

Goal: Modify the settings flow deliver a fully clickable, testable end-to-end MVP UI with mock data.

---

# Module 1: User Registration & Verification Backend  Implementation

## Role

Act as the Backend Engineer.

Read:

* [backend-developer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/backend-developer.md) 
* [save-token.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/save-token.md) 

## Action

Implement the backend for Module: Module 1: User Registration & Verification.

Only work on this module.

Complete:

* Database changes
* Models
* Repositories
* Services
* API endpoints
* Validation
* Security
* Unit tests

## Context

Frontend screens already exist.

API contracts must support existing UI without requiring UI redesign.

## Execute

Provide:

* Architecture decisions
* Files created/updated
* Database changes
* API endpoints
* Test coverage
* Postman/API examples

Stop when the module is fully implemented and ready for QA testing.

---

# Module 1: User Registration & Verification Frontend  Implementation

## Role

Act as Senior Flutter Developer.

Read:

* [flutter-developer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/flutter-developer.md) 
* [save-token.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/save-token.md) 

## Action

Replace mock data for Module: Module 1: User Registration & Verification.

Connect the UI to the real backend APIs.

## Context

UI already exists and workflow has been validated using mock data.

Do not redesign screens.

## Execute

* Replace mock repositories
* Connect APIs
* Handle loading states
* Handle error states
* Validate forms
* Update state management

Provide:

* Files modified
* APIs connected
* Test results
* Remaining blockers

---

# Module 1: User Registration & Verification QA Testing

## Role

Act as Senior Quality Assurance Engineer

Read:

* [qa-engineer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/qa-engineer.md) 
* [save-token.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/save-token.md) 

## Action

Test Module: Module 1: User Registration & Verification.

Perform functional, integration, validation, and workflow testing.

## Context

Backend and frontend implementation for this module are complete.

The goal is to determine whether the module is production-ready.

## Execute
Generate: Test cases report and defect report 

Strictly follow guideline which mentioned in [qa-engineer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/qa-engineer.md) 

--- 

# Defects Fixing Module 1: User Registration & Verification QA Findings

Read and follow:

* [backend_setup.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/walkthrough/backend_setup.md) 
* [flutter-developer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/flutter-developer.md) 
* [save-token.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/save-token.md) 

## Action
Analyze QA report [user-registration-%26-verification-defect-reports.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/testing-artifacts/user-registration-%26-verification-defect-reports.md)  and implement fixes.

## Context

The module has already been developed and tested. Your objective is to resolve all reported issues without introducing regressions or changing approved functionality.

## Execute

For each finding:
1. Identify root cause.
2. Implement the fix.
3. Verify the fix.
4. Check for related regressions.
5. Update tests if required.

After all fixes are completed

generate:

* qa-fixes-summary.md

Folder Path : outputs/

Include:

* Total issues received
* Issues fixed
* Remaining issues
* Risks/Dependencies
* Ready for QA Retest (Yes/No)

Do not implement new features, refactor unrelated code, or modify approved workflows. Focus only on resolving QA findings and preparing the module for QA re-validation.

---

# Email Verification Flow Bypass

The email verification flow is currently blocked because verification tokens are not being delivered to users' email addresses.

For demo purposes, bypass the email verification dependency by hardcoding the verification token for all users.

Requirements:

* Set the verification token to: `123456`
* Accept `123456` as a valid verification token for every user.
* Skip email token generation and email delivery during the demo.
* Ensure users can successfully complete the email verification step using the hardcoded token.

---

# Module 2: Authentication & Session Management Backend  Implementation

## Role

Act as the Backend Engineer.

Read:

* [backend-developer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/backend-developer.md) 
* [save-token.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/save-token.md) 

## Action

Implement the backend for Module: Module 2: Authentication & Session Management.

Only work on this module.

Complete:

* Database changes
* Models
* Repositories
* Services
* API endpoints
* Validation
* Security
* Unit tests

## Context

Frontend screens already exist.

API contracts must support existing UI without requiring UI redesign.

## Execute

Provide:

* Architecture decisions
* Files created/updated
* Database changes
* API endpoints
* Test coverage
* Postman/API examples

Stop when the module is fully implemented and ready for QA testing.

---

# Module 2: Authentication & Session Management Frontend Implementation

## Role

Act as Senior Flutter Developer.

Read:

* [flutter-developer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/flutter-developer.md) 
* [save-token.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/save-token.md) 

## Action

Replace mock data for Module: Module 2: Authentication & Session Management
Connect the UI to the real backend APIs.

## Context

UI already exists and workflow has been validated using mock data.

Do not redesign screens.

## Execute

* Replace mock repositories
* Connect APIs
* Handle loading states
* Handle error states
* Validate forms
* Update state management

Provide:

* Files modified
* APIs connected
* Test results
* Remaining blockers

---

# Defects Fixing Module 2: Authentication & Session Management QA Findings

Read and follow:

* [backend_setup.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/walkthrough/backend_setup.md) 
* [flutter-developer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/flutter-developer.md) 
* [save-token.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/save-token.md) 

## Action
Analyze QA report [authentication-session-management-defect-reports.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/testing-artifacts/authentication-session-management/authentication-session-management-defect-reports.md) 

## Context

The module has already been developed and tested. Your objective is to resolve all reported issues without introducing regressions or changing approved functionality.

## Execute

For each finding:
1. Identify root cause.
2. Implement the fix.
3. Verify the fix.
4. Check for related regressions.
5. Update tests if required.

After all fixes are completed

update:

* [qa-fixes-summary.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/qa-fixes-summary.md) 
Folder Path : outputs/

after fixes the update latest status the [authentication-session-management-test-cases-report.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/testing-artifacts/authentication-session-management/authentication-session-management-test-cases-report.md) 


Include:

* Total issues received
* Issues fixed
* Remaining issues
* Risks/Dependencies
* Ready for QA Retest (Yes/No)

Do not implement new features, refactor unrelated code, or modify approved workflows. Focus only on resolving QA findings and preparing the module for QA re-validation.

---

# Sprint 2 Modules Backend Implementation

## Module 3: Journal Entry Creation
## Module 4: Journal Entry Editing
## Module 5: Journal Entry Deletion


## Role

Act as the Backend Engineer.

Read:

* [backend-developer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/backend-developer.md) 
* [save-token.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/save-token.md) 

## Action

Implement the backend for Sprint 2 :- Module 3,4,5

Only work on this module.

Complete:

* Database changes
* Models
* Repositories
* Services
* API endpoints
* Validation
* Security
* Unit tests

## Context

Frontend screens already exist.

API contracts must support existing UI without requiring UI redesign.

## Execute

Provide:

* Architecture decisions
* Files created/updated
* Database changes
* API endpoints
* Test coverage
* Postman/API examples

Stop when the module is fully implemented and ready for QA testing.

---

# Sprint 2 Modules Frontend Implementation

## Module 3: Journal Entry Creation
## Module 4: Journal Entry Editing
## Module 5: Journal Entry Deletion


## Role

Act as Senior Flutter Developer.

Read:

* [flutter-developer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/flutter-developer.md) 
* [save-token.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/save-token.md) 

## Action

Replace mock data for Sprint 2 :- Module 3,4,5


Connect the UI to the real backend APIs.

## Context

UI already exists and workflow has been validated using mock data.

Do not redesign screens.

## Execute

* Replace mock repositories
* Connect APIs
* Handle loading states
* Handle error states
* Validate forms
* Update state management

Provide:

* Files modified
* APIs connected
* Test results
* Remaining blockers

---

# Sprint 2 Modules QA Testing

## Module 3: Journal Entry Creation
## Module 4: Journal Entry Editing
## Module 5: Journal Entry Deletion

## Role

Act as Senior Quality Assurance Engineer

Read:

* [qa-engineer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/qa-engineer.md) 
* [save-token.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/save-token.md) 

## Action

Test Sprint 2 :- Module 3,4,5

Perform functional, integration, validation, and workflow testing.

## Context

Backend and frontend implementation for this module are complete.

The goal is to determine whether the module is production-ready.

## Execute
Generate: Test cases report and defect report 

Strictly follow guideline which mentioned in [qa-engineer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/qa-engineer.md) 

---

# Sprint 3 Modules Backend Implementation

## Module 6: Search & Filtering
## Module 7: Calendar Navigation


## Role

Act as the Backend Engineer.

Read:

* [backend-developer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/backend-developer.md) 
* [save-token.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/save-token.md) 

## Action

Implement the backend for Sprint 3 :- Module 6,7

Only work on this module.

Complete:

* Database changes
* Models
* Repositories
* Services
* API endpoints
* Validation
* Security
* Unit tests

## Context

Frontend screens already exist.

API contracts must support existing UI without requiring UI redesign.

## Execute

Provide:

* Architecture decisions
* Files created/updated
* Database changes
* API endpoints
* Test coverage
* Postman/API examples

Stop when the module is fully implemented and ready for QA testing.

---

# Sprint 3 Modules Frontend Implementation

## Module 6: Search & Filtering
## Module 7: Calendar Navigation


## Role

Act as Senior Flutter Developer.

Read:

* [flutter-developer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/flutter-developer.md) 
* [save-token.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/save-token.md) 

## Action

Replace mock data for Sprint 3 :- Module 6,7


Connect the UI to the real backend APIs.

## Context

UI already exists and workflow has been validated using mock data.

Do not redesign screens.

## Execute

* Replace mock repositories
* Connect APIs
* Handle loading states
* Handle error states
* Validate forms
* Update state management

Provide:

* Files modified
* APIs connected
* Test results
* Remaining blockers

---

# Sprint 3 Modules QA Testing

## Module 6: Search & Filtering
## Module 7: Calendar Navigation

## Role

Act as Senior Quality Assurance Engineer

Read:

* [qa-engineer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/qa-engineer.md) 
* [save-token.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/save-token.md) 

## Action

Test Sprint 3 :- Module 6,7

Perform functional, integration, validation, and workflow testing.

## Context

Backend and frontend implementation for this module are complete.

The goal is to determine whether the module is production-ready.

## Execute
Generate: Test cases report and defect report 

Strictly follow guideline which mentioned in [qa-engineer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/qa-engineer.md) 


---

# Defects Fixing Sprint 3 Modules 

Read and follow:

* [backend_setup.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/walkthrough/backend_setup.md) 
* [flutter-developer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/flutter-developer.md) 
* [save-token.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/save-token.md) 

## Action
Analyze QA report 
[search-filtering-calendar-navigation-defect-reports.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/testing-artifacts/search-filtering-calendar-navigation/search-filtering-calendar-navigation-defect-reports.md) 

## Context

The module has already been developed and tested. Your objective is to resolve all reported issues without introducing regressions or changing approved functionality.

## Execute

For each finding:
1. Identify root cause.
2. Implement the fix.
3. Verify the fix.
4. Check for related regressions.
5. Update tests if required.

After all fixes are completed

update:

* [qa-fixes-summary.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/qa-fixes-summary.md) 
Folder Path : outputs/

after fixes the update latest status the [search-filtering-calendar-navigation-test-cases-report.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/testing-artifacts/search-filtering-calendar-navigation/search-filtering-calendar-navigation-test-cases-report.md) 

Include:

* Total issues received
* Issues fixed
* Remaining issues
* Risks/Dependencies
* Ready for QA Retest (Yes/No)

Do not implement new features, refactor unrelated code, or modify approved workflows. Focus only on resolving QA findings and preparing the module for QA re-validation.

---

# Sprint 4 Modules Backend Implementation

## Module 8: Journal Sharing
## Module 9: Analytics Dashboard


## Role

Act as the Backend Engineer.

Read:

* [backend-developer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/backend-developer.md) 
* [save-token.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/save-token.md) 

## Action

Implement the backend for Sprint 4 :- Module 8,9

Only work on this module.

Complete:

* Database changes
* Models
* Repositories
* Services
* API endpoints
* Validation
* Security
* Unit tests

## Context

Frontend screens already exist.

API contracts must support existing UI without requiring UI redesign.

## Execute

Provide:

* Architecture decisions
* Files created/updated
* Database changes
* API endpoints
* Test coverage
* Postman/API examples

Stop when the module is fully implemented and ready for QA testing.

---

# Sprint 4 Modules Frontend Implementation

## Module 8: Journal Sharing
## Module 9: Analytics Dashboard

## Role

Act as Senior Flutter Developer.

Read:

* [flutter-developer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/flutter-developer.md) 
* [save-token.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/save-token.md) 

## Action

Replace mock data for Sprint 4 :- Module 8,9


Connect the UI to the real backend APIs.

## Context

UI already exists and workflow has been validated using mock data.

Do not redesign screens.

## Execute

* Replace mock repositories
* Connect APIs
* Handle loading states
* Handle error states
* Validate forms
* Update state management

Provide:

* Files modified
* APIs connected
* Test results
* Remaining blockers

---

# Sprint 4 Modules QA Testing

## Module 8: Journal Sharing
## Module 9: Analytics Dashboard

## Role

Act as Senior Quality Assurance Engineer

Read:

* [qa-engineer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/qa-engineer.md) 
* [save-token.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/save-token.md) 

## Action

Test Sprint 4 :- Module 8,9

Perform functional, integration, validation, and workflow testing.

## Context

Backend and frontend implementation for this module are complete.

The goal is to determine whether the module is production-ready.

## Execute
Generate: Test cases report and defect report 

Strictly follow guideline which mentioned in [qa-engineer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/qa-engineer.md) 

---

# Sprint 5 Modules Backend Implementation

## Module 10: Data Export
## Module 11: Draft Preservation & Offline Handling


## Role

Act as the Backend Engineer.

Read:

* [backend-developer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/backend-developer.md) 
* [save-token.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/save-token.md) 

## Action

Implement the backend for Sprint 5 :- Module 10,11

Only work on this module.

Complete:

* Database changes
* Models
* Repositories
* Services
* API endpoints
* Validation
* Security
* Unit tests

## Context

Frontend screens already exist.

API contracts must support existing UI without requiring UI redesign.

## Execute

Provide:

* Architecture decisions
* Files created/updated
* Database changes
* API endpoints
* Test coverage
* Postman/API examples

Stop when the module is fully implemented and ready for QA testing.

---

# Sprint 5 Modules Frontend Implementation

## Module 10: Data Export
## Module 11: Draft Preservation & Offline Handling



## Role

Act as Senior Flutter Developer.

Read:

* [flutter-developer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/flutter-developer.md) 
* [save-token.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/save-token.md) 

## Action

Replace mock data for Sprint 5 :- Module 10,11


Connect the UI to the real backend APIs.

## Context

UI already exists and workflow has been validated using mock data.

Do not redesign screens.

## Execute

* Replace mock repositories
* Connect APIs
* Handle loading states
* Handle error states
* Validate forms
* Update state management

Provide:

* Files modified
* APIs connected
* Test results
* Remaining blockers

___

# Sprint 5 Modules QA Testing

## Module 10: Data Export
## Module 11: Draft Preservation & Offline Handling


## Role

Act as Senior Quality Assurance Engineer

Read:

* [qa-engineer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/qa-engineer.md) 
* [save-token.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/save-token.md) 

## Action

Test Sprint 5 :- Module 10,11

Perform functional, integration, validation, and workflow testing.

## Context

Backend and frontend implementation for this module are complete.

The goal is to determine whether the module is production-ready.

## Execute
Generate: Test cases report and defect report 

Strictly follow guideline which mentioned in [qa-engineer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/qa-engineer.md) 

---

# Defects Fixing Sprint 5 Modules 

Read and follow:

* [backend_setup.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/walkthrough/backend_setup.md) 
* [flutter-developer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/flutter-developer.md) 
* [save-token.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/save-token.md) 

## Action
Analyze QA report 


## Context

The module has already been developed and tested. Your objective is to resolve all reported issues without introducing regressions or changing approved functionality.

## Execute

For each finding:
1. Identify root cause.
2. Implement the fix.
3. Verify the fix.
4. Check for related regressions.
5. Update tests if required.

After all fixes are completed

update:

* [qa-fixes-summary.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/qa-fixes-summary.md) 
Folder Path : outputs/

after fixes the update latest status the [data-export-draft-preservation-offline-handling-test-cases-report.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/testing-artifacts/data-export-draft-preservation-offline-handling/data-export-draft-preservation-offline-handling-test-cases-report.md) 


Include:

* Total issues received
* Issues fixed
* Remaining issues
* Risks/Dependencies
* Ready for QA Retest (Yes/No)

Do not implement new features, refactor unrelated code, or modify approved workflows. Focus only on resolving QA findings and preparing the module for QA re-validation.


___

# Debug & Fix Journal Entries Flow

## Role

Act as a Senior Flutter & Backend Engineer.

Before making any changes, read and follow:

* [backend-developer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/backend-developer.md) 
* [flutter-developer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/flutter-developer.md) 
* [save-token.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/save-token.md) 

Adhere to all architecture, coding standards, debugging guidelines, and token-saving practices.

---

## Action

Resolve the issues in the **Journal Entries** feature.

Focus only on fixing defects. Do **not** introduce new features, refactor unrelated code, or modify approved workflows.

---

## Context

The Journal Entries module has already been implemented and previously tested.

### Reported Issue

**Flow:**

1. User logs into the application.
2. User creates a new journal entry.
3. User taps **Save**.
4. A white screen appears.
5. Returning to the app causes it to crash.

Your objective is to identify the root cause, implement a fix.

---

## Execute

### Investigation

* Reproduce the issue.
* Analyze logs, stack traces, and runtime exceptions.
* Identify the root cause (Frontend, Backend, Navigation, API, State Management, Database, or Serialization).

### Fix

* Implement the minimum required fix.
* Preserve existing functionality and architecture.
* Ensure no regressions are introduced.

### Deliverables

Generate the following report:

**outputs/qa-fixes-summary.md**

Include:

* Issue Summary
* Root Cause Analysis
* Files Modified
* Fixes Implemented
* Total Issues Received
* Total Issues Fixed
* Remaining Issues
* Risks / Dependencies
* Ready for QA Retest (Yes/No)

Complete the task only when the Journal Entries flow is stable, crash-free, and ready for QA re-validation.


---


# Sprint 6 Final QA & Production Readiness

## Role

Act as a Senior Quality Assurance Engineer.

Read and follow:

* [qa-engineer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/qa-engineer.md) 
* [save-token.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/save-token.md) 

Adopt all QA standards, testing guidelines, reporting formats, and token-saving practices.


## Action

Execute Sprint 6 for:

* Module 12: Mobile Responsiveness & UX
* Module 13: Security, Performance & Reliability

Then perform a complete end-to-end application validation covering all 13 modules  and 100 KPIs.

Use the following as the source of truth:

* [master-kpi.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/master-kpi.md) 
* [execution-plan.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/execution-plan.md) 

Do not skip any KPI, feature, workflow, or acceptance criterion.


## Context

The frontend and backend implementations are complete.

Your objective is to verify that the application is production-ready through comprehensive functional, integration, UI/UX, security, performance, reliability, regression, and end-to-end workflow testing.


## Execute

Generate:

1. **test-cases-report.md**

   * Test Case ID
   * Module
   * KPI Reference
   * Scenario
   * Expected Result
   * Actual Result
   * Status (PASS / FAIL)

2. **defect-report.md**

   * Defect ID
   * Module
   * Severity
   * Priority
   * Steps to Reproduce
   * Expected vs Actual
   * Impact
   * Recommendation

3. **production-readiness-report.md**

   * KPI Coverage Summary
   * Module-wise Summary
   * Overall Pass Rate
   * Open Defects
   * Critical Risks
   * Production Readiness Verdict

Final Verdict:

* ✅ Ready for Production
* ⚠️ Ready with Minor Issues
* ❌ Not Ready for Production

Follow [qa-engineer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/qa-engineer.md)  strictly throughout the execution and preserve progress using **save-token.md**.

---

# QA Lead Validation

## Role

Act as the QA Lead Engineer

Before starting, read and follow:

* [qa-lead-engineer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/qa-lead-engineer.md) 
* [save-token.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/save-token.md)
[master-kpi.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/master-kpi.md) 
[execution-plan.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/execution-plan.md) 

Adopt all QA standards, testing strategies, reporting guidelines, and token-saving practices.

---

## Action

Perform a comprehensive quality assessment of the requested scope.

Analyze the implementation and determine the most appropriate testing strategy. Select and execute the required testing mode(s) based on the current development stage, implementation status, and associated risks.

Do not assume previous QA reports are correct. Validate the application independently.

---

## Context

Scope:
**[Feature / Module / Sprint / Entire Application]**

Relevant documents:

* PRD
* Feature Catalogue
* BDD Scenarios
* Execution Plan
* Master KPI
* Previous QA Reports (if available)

Frontend and backend implementations are available for testing.

---

## Execute

### Phase 1 – Test Planning

* Analyze the scope.
* Identify dependencies.
* Select appropriate testing mode(s).
* Define test coverage.

### Phase 2 – Test Execution

Execute all selected testing modes while validating:

* Business requirements
* User workflows
* UI/UX
* Navigation
* API integration
* Data integrity
* State management
* Error handling
* Edge cases
* Performance
* Security
* Accessibility
* Responsive behavior
* Cross-module integration
* Regression risks

Attempt to discover hidden defects through exploratory testing and realistic user behavior.

Continue testing until no additional critical issues are identified.

### Phase 3 – Reporting

Generate all applicable reports under:

`outputs/testing-artifacts/qa-lead-engineer-report/`

Examples include:

* test-cases-report.md
* defect-report.md
* regression-report.md
* exploratory-test-report.md
* sanity-test-report.md
* end-to-end-test-report.md
* production-readiness-report.md
* qa-fixes-summary.md

Generate only the reports relevant to the selected testing strategy.

---

## Final Review

Provide:

* Test Coverage Summary
* Defect Summary
* Risk Assessment
* Regression Impact
* Overall Quality Score
* Production Readiness Assessment
* Recommended Developer Actions

Final Verdict:

* ✅ Approved for Release
* ⚠️ Approved with Minor Issues
* 🔄 Rework Required
* ❌ Release Blocked

Do not approve the application if any critical defects, major regressions, workflow failures, or release-blocking issues remain unresolved.

---

# Debug & Fix Journal Entries Flow

## Role

Act as a Senior Flutter & Backend Engineer.

Before making any changes, read and follow:

* [backend-developer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/backend-developer.md) 
* [flutter-developer.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/personas/flutter-developer.md) 
* [save-token.md](file;file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/agent-prompts/md-files/save-token.md) 

Adhere to all architecture, coding standards, debugging guidelines, and token-saving practices.

---

## Action

Debug and resolve the issues in the **Journal Entries** feature.

Focus only on fixing defects. Do **not** introduce new features, refactor unrelated code, or modify approved workflows.

After implementing fixes, perform end-to-end validation of the Journal Entries flow.

---

## Context

The Journal Entries module has already been implemented and previously tested.

### Reported Issue

**Flow:**

1. User logs into the application.
2. User creates a new journal entry.
3. User taps **Save**.
4. A white screen appears.
5. Returning to the app causes it to crash.

Your objective is to identify the root cause, implement a fix, and ensure the complete flow works reliably without regressions.

---

## Execute

### Investigation

* Reproduce the issue.
* Analyze logs, stack traces, and runtime exceptions.
* Identify the root cause (Frontend, Backend, Navigation, API, State Management, Database, or Serialization).

### Fix

* Implement the minimum required fix.
* Preserve existing functionality and architecture.
* Ensure no regressions are introduced.

### Validation

Verify the complete workflow:

* User Login
* Create Journal Entry
* Save Entry
* Successful Navigation
* Entry Persistence
* Journal List Refresh
* View Saved Entry
* Edit Entry
* Delete Entry (if applicable)
* App Stability (no crashes or white screens)

Also verify:

* Loading states
* Error handling
* Navigation flow
* State synchronization
* API responses
* Database persistence

### Deliverables

Generate the following report:

**outputs/qa-fixes-summary.md**

Include:

* Issue Summary
* Root Cause Analysis
* Files Modified
* Fixes Implemented
* Validation Results
* Regression Checks Performed
* Total Issues Received
* Total Issues Fixed
* Remaining Issues
* Risks / Dependencies
* Ready for QA Retest (Yes/No)

Complete the task only when the Journal Entries flow is stable, crash-free, and ready for QA re-validation.

---