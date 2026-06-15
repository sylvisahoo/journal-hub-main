import express from 'express';
import calendarController from '../controllers/calendarController.js';
import calendarValidation from '../validation/calendarValidation.js';
import authMiddleware from '../middleware/authMiddleware.js';

const router = express.Router();

// Apply auth middleware to all calendar routes
router.use(authMiddleware);

router.get(
  '/',
  calendarValidation.validateQuery(calendarValidation.getCalendarSchema),
  calendarController.getCalendar
);

export default router;
