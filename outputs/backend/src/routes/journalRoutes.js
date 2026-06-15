import express from 'express';
import journalController from '../controllers/journalController.js';
import shareController from '../controllers/shareController.js';
import journalValidation from '../validation/journalValidation.js';
import authMiddleware from '../middleware/authMiddleware.js';


const router = express.Router();

// Apply auth middleware to all journal routes
router.use(authMiddleware);

router.post(
  '/',
  journalValidation.validate(journalValidation.createJournalSchema),
  journalController.createJournal
);

router.get(
  '/',
  journalValidation.validateQuery(journalValidation.listJournalsQuerySchema),
  journalController.listJournals
);


router.get('/:journalId', journalController.getJournal);

router.put(
  '/:journalId',
  journalValidation.validate(journalValidation.updateJournalSchema),
  journalController.updateJournal
);

router.delete('/:journalId', journalController.deleteJournal);

// Sharing endpoints
router.post('/:journalId/share', shareController.generateShareLink);
router.delete('/:journalId/share', shareController.revokeShareLink);

export default router;
