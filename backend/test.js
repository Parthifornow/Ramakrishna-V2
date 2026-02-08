// Test script to verify the getStaffAssignedClasses endpoint
// Run this with: node test-staff-api.js

const fetch = require('node-fetch');

const API_BASE_URL = 'http://10.187.61.124:3000/api';

// Replace this with the actual staff ID from Firebase
const STAFF_ID = 'GNLEEZdF4P4SjiJWjKB7'; // The "Teach" user ID from your screenshot

async function testStaffAssignedClasses() {
  console.log('🧪 Testing Staff Assigned Classes Endpoint\n');
  console.log(`📍 URL: ${API_BASE_URL}/staff/assigned-classes/${STAFF_ID}\n`);

  try {
    const response = await fetch(`${API_BASE_URL}/staff/assigned-classes/${STAFF_ID}`);
    const data = await response.json();

    console.log('📊 Response Status:', response.status);
    console.log('📦 Response Data:');
    console.log(JSON.stringify(data, null, 2));

    if (data.success) {
      console.log('\n✅ SUCCESS!');
      console.log(`   Staff: ${data.data.staffName}`);
      console.log(`   Classes: ${data.data.assignedClasses.length}`);
      
      if (data.data.assignedClasses.length > 0) {
        console.log('\n   Assigned Classes:');
        data.data.assignedClasses.forEach((cls, index) => {
          console.log(`   ${index + 1}. ${cls.fullName} (${cls.classId})`);
        });
      }
    } else {
      console.log('\n❌ FAILED!');
      console.log(`   Message: ${data.message}`);
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

testStaffAssignedClasses();