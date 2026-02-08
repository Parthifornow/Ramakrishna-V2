import { Request, Response } from 'express';
import { db } from '../config/firebase';

const USERS_COLLECTION = 'users';

export class ClassController {
  // Get all unique classes
  static async getAllClasses(req: Request, res: Response) {
    try {
      const studentsSnapshot = await db
        .collection(USERS_COLLECTION)
        .where('userType', '==', 'student')
        .get();

      // Create a map to store unique class-section combinations
      const classesMap = new Map<string, any>();

      studentsSnapshot.docs.forEach(doc => {
        const data = doc.data();
        const classId = data.classId; // e.g., "10_A"
        
        // Skip if classId is undefined or null
        if (!classId) {
          console.warn(`⚠️ Student ${data.name || 'unknown'} (ID: ${doc.id}) has no classId`);
          return;
        }

        if (!classesMap.has(classId)) {
          const parts = classId.split('_');
          
          // Validate that we have both className and section
          if (parts.length !== 2) {
            console.warn(`⚠️ Invalid classId format: ${classId} for student ${data.name || 'unknown'}`);
            return;
          }

          const [className, section] = parts;

          classesMap.set(classId, {
            classId,
            className,
            section,
            fullName: `${className}-${section}`,
            studentCount: 0,
          });
        }

        const classData = classesMap.get(classId);
        if (classData) {
          classData.studentCount += 1;
        }
      });

      const classes = Array.from(classesMap.values());

      return res.status(200).json({
        success: true,
        classes,
        count: classes.length,
      });
    } catch (error: any) {
      console.error('❌ Get all classes error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error fetching classes',
        error: error.message,
      });
    }
  }

  // Get all students in a specific class
  static async getClassStudents(req: Request, res: Response) {
    try {
      const { classId } = req.params;

      if (!classId) {
        return res.status(400).json({
          success: false,
          message: 'Class ID is required',
        });
      }

      const studentsSnapshot = await db
        .collection(USERS_COLLECTION)
        .where('userType', '==', 'student')
        .where('classId', '==', classId)
        .get();

      const students = studentsSnapshot.docs.map(doc => ({
        id: doc.id,
        name: doc.data().name,
        phoneNumber: doc.data().phoneNumber,
        rollNumber: doc.data().rollNumber || '',
        className: doc.data().className,
        section: doc.data().section,
        classId: doc.data().classId,
      }));

      const parts = classId.split('_');
      if (parts.length !== 2) {
        return res.status(400).json({
          success: false,
          message: 'Invalid class ID format',
        });
      }

      const [className, section] = parts;

      return res.status(200).json({
        success: true,
        data: {
          classId,
          className,
          section,
          fullName: `${className}-${section}`,
          students,
          count: students.length,
        },
      });
    } catch (error: any) {
      console.error('❌ Get class students error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error fetching students',
        error: error.message,
      });
    }
  }

  // Get all students (for staff/admin)
  static async getAllStudents(req: Request, res: Response) {
    try {
      const studentsSnapshot = await db
        .collection(USERS_COLLECTION)
        .where('userType', '==', 'student')
        .get();

      const students = studentsSnapshot.docs.map(doc => {
        const data = doc.data();
        return {
          id: doc.id,
          name: data.name,
          phoneNumber: data.phoneNumber,
          rollNumber: data.rollNumber || '',
          className: data.className || '',
          section: data.section || '',
          classId: data.classId || '',
        };
      });

      return res.status(200).json({
        success: true,
        students,
        count: students.length,
      });
    } catch (error: any) {
      console.error('❌ Get all students error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error fetching students',
        error: error.message,
      });
    }
  }
}