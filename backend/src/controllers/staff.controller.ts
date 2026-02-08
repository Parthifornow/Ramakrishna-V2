import { Request, Response } from 'express';
import { db } from '../config/firebase';

const USERS_COLLECTION = 'users';

export class StaffController {
  // Assign staff to classes
  static async assignStaffToClasses(req: Request, res: Response) {
    try {
      const { staffId, classIds } = req.body;

      // Validate input
      if (!staffId || !classIds || !Array.isArray(classIds)) {
        return res.status(400).json({
          success: false,
          message: 'Staff ID and class IDs array are required',
        });
      }

      // Check if staff exists
      const staffDoc = await db.collection(USERS_COLLECTION).doc(staffId).get();
      if (!staffDoc.exists) {
        return res.status(404).json({
          success: false,
          message: 'Staff not found',
        });
      }

      const staffData = staffDoc.data();
      if (staffData?.userType !== 'staff') {
        return res.status(400).json({
          success: false,
          message: 'User is not a staff member',
        });
      }

      // Update staff's assigned classes
      await db.collection(USERS_COLLECTION).doc(staffId).update({
        assignedClassIds: classIds,
        updatedAt: new Date(),
      });

      console.log(`✅ Staff ${staffData?.name} assigned to classes: ${classIds.join(', ')}`);

      return res.status(200).json({
        success: true,
        message: 'Staff assigned to classes successfully',
        data: {
          staffId,
          staffName: staffData?.name,
          assignedClassIds: classIds,
        },
      });
    } catch (error: any) {
      console.error('❌ Staff assignment error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error assigning staff to classes',
        error: error.message,
      });
    }
  }

  // Add a single class to staff's assigned classes
  static async addClassToStaff(req: Request, res: Response) {
    try {
      const { staffId, classId } = req.body;

      // Validate input
      if (!staffId || !classId) {
        return res.status(400).json({
          success: false,
          message: 'Staff ID and class ID are required',
        });
      }

      // Check if staff exists
      const staffDoc = await db.collection(USERS_COLLECTION).doc(staffId).get();
      if (!staffDoc.exists) {
        return res.status(404).json({
          success: false,
          message: 'Staff not found',
        });
      }

      const staffData = staffDoc.data();
      if (staffData?.userType !== 'staff') {
        return res.status(400).json({
          success: false,
          message: 'User is not a staff member',
        });
      }

      // Get current assigned classes
      const currentClassIds = staffData?.assignedClassIds || [];

      // Check if class is already assigned
      if (currentClassIds.includes(classId)) {
        return res.status(409).json({
          success: false,
          message: 'Staff is already assigned to this class',
        });
      }

      // Add new class
      const updatedClassIds = [...currentClassIds, classId];

      await db.collection(USERS_COLLECTION).doc(staffId).update({
        assignedClassIds: updatedClassIds,
        updatedAt: new Date(),
      });

      console.log(`✅ Added class ${classId} to staff ${staffData?.name}`);

      return res.status(200).json({
        success: true,
        message: 'Class added to staff successfully',
        data: {
          staffId,
          staffName: staffData?.name,
          assignedClassIds: updatedClassIds,
        },
      });
    } catch (error: any) {
      console.error('❌ Add class to staff error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error adding class to staff',
        error: error.message,
      });
    }
  }

  // Remove a class from staff's assigned classes
  static async removeClassFromStaff(req: Request, res: Response) {
    try {
      const { staffId, classId } = req.body;

      // Validate input
      if (!staffId || !classId) {
        return res.status(400).json({
          success: false,
          message: 'Staff ID and class ID are required',
        });
      }

      // Check if staff exists
      const staffDoc = await db.collection(USERS_COLLECTION).doc(staffId).get();
      if (!staffDoc.exists) {
        return res.status(404).json({
          success: false,
          message: 'Staff not found',
        });
      }

      const staffData = staffDoc.data();
      if (staffData?.userType !== 'staff') {
        return res.status(400).json({
          success: false,
          message: 'User is not a staff member',
        });
      }

      // Get current assigned classes
      const currentClassIds = staffData?.assignedClassIds || [];

      // Remove the class
      const updatedClassIds = currentClassIds.filter((id: string) => id !== classId);

      await db.collection(USERS_COLLECTION).doc(staffId).update({
        assignedClassIds: updatedClassIds,
        updatedAt: new Date(),
      });

      console.log(`✅ Removed class ${classId} from staff ${staffData?.name}`);

      return res.status(200).json({
        success: true,
        message: 'Class removed from staff successfully',
        data: {
          staffId,
          staffName: staffData?.name,
          assignedClassIds: updatedClassIds,
        },
      });
    } catch (error: any) {
      console.error('❌ Remove class from staff error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error removing class from staff',
        error: error.message,
      });
    }
  }

  // Get staff's assigned classes with details
  static async getStaffAssignedClasses(req: Request, res: Response) {
    try {
      const { staffId } = req.params;

      console.log(`📞 getStaffAssignedClasses called for staffId: ${staffId}`);

      // Get staff data
      const staffDoc = await db.collection(USERS_COLLECTION).doc(staffId).get();
      if (!staffDoc.exists) {
        console.log(`❌ Staff not found: ${staffId}`);
        return res.status(404).json({
          success: false,
          message: 'Staff not found',
        });
      }

      const staffData = staffDoc.data();
      const assignedClassIds = staffData?.assignedClassIds || [];

      console.log(`📚 Staff ${staffData?.name} has assignedClassIds:`, assignedClassIds);

      // Get class details
      const classDetails = assignedClassIds.map((classId: string) => {
        // Split classId (e.g., "8_C" or "10_A")
        const parts = classId.split('_');
        if (parts.length !== 2) {
          console.warn(`⚠️ Invalid classId format: ${classId}`);
          return null;
        }

        const [className, section] = parts;
        const classDetail = {
          classId,
          className,
          section,
          fullName: `${className}-${section}`,
        };
        
        console.log(`  - Class detail created:`, classDetail);
        return classDetail;
      }).filter(Boolean); // Remove null entries

      console.log(`✅ Returning response with ${classDetails.length} classes`);

      const response = {
        success: true,
        data: {
          staffId,
          staffName: staffData?.name,
          assignedClasses: classDetails,
        },
      };

      console.log(`📤 Full response:`, JSON.stringify(response, null, 2));

      return res.status(200).json(response);
    } catch (error: any) {
      console.error('❌ Get staff assigned classes error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error fetching staff assigned classes',
        error: error.message,
      });
    }
  }

  // Get all students from staff's assigned classes
  static async getMyStudents(req: Request, res: Response) {
    try {
      const staffId = (req as any).user.id;

      // Get staff data
      const staffDoc = await db.collection(USERS_COLLECTION).doc(staffId).get();
      if (!staffDoc.exists) {
        return res.status(404).json({
          success: false,
          message: 'Staff not found',
        });
      }

      const staffData = staffDoc.data();
      const assignedClassIds = staffData?.assignedClassIds || [];

      if (assignedClassIds.length === 0) {
        return res.status(200).json({
          success: true,
          data: {
            students: [],
          },
          message: 'No class assignments found',
        });
      }

      // Firestore 'in' query supports max 10 items
      const batchSize = 10;
      const batches = [];
      
      for (let i = 0; i < assignedClassIds.length; i += batchSize) {
        const batch = assignedClassIds.slice(i, i + batchSize);
        batches.push(batch);
      }

      let allStudents: any[] = [];

      for (const batch of batches) {
        const studentsSnapshot = await db
          .collection(USERS_COLLECTION)
          .where('userType', '==', 'student')
          .where('classId', 'in', batch)
          .get();

        const batchStudents = studentsSnapshot.docs.map(doc => ({
          id: doc.id,
          name: doc.data().name,
          phoneNumber: doc.data().phoneNumber,
          className: doc.data().className,
          section: doc.data().section,
          rollNumber: doc.data().rollNumber,
          classId: doc.data().classId,
        }));

        allStudents = [...allStudents, ...batchStudents];
      }

      return res.status(200).json({
        success: true,
        data: {
          students: allStudents,
        },
        count: allStudents.length,
      });
    } catch (error: any) {
      console.error('❌ Get my students error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error fetching students',
        error: error.message,
      });
    }
  }

  // Get students from a specific class
  static async getClassStudents(req: Request, res: Response) {
    try {
      const { classId } = req.params;
      const staffId = (req as any).user.id;

      // Verify staff has access to this class
      const staffDoc = await db.collection(USERS_COLLECTION).doc(staffId).get();
      if (!staffDoc.exists) {
        return res.status(404).json({
          success: false,
          message: 'Staff not found',
        });
      }

      const staffData = staffDoc.data();
      const assignedClassIds = staffData?.assignedClassIds || [];

      if (!assignedClassIds.includes(classId)) {
        return res.status(403).json({
          success: false,
          message: 'You do not have access to this class',
        });
      }

      // Fetch students from this class
      const studentsSnapshot = await db
        .collection(USERS_COLLECTION)
        .where('userType', '==', 'student')
        .where('classId', '==', classId)
        .get();

      const students = studentsSnapshot.docs.map(doc => ({
        id: doc.id,
        name: doc.data().name,
        phoneNumber: doc.data().phoneNumber,
        className: doc.data().className,
        section: doc.data().section,
        rollNumber: doc.data().rollNumber,
        classId: doc.data().classId,
      }));

      const parts = classId.split('_');
      const [className, section] = parts.length === 2 ? parts : ['', ''];

      return res.status(200).json({
        success: true,
        data: {
          classId,
          className,
          section,
          students,
          count: students.length,
        },
      });
    } catch (error: any) {
      console.error('❌ Get class students error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error fetching class students',
        error: error.message,
      });
    }
  }

  // Get all staff members
  static async getAllStaff(req: Request, res: Response) {
    try {
      const staffSnapshot = await db
        .collection(USERS_COLLECTION)
        .where('userType', '==', 'staff')
        .get();

      const staff = staffSnapshot.docs.map(doc => ({
        id: doc.id,
        name: doc.data().name,
        phoneNumber: doc.data().phoneNumber,
        designation: doc.data().designation,
        subjects: doc.data().subjects || [],
        assignedClassIds: doc.data().assignedClassIds || [],
      }));

      return res.status(200).json({
        success: true,
        staff,
        count: staff.length,
      });
    } catch (error: any) {
      console.error('❌ Get all staff error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error fetching staff',
        error: error.message,
      });
    }
  }

  // Get staff members assigned to a specific class
  static async getClassStaff(req: Request, res: Response) {
    try {
      const { classId } = req.params;

      const staffSnapshot = await db
        .collection(USERS_COLLECTION)
        .where('userType', '==', 'staff')
        .where('assignedClassIds', 'array-contains', classId)
        .get();

      const staff = staffSnapshot.docs.map(doc => ({
        id: doc.id,
        name: doc.data().name,
        phoneNumber: doc.data().phoneNumber,
        designation: doc.data().designation,
        subjects: doc.data().subjects || [],
      }));

      const parts = classId.split('_');
      const [className, section] = parts.length === 2 ? parts : ['', ''];

      return res.status(200).json({
        success: true,
        data: {
          classId,
          className,
          section,
          staff,
          count: staff.length,
        },
      });
    } catch (error: any) {
      console.error('❌ Get class staff error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error fetching class staff',
        error: error.message,
      });
    }
  }
}