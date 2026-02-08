export interface User {
  id?: string;
  phoneNumber: string;
  name: string;
  password: string;
  userType: 'student' | 'staff';
  
  // For students
  class?: string;
  section?: string;
  rollNumber?: string;
  
  // For staff
  designation?: string;
  subjects?: string[];
  
  firebaseUid?: string;
  phoneVerified?: boolean;
  createdAt?: Date;
  updatedAt?: Date;
}

export interface PendingUser {
  phoneNumber: string;
  name: string;
  password: string;
  userType: 'student' | 'staff';
  class?: string;
  section?: string;
  rollNumber?: string;
  designation?: string;
  subjects?: string[];
  createdAt: Date;
  expiresAt: Date;
}

export interface UserResponse {
  id: string;
  phoneNumber: string;
  name: string;
  userType: string;
  class?: string;
  section?: string;
  rollNumber?: string;
  designation?: string;
  subjects?: string[];
}

export interface LoginRequest {
  phoneNumber: string;
  password: string;
}

export interface PreRegisterRequest {
  phoneNumber: string;
  password: string;
  name: string;
  userType: 'student' | 'staff';
  class?: string;
  section?: string;
  rollNumber?: string;
  designation?: string;
  subjects?: string[];
}

export interface CompleteRegistrationRequest {
  phoneNumber: string;
  firebaseUid: string;
}