import { Request, Response, NextFunction } from 'express';

export const requestLogger = (req: Request, res: Response, next: NextFunction) => {
  const start = Date.now();

  // Log when response finishes
  res.on('finish', () => {
    const duration = Date.now() - start;
    const logLevel = res.statusCode >= 400 ? '❌' : '✅';
    
    console.log(
      `${logLevel} ${req.method} ${req.originalUrl} - ${res.statusCode} - ${duration}ms`
    );

    // Log slow requests (> 1 second)
    if (duration > 1000) {
      console.warn(`⚠️ Slow request detected: ${req.method} ${req.originalUrl} - ${duration}ms`);
    }
  });

  next();
};