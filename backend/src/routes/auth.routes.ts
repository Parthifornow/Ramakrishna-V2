import express from 'express';
import { AuthController } from '../controllers/auth.controller';
import { authMiddleware } from '../middleware/auth.middleware';
import { 
  authLimiter, 
  passwordResetLimiter, 
  checkAccountLockout 
} from '../middleware/rate-limit.middleware';

const router = express.Router();

// Admin routes - NO rate limiting for admin dashboard
router.post('/admin/pre-register', AuthController.preRegister);
router.post('/admin/complete-registration', AuthController.completeRegistration);

// Public routes with rate limiting (for mobile app)
router.post('/pre-register', authLimiter, AuthController.preRegister);
router.post('/complete-registration', authLimiter, AuthController.completeRegistration);
router.post('/login', authLimiter, checkAccountLockout, AuthController.login);
router.post('/reset-password', passwordResetLimiter, AuthController.resetPassword);

// Protected routes
router.get('/profile', authMiddleware, AuthController.getProfile);

export default router;