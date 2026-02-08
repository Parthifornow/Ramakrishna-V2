import { db } from '../backend/src/config/firebase';

const USERS_COLLECTION = 'users';

async function cleanupInvalidStudents() {
  console.log('🧹 Starting database cleanup...\n');
  
  try {
    // Get all students
    const studentsSnapshot = await db
      .collection(USERS_COLLECTION)
      .where('userType', '==', 'student')
      .get();

    console.log(`📊 Found ${studentsSnapshot.docs.length} students in database\n`);

    let invalidCount = 0;
    let fixedCount = 0;
    const invalidStudents: any[] = [];

    // Check each student
    for (const doc of studentsSnapshot.docs) {
      const data = doc.data();
      const studentId = doc.id;

      // Check if classId is missing or invalid
      if (!data.classId || typeof data.classId !== 'string') {
        invalidCount++;
        invalidStudents.push({
          id: studentId,
          name: data.name,
          className: data.className,
          section: data.section,
          classId: data.classId,
        });

        console.log(`❌ Invalid student found:`);
        console.log(`   ID: ${studentId}`);
        console.log(`   Name: ${data.name}`);
        console.log(`   ClassId: ${data.classId || 'MISSING'}`);
        console.log(`   ClassName: ${data.className || 'MISSING'}`);
        console.log(`   Section: ${data.section || 'MISSING'}`);

        // Try to fix if className and section exist
        if (data.className && data.section) {
          const newClassId = `${data.className}_${data.section}`;
          
          await db.collection(USERS_COLLECTION).doc(studentId).update({
            classId: newClassId,
            updatedAt: new Date(),
          });

          fixedCount++;
          console.log(`   ✅ Fixed! New classId: ${newClassId}\n`);
        } else {
          console.log(`   ⚠️ Cannot auto-fix - missing className or section\n`);
        }
      }

      // Check if classId format is invalid
      if (data.classId && !data.classId.includes('_')) {
        console.log(`⚠️ Warning: Student ${data.name} has invalid classId format: ${data.classId}`);
      }
    }

    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('📋 CLEANUP SUMMARY:');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`Total students: ${studentsSnapshot.docs.length}`);
    console.log(`Invalid students found: ${invalidCount}`);
    console.log(`Students fixed: ${fixedCount}`);
    console.log(`Students still need manual fix: ${invalidCount - fixedCount}`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    if (invalidCount === 0) {
      console.log('✅ Database is clean! No invalid students found.');
    } else if (fixedCount === invalidCount) {
      console.log('✅ All invalid students have been fixed!');
    } else {
      console.log('⚠️ Some students still need manual intervention.');
      console.log('\nStudents that need manual fixing:');
      invalidStudents
        .filter((s, i) => i >= fixedCount)
        .forEach(s => {
          console.log(`  - ${s.name} (ID: ${s.id})`);
        });
    }

  } catch (error) {
    console.error('❌ Error during cleanup:', error);
  }
}

// Run the cleanup
cleanupInvalidStudents();