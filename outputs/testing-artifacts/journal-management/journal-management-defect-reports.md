# Defect Reports - Journal Entry Creation, Editing, Deletion

All core functional requirements, integrations, validations, and security constraints for Modules 3, 4, and 5 have been implemented and verified. No critical or high-priority defects remain open.

Below is the report detailing the known architectural limitations and observations:

| Defect ID | Summary | Steps to Reproduce | Expected Result | Actual Result | Environment | Severity | Priority | Evidence / Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| **DEF-011** | Category and Tag deletion requests behave as no-ops in production mode | 1. Go to Settings Screen.<br>2. Attempt to delete a category or tag.<br>3. Refresh the page or restart the app. | The deleted category or tag is permanently removed from the user account. | The category or tag continues to exist and reappears after reloading because the backend lacks DELETE endpoints. | Production Backend (Node.js/Express) | Low | Low | Backend routes `categoryRoutes.js` and `tagRoutes.js` do not expose delete handlers. The frontend production repository wraps these calls as silent no-ops to maintain backwards-compatibility. |
