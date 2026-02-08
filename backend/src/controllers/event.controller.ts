import { Request, Response } from 'express';
import { db } from '../config/firebase';
import admin from 'firebase-admin';

const EVENTS_COLLECTION = 'events';
const USERS_COLLECTION = 'users';

export interface Event {
  id?: string;
  title: string;
  description: string;
  eventDate: string; // ISO date string
  eventTime?: string;
  location?: string;
  category: 'academic' | 'sports' | 'cultural' | 'holiday' | 'exam' | 'general';
  targetAudience: 'all' | 'students' | 'staff' | 'specific_class';
  targetClassIds?: string[]; // For specific classes
  priority: 'low' | 'medium' | 'high';
  imageUrl?: string;
  createdBy: string;
  createdByName: string;
  createdAt: Date;
  updatedAt: Date;
  isActive: boolean;
}

export class EventsController {
  // Create a new event (Staff only)
  static async createEvent(req: Request, res: Response) {
    try {
      const staffId = (req as any).user.id;
      const {
        title,
        description,
        eventDate,
        eventTime,
        location,
        category,
        targetAudience,
        targetClassIds,
        priority,
        imageUrl,
      } = req.body;

      console.log(`📅 Creating event: ${title} by staff ${staffId}`);

      // Validate input
      if (!title || !description || !eventDate || !category || !targetAudience || !priority) {
        return res.status(400).json({
          success: false,
          message: 'Title, description, date, category, target audience, and priority are required',
        });
      }

      // Get staff details
      const staffDoc = await db.collection(USERS_COLLECTION).doc(staffId).get();
      if (!staffDoc.exists) {
        return res.status(404).json({
          success: false,
          message: 'Staff not found',
        });
      }

      const staffData = staffDoc.data();
      if (staffData?.userType !== 'staff') {
        return res.status(403).json({
          success: false,
          message: 'Only staff members can create events',
        });
      }

      // Validate target audience
      if (targetAudience === 'specific_class' && (!targetClassIds || targetClassIds.length === 0)) {
        return res.status(400).json({
          success: false,
          message: 'Target class IDs are required for specific class events',
        });
      }

      // Create event object
      const event: Event = {
        title: title.trim(),
        description: description.trim(),
        eventDate,
        eventTime: eventTime || null,
        location: location?.trim() || null,
        category,
        targetAudience,
        targetClassIds: targetAudience === 'specific_class' ? targetClassIds : null,
        priority,
        imageUrl: imageUrl || null,
        createdBy: staffId,
        createdByName: staffData?.name || 'Staff',
        createdAt: new Date(),
        updatedAt: new Date(),
        isActive: true,
      };

      // Save to Firestore
      const docRef = await db.collection(EVENTS_COLLECTION).add(event);

      console.log(`✅ Event created successfully: ${docRef.id}`);

      return res.status(201).json({
        success: true,
        message: 'Event created successfully',
        data: {
          id: docRef.id,
          ...event,
        },
      });
    } catch (error: any) {
      console.error('❌ Create event error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error creating event',
        error: error.message,
      });
    }
  }

  // Get all events for students (filtered by class)
  static async getStudentEvents(req: Request, res: Response) {
    try {
      const studentId = (req as any).user.id;
      const { limit = 50 } = req.query;

      console.log(`📖 Fetching events for student ${studentId}`);

      // Get student details
      const studentDoc = await db.collection(USERS_COLLECTION).doc(studentId).get();
      if (!studentDoc.exists) {
        return res.status(404).json({
          success: false,
          message: 'Student not found',
        });
      }

      const studentData = studentDoc.data();
      const classId = studentData?.classId;

      // Get events
      const eventsSnapshot = await db
        .collection(EVENTS_COLLECTION)
        .where('isActive', '==', true)
        .orderBy('eventDate', 'desc')
        .orderBy('createdAt', 'desc')
        .limit(parseInt(limit as string))
        .get();

      const events = eventsSnapshot.docs
        .map(doc => ({
          id: doc.id,
          ...doc.data(),
        }))
        .filter((event: any) => {
          // Filter based on target audience
          if (event.targetAudience === 'all') return true;
          if (event.targetAudience === 'students') return true;
          if (event.targetAudience === 'staff') return false;
          if (event.targetAudience === 'specific_class') {
            return event.targetClassIds?.includes(classId);
          }
          return false;
        });

      return res.status(200).json({
        success: true,
        data: {
          events,
          count: events.length,
        },
      });
    } catch (error: any) {
      console.error('❌ Get student events error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error fetching events',
        error: error.message,
      });
    }
  }

  // Get all events for staff
  static async getStaffEvents(req: Request, res: Response) {
    try {
      const staffId = (req as any).user.id;
      const { limit = 50, includeInactive = false } = req.query;

      console.log(`📖 Fetching events for staff ${staffId}`);

      let query = db.collection(EVENTS_COLLECTION).orderBy('eventDate', 'desc').orderBy('createdAt', 'desc');

      if (!includeInactive) {
        query = query.where('isActive', '==', true);
      }

      const eventsSnapshot = await query.limit(parseInt(limit as string)).get();

      const events = eventsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
      }));

      return res.status(200).json({
        success: true,
        data: {
          events,
          count: events.length,
        },
      });
    } catch (error: any) {
      console.error('❌ Get staff events error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error fetching events',
        error: error.message,
      });
    }
  }

  // Get my created events (Staff only)
  static async getMyEvents(req: Request, res: Response) {
    try {
      const staffId = (req as any).user.id;
      const { limit = 50 } = req.query;

      console.log(`📖 Fetching events created by staff ${staffId}`);

      const eventsSnapshot = await db
        .collection(EVENTS_COLLECTION)
        .where('createdBy', '==', staffId)
        .orderBy('createdAt', 'desc')
        .limit(parseInt(limit as string))
        .get();

      const events = eventsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
      }));

      return res.status(200).json({
        success: true,
        data: {
          events,
          count: events.length,
        },
      });
    } catch (error: any) {
      console.error('❌ Get my events error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error fetching events',
        error: error.message,
      });
    }
  }

  // Update event (Staff only - creator or admin)
  static async updateEvent(req: Request, res: Response) {
    try {
      const staffId = (req as any).user.id;
      const { eventId } = req.params;
      const updateData = req.body;

      console.log(`✏️ Updating event ${eventId} by staff ${staffId}`);

      // Get event
      const eventDoc = await db.collection(EVENTS_COLLECTION).doc(eventId).get();
      if (!eventDoc.exists) {
        return res.status(404).json({
          success: false,
          message: 'Event not found',
        });
      }

      const eventData = eventDoc.data();

      // Check if staff is the creator
      if (eventData?.createdBy !== staffId) {
        return res.status(403).json({
          success: false,
          message: 'You can only update events you created',
        });
      }

      // Update event
      const updatedEvent = {
        ...updateData,
        updatedAt: new Date(),
      };

      // Remove fields that shouldn't be updated
      delete updatedEvent.createdBy;
      delete updatedEvent.createdByName;
      delete updatedEvent.createdAt;
      delete updatedEvent.id;

      await db.collection(EVENTS_COLLECTION).doc(eventId).update(updatedEvent);

      console.log(`✅ Event updated successfully: ${eventId}`);

      return res.status(200).json({
        success: true,
        message: 'Event updated successfully',
      });
    } catch (error: any) {
      console.error('❌ Update event error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error updating event',
        error: error.message,
      });
    }
  }

  // Delete event (soft delete - mark as inactive)
  static async deleteEvent(req: Request, res: Response) {
    try {
      const staffId = (req as any).user.id;
      const { eventId } = req.params;

      console.log(`🗑️ Deleting event ${eventId} by staff ${staffId}`);

      // Get event
      const eventDoc = await db.collection(EVENTS_COLLECTION).doc(eventId).get();
      if (!eventDoc.exists) {
        return res.status(404).json({
          success: false,
          message: 'Event not found',
        });
      }

      const eventData = eventDoc.data();

      // Check if staff is the creator
      if (eventData?.createdBy !== staffId) {
        return res.status(403).json({
          success: false,
          message: 'You can only delete events you created',
        });
      }

      // Soft delete - mark as inactive
      await db.collection(EVENTS_COLLECTION).doc(eventId).update({
        isActive: false,
        updatedAt: new Date(),
      });

      console.log(`✅ Event deleted successfully: ${eventId}`);

      return res.status(200).json({
        success: true,
        message: 'Event deleted successfully',
      });
    } catch (error: any) {
      console.error('❌ Delete event error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error deleting event',
        error: error.message,
      });
    }
  }

  // Get upcoming events (for dashboard widgets)
  static async getUpcomingEvents(req: Request, res: Response) {
    try {
      const userId = (req as any).user.id;
      const { limit = 5 } = req.query;

      console.log(`📅 Fetching upcoming events for user ${userId}`);

      // Get user details
      const userDoc = await db.collection(USERS_COLLECTION).doc(userId).get();
      if (!userDoc.exists) {
        return res.status(404).json({
          success: false,
          message: 'User not found',
        });
      }

      const userData = userDoc.data();
      const userType = userData?.userType;
      const classId = userData?.classId;

      const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD

      // Get upcoming events
      const eventsSnapshot = await db
        .collection(EVENTS_COLLECTION)
        .where('isActive', '==', true)
        .where('eventDate', '>=', today)
        .orderBy('eventDate', 'asc')
        .orderBy('createdAt', 'desc')
        .limit(parseInt(limit as string))
        .get();

      let events = eventsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
      }));

      // Filter based on user type
      if (userType === 'student') {
        events = events.filter((event: any) => {
          if (event.targetAudience === 'all') return true;
          if (event.targetAudience === 'students') return true;
          if (event.targetAudience === 'staff') return false;
          if (event.targetAudience === 'specific_class') {
            return event.targetClassIds?.includes(classId);
          }
          return false;
        });
      }

      return res.status(200).json({
        success: true,
        data: {
          events,
          count: events.length,
        },
      });
    } catch (error: any) {
      console.error('❌ Get upcoming events error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error fetching upcoming events',
        error: error.message,
      });
    }
  }
}