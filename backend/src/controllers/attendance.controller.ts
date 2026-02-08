import { Request, Response } from 'express';
import { db } from '../config/firebase';

const USERS_COLLECTION = 'users';
const ATTENDANCE_COLLECTION = 'attendance';

export class AttendanceController {
  // Mark attendance for a class with subject
  static async markAttendance(req: Request, res: Response) {
    try {
      const { classId, date, subject, period, attendance, markedBy, staffName } = req.body;

      console.log(`📝 Marking attendance for class ${classId} - ${subject} on ${date}`);

      // Validate input
      if (!classId || !date || !subject || !attendance || !markedBy) {
        return res.status(400).json({
          success: false,
          message: 'Class ID, date, subject, attendance data, and markedBy are required',
        });
      }

      if (!Array.isArray(attendance)) {
        return res.status(400).json({
          success: false,
          message: 'Attendance must be an array',
        });
      }

      // Create attendance record ID (classId_subject_date_period)
      const attendanceId = period 
        ? `${classId}_${subject}_${date}_${period}`
        : `${classId}_${subject}_${date}`;

      // Check if attendance already exists
      const existingDoc = await db.collection(ATTENDANCE_COLLECTION).doc(attendanceId).get();

      const attendanceRecord = {
        classId,
        date,
        subject,
        period: period || null,
        attendance, // Array of {studentId, name, rollNumber, status}
        markedBy,
        staffName: staffName || '',
        markedAt: new Date(),
        updatedAt: new Date(),
      };

      if (existingDoc.exists) {
        await db.collection(ATTENDANCE_COLLECTION).doc(attendanceId).update({
          attendance,
          updatedAt: new Date(),
        });
        console.log(`✅ Updated attendance for ${classId} - ${subject} on ${date}`);
      } else {
        await db.collection(ATTENDANCE_COLLECTION).doc(attendanceId).set(attendanceRecord);
        console.log(`✅ Created attendance for ${classId} - ${subject} on ${date}`);
      }

      return res.status(200).json({
        success: true,
        message: 'Attendance marked successfully',
        data: {
          attendanceId,
          classId,
          date,
          subject,
          period,
          totalStudents: attendance.length,
          present: attendance.filter((a: any) => a.status === 'present').length,
          absent: attendance.filter((a: any) => a.status === 'absent').length,
        },
      });
    } catch (error: any) {
      console.error('❌ Mark attendance error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error marking attendance',
        error: error.message,
      });
    }
  }

  // Get attendance for a specific class, subject and date
  static async getClassAttendance(req: Request, res: Response) {
    try {
      const { classId, date } = req.params;
      const { subject, period } = req.query;

      console.log(`📖 Fetching attendance for class ${classId} on ${date}`);

      let attendanceId: string;
      if (subject && period) {
        attendanceId = `${classId}_${subject}_${date}_${period}`;
      } else if (subject) {
        attendanceId = `${classId}_${subject}_${date}`;
      } else {
        // Get all subjects for this class and date
        const snapshot = await db.collection(ATTENDANCE_COLLECTION)
          .where('classId', '==', classId)
          .where('date', '==', date)
          .get();

        const allRecords = snapshot.docs.map(doc => ({
          attendanceId: doc.id,
          ...doc.data(),
        }));

        return res.status(200).json({
          success: true,
          data: allRecords,
        });
      }

      const attendanceDoc = await db.collection(ATTENDANCE_COLLECTION).doc(attendanceId).get();

      if (!attendanceDoc.exists) {
        return res.status(200).json({
          success: true,
          data: null,
          message: 'No attendance record found',
        });
      }

      const data = attendanceDoc.data();

      return res.status(200).json({
        success: true,
        data: {
          attendanceId,
          ...data,
        },
      });
    } catch (error: any) {
      console.error('❌ Get class attendance error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error fetching attendance',
        error: error.message,
      });
    }
  }

  // Get student's subject-wise attendance
  static async getStudentAttendance(req: Request, res: Response) {
    try {
      const { studentId } = req.params;
      const { limit = 60 } = req.query;

      console.log(`👨‍🎓 Fetching attendance for student ${studentId}`);

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

      if (!classId) {
        return res.status(400).json({
          success: false,
          message: 'Student has no class assigned',
        });
      }

      // Fetch all attendance records for the student's class
      const snapshot = await db.collection(ATTENDANCE_COLLECTION)
        .where('classId', '==', classId)
        .limit(parseInt(limit as string))
        .get();

      // Group by subject
      const subjectWiseAttendance: Record<string, any> = {};
      const allRecords: any[] = [];

      snapshot.docs.forEach(doc => {
        const data = doc.data();
        const studentAttendance = data.attendance?.find((a: any) => a.studentId === studentId);

        if (studentAttendance) {
          const subject = data.subject || 'General';
          
          // Initialize subject if not exists
          if (!subjectWiseAttendance[subject]) {
            subjectWiseAttendance[subject] = {
              subject,
              totalDays: 0,
              presentDays: 0,
              absentDays: 0,
              attendancePercentage: 0,
              records: [],
            };
          }

          // Update subject stats
          subjectWiseAttendance[subject].totalDays++;
          if (studentAttendance.status === 'present') {
            subjectWiseAttendance[subject].presentDays++;
          } else if (studentAttendance.status === 'absent') {
            subjectWiseAttendance[subject].absentDays++;
          }

          // Add record
          subjectWiseAttendance[subject].records.push({
            date: data.date,
            period: data.period,
            status: studentAttendance.status,
            markedAt: data.markedAt,
            staffName: data.staffName,
          });

          allRecords.push({
            date: data.date,
            subject: data.subject,
            period: data.period,
            status: studentAttendance.status,
            staffName: data.staffName,
            markedAt: data.markedAt,
          });
        }
      });

      // Calculate percentages
      Object.values(subjectWiseAttendance).forEach((subject: any) => {
        subject.attendancePercentage = subject.totalDays > 0 
          ? parseFloat(((subject.presentDays / subject.totalDays) * 100).toFixed(2))
          : 0;
        
        // Sort records by date descending
        subject.records.sort((a: any, b: any) => b.date.localeCompare(a.date));
      });

      // Calculate overall statistics
      const totalDays = allRecords.length;
      const presentDays = allRecords.filter(r => r.status === 'present').length;
      const absentDays = allRecords.filter(r => r.status === 'absent').length;
      const overallPercentage = totalDays > 0 
        ? parseFloat(((presentDays / totalDays) * 100).toFixed(2))
        : 0;

      // Sort all records by date
      allRecords.sort((a, b) => {
        const dateCompare = b.date.localeCompare(a.date);
        if (dateCompare !== 0) return dateCompare;
        return (b.period || '').localeCompare(a.period || '');
      });

      return res.status(200).json({
        success: true,
        data: {
          studentId,
          studentName: studentData?.name,
          classId,
          className: studentData?.className,
          section: studentData?.section,
          rollNumber: studentData?.rollNumber,
          overallStatistics: {
            totalDays,
            presentDays,
            absentDays,
            attendancePercentage: overallPercentage,
          },
          subjectWise: Object.values(subjectWiseAttendance),
          allRecords: allRecords.slice(0, 20), // Last 20 records
        },
      });
    } catch (error: any) {
      console.error('❌ Get student attendance error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error fetching student attendance',
        error: error.message,
      });
    }
  }

  // Get attendance history for a class
  static async getClassAttendanceHistory(req: Request, res: Response) {
    try {
      const { classId } = req.params;
      const { limit = 30, subject } = req.query;

      console.log(`📚 Fetching attendance history for class ${classId}`);

      let query = db.collection(ATTENDANCE_COLLECTION)
        .where('classId', '==', classId)
        .limit(parseInt(limit as string));

      if (subject) {
        query = query.where('subject', '==', subject);
      }

      const snapshot = await query.get();

      const history = snapshot.docs.map(doc => {
        const data = doc.data();
        return {
          attendanceId: doc.id,
          classId: data.classId,
          date: data.date,
          subject: data.subject,
          period: data.period,
          totalStudents: data.attendance?.length || 0,
          present: data.attendance?.filter((a: any) => a.status === 'present').length || 0,
          absent: data.attendance?.filter((a: any) => a.status === 'absent').length || 0,
          markedBy: data.markedBy,
          staffName: data.staffName,
          markedAt: data.markedAt,
        };
      });

      // Sort by date and period
      history.sort((a, b) => {
        const dateCompare = b.date.localeCompare(a.date);
        if (dateCompare !== 0) return dateCompare;
        return (b.period || '').localeCompare(a.period || '');
      });

      return res.status(200).json({
        success: true,
        data: {
          classId,
          history,
          count: history.length,
        },
      });
    } catch (error: any) {
      console.error('❌ Get class attendance history error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error fetching attendance history',
        error: error.message,
      });
    }
  }

  // Get attendance summary for staff (their subjects)
  static async getStaffAttendanceSummary(req: Request, res: Response) {
    try {
      const staffId = (req as any).user.id;

      console.log(`📊 Fetching attendance summary for staff ${staffId}`);

      // Get staff details
      const staffDoc = await db.collection(USERS_COLLECTION).doc(staffId).get();
      
      if (!staffDoc.exists) {
        return res.status(404).json({
          success: false,
          message: 'Staff not found',
        });
      }

      const staffData = staffDoc.data();
      const assignedClassIds = staffData?.assignedClassIds || [];
      const subjects = staffData?.subjects || [];

      if (assignedClassIds.length === 0) {
        return res.status(200).json({
          success: true,
          data: {
            summary: [],
            message: 'No classes assigned',
          },
        });
      }

      // Get attendance records for all assigned classes
      const summary: any[] = [];

      for (const classId of assignedClassIds) {
        for (const subject of subjects) {
          const snapshot = await db.collection(ATTENDANCE_COLLECTION)
            .where('classId', '==', classId)
            .where('subject', '==', subject)
            .where('markedBy', '==', staffId)
            .get();

          if (snapshot.size > 0) {
            const totalSessions = snapshot.size;
            let totalPresent = 0;
            let totalAbsent = 0;

            snapshot.docs.forEach(doc => {
              const data = doc.data();
              totalPresent += data.attendance?.filter((a: any) => a.status === 'present').length || 0;
              totalAbsent += data.attendance?.filter((a: any) => a.status === 'absent').length || 0;
            });

            const [className, section] = classId.split('_');
            
            summary.push({
              classId,
              className,
              section,
              subject,
              totalSessions,
              totalPresent,
              totalAbsent,
              averageAttendance: totalPresent + totalAbsent > 0
                ? parseFloat(((totalPresent / (totalPresent + totalAbsent)) * 100).toFixed(2))
                : 0,
            });
          }
        }
      }

      return res.status(200).json({
        success: true,
        data: {
          staffId,
          staffName: staffData?.name,
          summary,
        },
      });
    } catch (error: any) {
      console.error('❌ Get staff attendance summary error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error fetching attendance summary',
        error: error.message,
      });
    }
  }
}