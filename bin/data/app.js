require('dotenv').config();

var compression = require('compression');
var createError = require('http-errors');
var express = require('express');
var path = require('path');
var cookieParser = require('cookie-parser');
var morgan = require('morgan');
const winston = require('winston');

const helmet = require('helmet');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const hpp = require('hpp');
const csurf = require('csurf');

const pg = require('pg');
const { Sequelize } = require('sequelize');

const passport = require('passport');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
// const pdfmake = require('pdfmake');
// const pm2 = require('pm2');

var indexRouter = require('./routes/index');
var usersRouter = require('./routes/users');

var app = express();
app.use(compression({
  filter: (req, res) => {
    if (req.headers['x-no-compression']) {
      return false
    }
    return compression.filter(req, res)
  }
}));

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    // Add other transports like file, database, or external logging services here
    // new winston.transports.File({ filename: 'error.log', level: 'error' }),
    // new winston.transports.File({ filename: 'combined.log' }),
  ],
});

const DATABASE_URL = process.env.DATABASE_URL || 'postgres://codespace:password@db:5432/mydatabase';
const sequelize = new Sequelize(DATABASE_URL, {
  dialect: 'postgres', // 'mysql', 'sqlite', 'mssql', 'postgres'
  logging: msg => logger.debug(msg)
});
sequelize.authenticate()
  .then(() => {
    logger.info('Database connection has been established successfully.');
  })
  .catch(err => {
    logger.error('Unable to connect to the database:', err);
    process.exit(1);
  });

app.use(helmet());
const corsOptions = {
  origin: process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : '*', // Allow specific origins or all
  methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
  preflightContinue: false,
  optionsSuccessStatus: 204
};
app.use(cors(corsOptions));
app.use(hpp());

app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, '../client')));

app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'ejs');
app.use(morgan('combined', {
  stream: {
    write: message => logger.info(message.trim())
  }
}));
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again after 15 minutes'
});
app.use('/api/', apiLimiter);
app.use(passport.initialize());

const protectedRouter = express.Router();
protectedRouter.use(passport.authenticate('jwt', { session: false }));
protectedRouter.use(apiLimiter);



app.use('/', indexRouter);
protectedRouter.use('/users', usersRouter);

// catch 404 and forward to error handler
app.use(function (req, res, next) {
  next(createError(404));
});

// error handler
app.use(function (err, req, res, next) {
  logger.error('An unhandled error occurred:', err);

  const statusCode = err.statusCode || 500;
  const message = err.message || 'Internal Server Error';

  res.status(statusCode).json({
    status: 'error',
    statusCode: statusCode,
    message: message,
    // Include stack trace only in development
    stack: process.env.NODE_ENV === 'development' ? err.stack : {}
  });
  res.render('error');
});

module.exports = app;
