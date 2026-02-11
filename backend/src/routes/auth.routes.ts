import express from 'express';
import { AuthController } from '../controllers/auth.controller';
import { authMiddleware } from '../middleware/auth.middleware';
import { 
  authLimiter, 
  passwordResetLimiter, 
  registrationLimiter,
  checkAccountLockout 
} from '../middleware/rate-limit.middleware';

const router = express.Router();

// Public routes with rate limiting
router.post('/pre-register', registrationLimiter, AuthController.preRegister);
router.post('/complete-registration', registrationLimiter, AuthController.completeRegistration);
router.post('/login', authLimiter, checkAccountLockout, AuthController.login);
router.post('/reset-password', passwordResetLimiter, AuthController.resetPassword);

// Protected routes
router.get('/profile', authMiddleware, AuthController.getProfile);

export default router;