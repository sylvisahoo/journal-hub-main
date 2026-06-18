# CR Prompts 

# Project Analysis Prompt
Before implementing the change request, first analyze the existing project and understand how it currently works.

Please:

* Review the overall architecture and tech stack.
* Identify all modules, screens, APIs, database entities, and third-party integrations.
* Explain the purpose of each affected component.
* Analyze the change request and identify exactly which areas of the system will be impacted.
* Highlight dependencies, risks, edge cases, and potential side effects.
* Recommend the best implementation approach.

Provide a concise report covering:

1. Current system overview
2. Affected modules/components
3. Required frontend changes
4. Required backend changes
5. Database/API impact
6. Risks and considerations
7. Step-by-step implementation plan

Do not start coding yet. First understand the project and present your findings.

# Comparison 
Compare the Existing KPI and New Enhancement KPI documents and identify all differences.

Please:

* Match related KPIs.
* Highlight new, modified, and removed requirements.
* Categorize each change as New Feature, Enhancement, Modification, or Removal.
* Identify the impacted modules.

Output format:

### Summary

* New Features
* Enhancements
* Modifications
* Removals

### Change Log

| Module | Existing KPI | New KPI | Change Type | Impact |
| ------ | ------------ | ------- | ----------- | ------ |

Also provide a brief estimate of frontend, backend, database, and testing impact for each module.


# Change Request Verification & Implementation

Review the existing Personal Journal App codebase and verify whether the following enhancement features are already implemented.

## Tasks

1. Perform a complete codebase audit.

2. Compare the current implementation against the enhancement feature list below.

3. Create a report named `enhancement_audit.md` containing:

    * Feature Name
    * Status (Implemented / Partially Implemented / Missing)
    * Files affected
    * Recommended implementation approach

4. For all features marked as **Missing** or **Partially Implemented**:

    * Implement the feature completely.
    * Follow the existing project architecture, coding standards, and UI patterns.
    * Update database schema, APIs, state management, and UI where required.
    * Ensure responsive behavior on mobile and web.
    * Add validation, error handling, and tests where applicable.

## Enhancement Features

* Entry Templates (Gratitude, Dream Log, Travel Diary, Daily Reflection, etc.)
* Export Journal Entries to PDF and HTML
* Word Count Tracking with Daily/Weekly Goals
* Entry Tagging System with Tag Cloud Visualization
* Advanced Search with Date Range, Tags, and Entry Length Filters
* Dark/Light Theme Toggle with Preference Persistence
* Entry Statistics Dashboard (entries, streaks, writing frequency, trends)
* Backup and Restore Functionality (Export/Import Journal Data)
* Rich Text Editor (bold, italic, headings, lists, quotes)
* Journal Entry Categories (Personal, Work, Ideas, Reflections, etc.)

## Deliverables

* enhancement_audit.md
* Updated source code
* Database migrations (if required)
* API changes (if required)
* UI updates
* Test results summary


