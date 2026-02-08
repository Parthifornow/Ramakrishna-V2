import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { db } from '../config/firebase';
import { User, UserResponse } from '../models/user.models';

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';
const USERS_COLLECTION = 'users';
const PENDING_USERS_COLLECTION = 'pending_users';

export class AuthController {
  // Store user temporarily until phone is verified
  static async preRegister(req: Request, res: Response) {
    try {
      const { phoneNumber, password, name, userType, class: className, section, rollNumber, designation, subjects } = req.body;

      // Validate input
      if (!phoneNumber || !password || !name || !userType) {
        return res.status(400).json({
          success: false,
          message: 'Phone number, password, name, and user type are required',
        });
      }

      // Validate user type
      if (!['student', 'staff'].includes(userType)) {
        return res.status(400).json({
          success: false,
          message: 'User type must be either student or staff',
        });
      }

      // Validate student-specific fields
      if (userType === 'student') {
        if (!className || !section) {
          return res.status(400).json({
            success: false,
            message: 'Class and section are required for students',
          });
        }
      }

      // Validate staff-specific fields
      if (userType === 'staff') {
        if (!designation) {
          return res.status(400).json({
            success: false,
            message: 'Designation is required for staff',
          });
        }
      }

      // Validate phone number (10 digits)
      if (!/^\d{10}$/.test(phoneNumber)) {
        return res.status(400).json({
          success: false,
          message: 'Invalid phone number format. Must be 10 digits.',
        });
      }

      // Validate password length
      if (password.length < 6) {
        return res.status(400).json({
          success: false,
          message: 'Password must be at least 6 characters',
        });
      }

      // Validate name length
      if (name.trim().length < 3) {
        return res.status(400).json({
          success: false,
          message: 'Name must be at least 3 characters',
        });
      }

      // Check if user already exists in main users collection
      const existingUserSnapshot = await db
        .collection(USERS_COLLECTION)
        .where('phoneNumber', '==', phoneNumber)
        .get();

      if (!existingUserSnapshot.empty) {
        return res.status(409).json({
          success: false,
          message: 'User with this phone number already exists',
        });
      }

      // Hash password
      const hashedPassword = await bcrypt.hash(password, 10);

      // Store in pending users
      const pendingUser: any = {
        phoneNumber,
        password: hashedPassword,
        name: name.trim(),
        userType,
        createdAt: new Date(),
        expiresAt: new Date(Date.now() + 30 * 60 * 1000), // 30 minutes
      };

      // Add student-specific fields
      if (userType === 'student') {
        pendingUser.classId = `${className}_${section}`; // e.g., "10_A"
        pendingUser.className = className;
        pendingUser.section = section;
        pendingUser.rollNumber = rollNumber || '';
      }

      // Add staff-specific fields
      if (userType === 'staff') {
        pendingUser.designation = designation;
        pendingUser.subjects = subjects || [];
        pendingUser.assignedClassIds = []; // Will be populated by admin later
      }

      // Check if already in pending
      const pendingSnapshot = await db
        .collection(PENDING_USERS_COLLECTION)
        .where('phoneNumber', '==', phoneNumber)
        .get();

      if (!pendingSnapshot.empty) {
        // Update existing pending user
        const docId = pendingSnapshot.docs[0].id;
        await db.collection(PENDING_USERS_COLLECTION).doc(docId).update(pendingUser);
      } else {
        // Create new pending user
        await db.collection(PENDING_USERS_COLLECTION).add(pendingUser);
      }

      console.log(`✅ Pre-registration successful for: ${phoneNumber} (${userType})`);

      return res.status(200).json({
        success: true,
        message: 'User data saved. Please verify your phone number.',
      });
    } catch (error: any) {
      console.error('❌ Pre-registration error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error during registration process',
        error: error.message,
      });
    }
  }

  // Complete registration after phone verification
  static async completeRegistration(req: Request, res: Response) {
    try {
      const { phoneNumber, firebaseUid } = req.body;

      console.log(`📝 Complete registration request for: ${phoneNumber}`);

      // Validate input
      if (!phoneNumber || !firebaseUid) {
        return res.status(400).json({
          success: false,
          message: 'Phone number and Firebase UID are required',
        });
      }

      // Check if user already exists
      const existingUserSnapshot = await db
        .collection(USERS_COLLECTION)
        .where('phoneNumber', '==', phoneNumber)
        .get();

      if (!existingUserSnapshot.empty) {
        return res.status(409).json({
          success: false,
          message: 'User with this phone number already exists',
        });
      }

      // Get pending user data
      const pendingSnapshot = await db
        .collection(PENDING_USERS_COLLECTION)
        .where('phoneNumber', '==', phoneNumber)
        .get();

      if (pendingSnapshot.empty) {
        return res.status(404).json({
          success: false,
          message: 'No pending registration found. Please start registration again.',
        });
      }

      const pendingDoc = pendingSnapshot.docs[0];
      const pendingData = pendingDoc.data();

      // Check if pending registration has expired
      if (pendingData.expiresAt.toDate() < new Date()) {
        await db.collection(PENDING_USERS_COLLECTION).doc(pendingDoc.id).delete();
        return res.status(410).json({
          success: false,
          message: 'Registration session expired. Please start again.',
        });
      }

      // Create final user object
      const newUser: any = {
        phoneNumber: pendingData.phoneNumber,
        password: pendingData.password,
        name: pendingData.name,
        userType: pendingData.userType,
        firebaseUid: firebaseUid,
        phoneVerified: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      // Add student-specific fields
      if (pendingData.userType === 'student') {
        newUser.classId = pendingData.classId;
        newUser.className = pendingData.className;
        newUser.section = pendingData.section;
        newUser.rollNumber = pendingData.rollNumber || '';
      }

      // Add staff-specific fields
      if (pendingData.userType === 'staff') {
        newUser.designation = pendingData.designation;
        newUser.subjects = pendingData.subjects || [];
        newUser.assignedClassIds = pendingData.assignedClassIds || [];
      }

      // Save to main users collection
      const docRef = await db.collection(USERS_COLLECTION).add(newUser);

      // Delete from pending users
      await db.collection(PENDING_USERS_COLLECTION).doc(pendingDoc.id).delete();

      // Generate JWT token
      const token = jwt.sign(
        { id: docRef.id, phoneNumber, userType: newUser.userType },
        JWT_SECRET,
        { expiresIn: '7d' }
      );

      // Prepare response (exclude password)
      const userResponse: any = {
        id: docRef.id,
        phoneNumber: newUser.phoneNumber,
        name: newUser.name,
        userType: newUser.userType,
      };

      if (newUser.userType === 'student') {
        userResponse.classId = newUser.classId;
        userResponse.className = newUser.className;
        userResponse.section = newUser.section;
        userResponse.rollNumber = newUser.rollNumber;
      }

      if (newUser.userType === 'staff') {
        userResponse.designation = newUser.designation;
        userResponse.subjects = newUser.subjects;
        userResponse.assignedClassIds = newUser.assignedClassIds;
      }

      console.log(`✅ Registration completed for: ${phoneNumber} (${newUser.userType})`);

      return res.status(201).json({
        success: true,
        message: 'Registration completed successfully',
        user: userResponse,
        token,
      });
    } catch (error: any) {
      console.error('❌ Complete registration error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error completing registration',
        error: error.message,
      });
    }
  }

  // Login user
  static async login(req: Request, res: Response) {
    try {
      const { phoneNumber, password } = req.body;

      console.log(`🔐 Login attempt for: ${phoneNumber}`);

      // Validate input
      if (!phoneNumber || !password) {
        return res.status(400).json({
          success: false,
          message: 'Phone number and password are required',
        });
      }

      // Validate phone number format
      if (!/^\d{10}$/.test(phoneNumber)) {
        return res.status(400).json({
          success: false,
          message: 'Invalid phone number format',
        });
      }

      // Find user by phone number
      const userSnapshot = await db
        .collection(USERS_COLLECTION)
        .where('phoneNumber', '==', phoneNumber)
        .limit(1)
        .get();

      if (userSnapshot.empty) {
        return res.status(401).json({
          success: false,
          message: 'Invalid phone number or password',
        });
      }

      const userDoc = userSnapshot.docs[0];
      const userData = userDoc.data() as any;
      const userId = userDoc.id;

      // Check if phone is verified
      if (!userData.phoneVerified) {
        return res.status(403).json({
          success: false,
          message: 'Phone number not verified. Please complete registration.',
        });
      }

      // Verify password
      const isPasswordValid = await bcrypt.compare(password, userData.password);

      if (!isPasswordValid) {
        return res.status(401).json({
          success: false,
          message: 'Invalid phone number or password',
        });
      }

      // Generate JWT token
      const token = jwt.sign(
        { id: userId, phoneNumber: userData.phoneNumber, userType: userData.userType },
        JWT_SECRET,
        { expiresIn: '7d' }
      );

      // Prepare response (exclude password)
      const userResponse: any = {
        id: userId,
        phoneNumber: userData.phoneNumber,
        name: userData.name,
        userType: userData.userType,
      };

      if (userData.userType === 'student') {
        userResponse.classId = userData.classId;
        userResponse.className = userData.className;
        userResponse.section = userData.section;
        userResponse.rollNumber = userData.rollNumber;
      }

      if (userData.userType === 'staff') {
        userResponse.designation = userData.designation;
        userResponse.subjects = userData.subjects;
        userResponse.assignedClassIds = userData.assignedClassIds || [];
      }

      console.log(`✅ Login successful for: ${phoneNumber} (${userData.userType})`);

      return res.status(200).json({
        success: true,
        message: 'Login successful',
        user: userResponse,
        token,
      });
    } catch (error: any) {
      console.error('❌ Login error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error during login',
        error: error.message,
      });
    }
  }

  // Reset Password
  static async resetPassword(req: Request, res: Response) {
    try {
      const { phoneNumber, newPassword } = req.body;

      console.log(`🔑 Password reset attempt for: ${phoneNumber}`);

      // Validate input
      if (!phoneNumber || !newPassword) {
        return res.status(400).json({
          success: false,
          message: 'Phone number and new password are required',
        });
      }

      // Validate phone number format
      if (!/^\d{10}$/.test(phoneNumber)) {
        return res.status(400).json({
          success: false,
          message: 'Invalid phone number format',
        });
      }

      // Validate password length
      if (newPassword.length < 6) {
        return res.status(400).json({
          success: false,
          message: 'Password must be at least 6 characters',
        });
      }

      // Find user by phone number
      const userSnapshot = await db
        .collection(USERS_COLLECTION)
        .where('phoneNumber', '==', phoneNumber)
        .limit(1)
        .get();

      if (userSnapshot.empty) {
        return res.status(404).json({
          success: false,
          message: 'User not found with this phone number',
        });
      }

      const userDoc = userSnapshot.docs[0];
      const userId = userDoc.id;

      // Hash new password
      const hashedPassword = await bcrypt.hash(newPassword, 10);

      // Update password in Firestore
      await db.collection(USERS_COLLECTION).doc(userId).update({
        password: hashedPassword,
        updatedAt: new Date(),
      });

      console.log(`✅ Password reset successful for: ${phoneNumber}`);

      return res.status(200).json({
        success: true,
        message: 'Password reset successfully',
      });
    } catch (error: any) {
      console.error('❌ Password reset error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error resetting password',
        error: error.message,
      });
    }
  }

  // Get user profile (protected route)
  static async getProfile(req: Request, res: Response) {
    try {
      const userId = (req as any).user.id;

      const userDoc = await db.collection(USERS_COLLECTION).doc(userId).get();

      if (!userDoc.exists) {
        return res.status(404).json({
          success: false,
          message: 'User not found',
        });
      }

      const userData = userDoc.data() as User;

      const userResponse: any = {
        id: userDoc.id,
        phoneNumber: userData.phoneNumber,
        name: userData.name,
        userType: userData.userType,
      };

      if (userData.userType === 'student') {
        userResponse.classId = (userData as any).classId;
        userResponse.className = (userData as any).className;
        userResponse.section = (userData as any).section;
        userResponse.rollNumber = (userData as any).rollNumber;
      }

      if (userData.userType === 'staff') {
        userResponse.designation = (userData as any).designation;
        userResponse.subjects = (userData as any).subjects;
        userResponse.assignedClassIds = (userData as any).assignedClassIds || [];
      }

      return res.status(200).json({
        success: true,
        user: userResponse,
      });
    } catch (error: any) {
      console.error('❌ Profile fetch error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error fetching profile',
        error: error.message,
      });
    }
  }
}