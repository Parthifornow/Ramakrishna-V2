import rateLimit from 'express-rate-limit';
import slowDown from 'express-slow-down';
import { Request } from 'express';

// General API rate limiter
export const apiLimiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '900000'), // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100'),
  message: {
    success: false,
    message: 'Too many requests from this IP, please try again later.',
  },
  standardHeaders: true,
  legacyHeaders: false,
  // Use Redis store in production for distributed systems
  // store: new RedisStore({ ... })
});

// Strict rate limiter for authentication endpoints
export const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 attempts
  skipSuccessfulRequests: true,
  message: {
    success: false,
    message: 'Too many login attempts. Please try again after 15 minutes.',
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// Password reset rate limiter
export const passwordResetLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 3, // 3 attempts per hour
  message: {
    success: false,
    message: 'Too many password reset attempts. Please try again after 1 hour.',
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// Registration rate limiter
export const registrationLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 3, // 3 registrations per hour per IP
  message: {
    success: false,
    message: 'Too many accounts created from this IP. Please try again after 1 hour.',
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// Speed limiter - gradually slow down requests (FIXED)
export const speedLimiter = slowDown({
  windowMs: 15 * 60 * 1000, // 15 minutes
  delayAfter: 50, // Allow 50 requests per 15 minutes at full speed
  delayMs: () => 500, // Fixed: Use function that returns constant delay
  maxDelayMs: 5000, // Maximum delay of 5 seconds
  validate: {
    delayMs: false, // Disable warning
  },
});

// Account lockout tracking
const loginAttempts = new Map<string, { count: number; lockedUntil?: Date }>();

export const checkAccountLockout = (req: Request, res: any, next: any) => {
  const { phoneNumber } = req.body;

  if (!phoneNumber) {
    return next();
  }

  const attempts = loginAttempts.get(phoneNumber);

  if (attempts?.lockedUntil && attempts.lockedUntil > new Date()) {
    const minutesLeft = Math.ceil(
      (attempts.lockedUntil.getTime() - Date.now()) / 60000
    );
    return res.status(423).json({
      success: false,
      message: `Account temporarily locked. Try again in ${minutesLeft} minutes.`,
    });
  }

  next();
};

export const recordLoginAttempt = (phoneNumber: string, success: boolean) => {
  if (success) {
    loginAttempts.delete(phoneNumber);
    return;
  }

  const maxAttempts = parseInt(process.env.MAX_LOGIN_ATTEMPTS || '5');
  const lockoutDuration = parseInt(process.env.LOCKOUT_DURATION_MINUTES || '15');

  const attempts = loginAttempts.get(phoneNumber) || { count: 0 };
  attempts.count += 1;

  if (attempts.count >= maxAttempts) {
    attempts.lockedUntil = new Date(Date.now() + lockoutDuration * 60 * 1000);
  }

  loginAttempts.set(phoneNumber, attempts);
};

// Clean up old lockouts periodically
setInterval(() => {
  const now = new Date();
  for (const [phoneNumber, attempts] of loginAttempts.entries()) {
    if (attempts.lockedUntil && attempts.lockedUntil < now) {
      loginAttempts.delete(phoneNumber);
    }
  }
}, 5 * 60 * 1000); // Every 5 minutes