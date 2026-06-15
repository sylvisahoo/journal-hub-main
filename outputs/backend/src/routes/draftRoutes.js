import express from 'express';
import draftController from '../controllers/draftController.js';
import { authMiddleware } from '../middleware/authMiddleware.js';
import { saveDraftSchema, validate } from '../validation/draftValidation.js';

const router = express.Router();

// All draft routes are protected
router.use(authMiddleware);

// Save/Autosave Draft Endpoint
router.post('/', validate(saveDraftSchema), draftController.saveDraft);

// Retrieve Draft Endpoint
router.get('/:draftId', draftController.getDraft);

export default router;
