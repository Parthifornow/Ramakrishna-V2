export interface Class {
  id?: string;
  className: string;
  section: string;
  academicYear: string;
  createdAt?: Date;
  updatedAt?: Date;
}

export interface ClassResponse {
  id: string;
  className: string;
  section: string;
  academicYear: string;
  studentCount?: number;
  staffCount?: number;
}