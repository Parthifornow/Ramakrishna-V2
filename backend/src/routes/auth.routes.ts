import express from 'express';
import { AuthController } from '../controllers/auth.controller';
import { authMiddleware } from '../middleware/auth.middleware';

const router = express.Router();

// Public routes
router.post('/pre-register', AuthController.preRegister);
router.post('/complete-registration', AuthController.completeRegistration);
router.post('/login', AuthController.login);
router.post('/reset-password', AuthController.resetPassword);

// Protected routes
router.get('/profile', authMiddleware, AuthController.getProfile);

export default router;