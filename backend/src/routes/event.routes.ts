import express from 'express';
import { EventsController } from '../controllers/event.controller';
import { authMiddleware } from '../middleware/auth.middleware';

const router = express.Router();

// All routes require authentication
router.use(authMiddleware);

// Create event (Staff only)
router.post('/create', EventsController.createEvent);

// Get events
router.get('/student/all', EventsController.getStudentEvents);
router.get('/staff/all', EventsController.getStaffEvents);
router.get('/my-events', EventsController.getMyEvents);
router.get('/upcoming', EventsController.getUpcomingEvents);

// Update/Delete event (Staff only - creator)
router.put('/:eventId', EventsController.updateEvent);
router.delete('/:eventId', EventsController.deleteEvent);

export default router;