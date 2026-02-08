import express from 'express';
import { StaffController } from '../controllers/staff.controller';
import { authMiddleware } from '../middleware/auth.middleware';

const router = express.Router();

// Public routes for staff management (web dashboard - admin panel)
router.get('/all', StaffController.getAllStaff);
router.post('/assign-classes', StaffController.assignStaffToClasses);
router.post('/add-class', StaffController.addClassToStaff);
router.post('/remove-class', StaffController.removeClassFromStaff);
router.get('/assigned-classes/:staffId', StaffController.getStaffAssignedClasses);
router.get('/class/:classId/staff', StaffController.getClassStaff);

// Protected routes (require authentication - for mobile app)
router.get('/my-students', authMiddleware, StaffController.getMyStudents);
router.get('/my-class/:classId/students', authMiddleware, StaffController.getClassStudents);

export default router;