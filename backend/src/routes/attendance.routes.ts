import express from 'express';
import { AttendanceController } from '../controllers/attendance.controller';
import { authMiddleware } from '../middleware/auth.middleware';

const router = express.Router();

// Mark attendance (protected - staff only)
router.post('/mark', authMiddleware, AttendanceController.markAttendance);

// Get attendance for a specific class and date (with optional subject/period filters)
router.get('/class/:classId/date/:date', authMiddleware, AttendanceController.getClassAttendance);

// Get attendance history for a class
router.get('/class/:classId/history', authMiddleware, AttendanceController.getClassAttendanceHistory);

// Get student's subject-wise attendance record
router.get('/student/:studentId', authMiddleware, AttendanceController.getStudentAttendance);

// Get staff's attendance summary (their subjects across classes)
router.get('/staff/summary', authMiddleware, AttendanceController.getStaffAttendanceSummary);

export default router;