export interface StaffAssignment {
  id?: string;
  staffId: string;
  staffName?: string;
  className: string;
  section: string;
  subject: string;
  academicYear: string;
  createdAt?: Date;
  updatedAt?: Date;
}

export interface StaffAssignmentResponse {
  id: string;
  staffId: string;
  staffName: string;
  className: string;
  section: string;
  subject: string;
  academicYear: string;
}

export interface AssignStaffRequest {
  staffId: string;
  className: string;
  section: string;
  subject: string;
  academicYear?: string;
}