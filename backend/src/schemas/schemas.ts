import Joi from 'joi';

// User validation schemas
export const loginSchema = Joi.object({
  phoneNumber: Joi.string()
    .pattern(/^\d{10}$/)
    .required()
    .messages({
      'string.pattern.base': 'Phone number must be exactly 10 digits',
      'any.required': 'Phone number is required',
    }),
  password: Joi.string()
    .min(6)
    .max(128)
    .required()
    .messages({
      'string.min': 'Password must be at least 6 characters',
      'any.required': 'Password is required',
    }),
});

export const preRegisterSchema = Joi.object({
  phoneNumber: Joi.string()
    .pattern(/^\d{10}$/)
    .required(),
  password: Joi.string()
    .min(6)
    .max(128)
    .required(),
  name: Joi.string()
    .min(3)
    .max(100)
    .trim()
    .required(),
  userType: Joi.string()
    .valid('student', 'staff')
    .required(),
  class: Joi.when('userType', {
    is: 'student',
    then: Joi.string().required(),
    otherwise: Joi.optional(),
  }),
  section: Joi.when('userType', {
    is: 'student',
    then: Joi.string().required(),
    otherwise: Joi.optional(),
  }),
  rollNumber: Joi.string().max(50).optional(),
  designation: Joi.when('userType', {
    is: 'staff',
    then: Joi.string().required(),
    otherwise: Joi.optional(),
  }),
  subjects: Joi.array().items(Joi.string()).max(10).optional(),
});

export const resetPasswordSchema = Joi.object({
  phoneNumber: Joi.string()
    .pattern(/^\d{10}$/)
    .required(),
  newPassword: Joi.string()
    .min(6)
    .max(128)
    .required(),
});

// Attendance validation schemas
export const markAttendanceSchema = Joi.object({
  classId: Joi.string().required(),
  date: Joi.string()
    .pattern(/^\d{4}-\d{2}-\d{2}$/)
    .required(),
  subject: Joi.string().max(100).required(),
  period: Joi.string().max(10).optional().allow(null),
  attendance: Joi.array()
    .items(
      Joi.object({
        studentId: Joi.string().required(),
        name: Joi.string().required(),
        rollNumber: Joi.string().optional().allow(''),
        status: Joi.string().valid('present', 'absent').required(),
      })
    )
    .min(1)
    .required(),
  markedBy: Joi.string().required(),
  staffName: Joi.string().max(100).optional().allow(''),
});

// Event validation schemas
export const createEventSchema = Joi.object({
  title: Joi.string().min(3).max(200).trim().required(),
  description: Joi.string().min(10).max(2000).trim().required(),
  eventDate: Joi.string()
    .pattern(/^\d{4}-\d{2}-\d{2}$/)
    .required(),
  eventTime: Joi.string()
    .pattern(/^\d{2}:\d{2}$/)
    .optional()
    .allow(null),
  location: Joi.string().max(200).trim().optional().allow(null),
  category: Joi.string()
    .valid('academic', 'sports', 'cultural', 'holiday', 'exam', 'general')
    .required(),
  targetAudience: Joi.string()
    .valid('all', 'students', 'staff', 'specific_class')
    .required(),
  targetClassIds: Joi.when('targetAudience', {
    is: 'specific_class',
    then: Joi.array().items(Joi.string()).min(1).required(),
    otherwise: Joi.optional().allow(null),
  }),
  priority: Joi.string().valid('low', 'medium', 'high').required(),
  imageUrl: Joi.string().uri().max(500).optional().allow(null),
});

// Pagination schema
export const paginationSchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
});

// Query validation schemas
export const dateRangeSchema = Joi.object({
  startDate: Joi.string().pattern(/^\d{4}-\d{2}-\d{2}$/).optional(),
  endDate: Joi.string().pattern(/^\d{4}-\d{2}-\d{2}$/).optional(),
});