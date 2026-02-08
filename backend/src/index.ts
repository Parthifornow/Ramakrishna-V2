import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';

// IMPORTANT: Firebase must be imported BEFORE routes
import './config/firebase';
import authRoutes from './routes/auth.routes';
import staffRoutes from './routes/staff.routes';
import classRoutes from './routes/class.route';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/staff', staffRoutes);
app.use('/api/class', classRoutes);

// Health check
app.get('/health', (_req, res) => {
  res.json({
    status: 'ok',
    environment: process.env.NODE_ENV,
  });
});

// Global error handler
app.use(
  (
    err: any,
    _req: express.Request,
    res: express.Response,
    _next: express.NextFunction
  ) => {
    console.error(err);
    res.status(err.status || 500).json({
      success: false,
      message: err.message || 'Internal Server Error',
    });
  }
);

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📍 Health: http://localhost:${PORT}/health`);
  console.log(`🔐 Auth:   http://localhost:${PORT}/api/auth`);
  console.log(`👥 Staff:  http://localhost:${PORT}/api/staff`);
  console.log(`🏫 Class:  http://localhost:${PORT}/api/class`);
});

export default app;