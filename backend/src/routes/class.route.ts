import express from 'express';
import { ClassController } from '../controllers/class.controller';

const router = express.Router();

// Public routes - no auth required for admin panel
router.get('/all', ClassController.getAllClasses);
router.get('/:className/:section/students', ClassController.getClassStudents);
router.get('/students/all', ClassController.getAllStudents);

export default router;