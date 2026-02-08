import bcrypt from 'bcryptjs';
import { db } from '../src/config/firebase';

const USERS_COLLECTION = 'users';

interface TestUser {
  phoneNumber: string;
  password: string;
  name: string;
  userType: 'student' | 'staff';
  classId?: string;
  className?: string;
  section?: string;
  rollNumber?: string;
  designation?: string;
  subjects?: string[];
  assignedClassIds?: string[];
  phoneVerified: boolean;
  firebaseUid: string;
}

async function seedTestData() {
  console.log('🌱 Starting to seed test data...');

  try {
    const hashedPassword = await bcrypt.hash('password123', 10);

    // Test Students Data
    const students: TestUser[] = [
      // Class 10-A
      {
        phoneNumber: '9876543210',
        password: hashedPassword,
        name: 'Rajesh Kumar',
        userType: 'student',
        classId: '10_A',
        className: '10',
        section: 'A',
        rollNumber: '1',
        phoneVerified: true,
        firebaseUid: 'test_student_1',
      },
      {
        phoneNumber: '9876543211',
        password: hashedPassword,
        name: 'Priya Sharma',
        userType: 'student',
        classId: '10_A',
        className: '10',
        section: 'A',
        rollNumber: '2',
        phoneVerified: true,
        firebaseUid: 'test_student_2',
      },
      {
        phoneNumber: '9876543212',
        password: hashedPassword,
        name: 'Amit Patel',
        userType: 'student',
        classId: '10_A',
        className: '10',
        section: 'A',
        rollNumber: '3',
        phoneVerified: true,
        firebaseUid: 'test_student_3',
      },
      {
        phoneNumber: '9876543213',
        password: hashedPassword,
        name: 'Sneha Reddy',
        userType: 'student',
        classId: '10_A',
        className: '10',
        section: 'A',
        rollNumber: '4',
        phoneVerified: true,
        firebaseUid: 'test_student_4',
      },
      
      // Class 10-B
      {
        phoneNumber: '9876543214',
        password: hashedPassword,
        name: 'Vikram Singh',
        userType: 'student',
        classId: '10_B',
        className: '10',
        section: 'B',
        rollNumber: '1',
        phoneVerified: true,
        firebaseUid: 'test_student_5',
      },
      {
        phoneNumber: '9876543215',
        password: hashedPassword,
        name: 'Ananya Iyer',
        userType: 'student',
        classId: '10_B',
        className: '10',
        section: 'B',
        rollNumber: '2',
        phoneVerified: true,
        firebaseUid: 'test_student_6',
      },
      {
        phoneNumber: '9876543216',
        password: hashedPassword,
        name: 'Karthik Menon',
        userType: 'student',
        classId: '10_B',
        className: '10',
        section: 'B',
        rollNumber: '3',
        phoneVerified: true,
        firebaseUid: 'test_student_7',
      },
      
      // Class 11-A
      {
        phoneNumber: '9876543217',
        password: hashedPassword,
        name: 'Divya Nair',
        userType: 'student',
        classId: '11_A',
        className: '11',
        section: 'A',
        rollNumber: '1',
        phoneVerified: true,
        firebaseUid: 'test_student_8',
      },
      {
        phoneNumber: '9876543218',
        password: hashedPassword,
        name: 'Rohan Verma',
        userType: 'student',
        classId: '11_A',
        className: '11',
        section: 'A',
        rollNumber: '2',
        phoneVerified: true,
        firebaseUid: 'test_student_9',
      },
      {
        phoneNumber: '9876543219',
        password: hashedPassword,
        name: 'Meera Joshi',
        userType: 'student',
        classId: '11_A',
        className: '11',
        section: 'A',
        rollNumber: '3',
        phoneVerified: true,
        firebaseUid: 'test_student_10',
      },

      // Class 12-A
      {
        phoneNumber: '9876543220',
        password: hashedPassword,
        name: 'Arjun Rao',
        userType: 'student',
        classId: '12_A',
        className: '12',
        section: 'A',
        rollNumber: '1',
        phoneVerified: true,
        firebaseUid: 'test_student_11',
      },
      {
        phoneNumber: '9876543221',
        password: hashedPassword,
        name: 'Kavya Pillai',
        userType: 'student',
        classId: '12_A',
        className: '12',
        section: 'A',
        rollNumber: '2',
        phoneVerified: true,
        firebaseUid: 'test_student_12',
      },
    ];

    // Test Staff Data with assigned classes
    const staff: TestUser[] = [
      {
        phoneNumber: '9988776655',
        password: hashedPassword,
        name: 'Dr. Suresh Kumar',
        userType: 'staff',
        designation: 'Senior Mathematics Teacher',
        subjects: ['Mathematics', 'Statistics'],
        assignedClassIds: ['10_A', '10_B', '11_A'], // Assigned to multiple classes
        phoneVerified: true,
        firebaseUid: 'test_staff_1',
      },
      {
        phoneNumber: '9988776656',
        password: hashedPassword,
        name: 'Mrs. Lakshmi Menon',
        userType: 'staff',
        designation: 'English Teacher',
        subjects: ['English', 'Literature'],
        assignedClassIds: ['10_A', '11_A', '12_A'],
        phoneVerified: true,
        firebaseUid: 'test_staff_2',
      },
      {
        phoneNumber: '9988776657',
        password: hashedPassword,
        name: 'Mr. Ravi Shankar',
        userType: 'staff',
        designation: 'Science Teacher',
        subjects: ['Physics', 'Chemistry'],
        assignedClassIds: ['10_A', '10_B', '12_A'],
        phoneVerified: true,
        firebaseUid: 'test_staff_3',
      },
      {
        phoneNumber: '9988776658',
        password: hashedPassword,
        name: 'Ms. Anjali Desai',
        userType: 'staff',
        designation: 'Computer Science Teacher',
        subjects: ['Computer Science', 'IT'],
        assignedClassIds: ['11_A', '12_A'],
        phoneVerified: true,
        firebaseUid: 'test_staff_4',
      },
      {
        phoneNumber: '9988776659',
        password: hashedPassword,
        name: 'Prof. Ramesh Gupta',
        userType: 'staff',
        designation: 'History Teacher',
        subjects: ['History', 'Civics'],
        assignedClassIds: ['10_A', '10_B'],
        phoneVerified: true,
        firebaseUid: 'test_staff_5',
      },
    ];

    // Insert Students
    console.log('📚 Inserting students...');
    for (const student of students) {
      const docRef = await db.collection(USERS_COLLECTION).add({
        ...student,
        createdAt: new Date(),
        updatedAt: new Date(),
      });
      console.log(`✅ Created student: ${student.name} (Class ${student.className}-${student.section})`);
    }

    // Insert Staff
    console.log('\n👨‍🏫 Inserting staff...');
    for (const staffMember of staff) {
      const docRef = await db.collection(USERS_COLLECTION).add({
        ...staffMember,
        createdAt: new Date(),
        updatedAt: new Date(),
      });
      console.log(`✅ Created staff: ${staffMember.name} - ${staffMember.designation}`);
      console.log(`   Assigned to classes: ${staffMember.assignedClassIds?.join(', ')}`);
    }

    console.log('\n✅ Test data seeded successfully!');
    console.log('\n📋 TEST CREDENTIALS:');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('\n👨‍🎓 STUDENTS (Password: password123):');
    console.log('  Class 10-A:');
    console.log('    9876543210 - Rajesh Kumar (Roll: 1)');
    console.log('    9876543211 - Priya Sharma (Roll: 2)');
    console.log('    9876543212 - Amit Patel (Roll: 3)');
    console.log('    9876543213 - Sneha Reddy (Roll: 4)');
    console.log('  Class 10-B:');
    console.log('    9876543214 - Vikram Singh (Roll: 1)');
    console.log('    9876543215 - Ananya Iyer (Roll: 2)');
    console.log('    9876543216 - Karthik Menon (Roll: 3)');
    console.log('  Class 11-A:');
    console.log('    9876543217 - Divya Nair (Roll: 1)');
    console.log('    9876543218 - Rohan Verma (Roll: 2)');
    console.log('    9876543219 - Meera Joshi (Roll: 3)');
    console.log('  Class 12-A:');
    console.log('    9876543220 - Arjun Rao (Roll: 1)');
    console.log('    9876543221 - Kavya Pillai (Roll: 2)');
    
    console.log('\n👨‍🏫 STAFF (Password: password123):');
    console.log('    9988776655 - Dr. Suresh Kumar (Math) → Classes: 10-A, 10-B, 11-A');
    console.log('    9988776656 - Mrs. Lakshmi Menon (English) → Classes: 10-A, 11-A, 12-A');
    console.log('    9988776657 - Mr. Ravi Shankar (Science) → Classes: 10-A, 10-B, 12-A');
    console.log('    9988776658 - Ms. Anjali Desai (Computer) → Classes: 11-A, 12-A');
    console.log('    9988776659 - Prof. Ramesh Gupta (History) → Classes: 10-A, 10-B');
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  } catch (error) {
    console.error('❌ Error seeding data:', error);
  }
}

// Run the seed function
seedTestData();