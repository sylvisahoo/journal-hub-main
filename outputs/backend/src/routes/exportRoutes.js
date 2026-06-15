import express from 'express';
import exportController from '../controllers/exportController.js';
import exportValidation from '../validation/exportValidation.js';
import authMiddleware from '../middleware/authMiddleware.js';

const router = express.Router();

// Apply auth middleware to all export routes
router.use(authMiddleware);

router.post(
  '/',
  exportValidation.validate(exportValidation.requestExportSchema),
  exportController.requestExport
);

router.get('/', exportController.getUserExports);

router.get('/:exportId', exportController.getExportStatus);

router.post('/:exportId/retry', exportController.retryExport);

export default router;
