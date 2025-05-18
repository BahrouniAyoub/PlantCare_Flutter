const express = require('express');
const router = express.Router();
const { login, getProfile, signup, getUserById} = require('../controllers/authController'); 
const {authenticate} = require('../middleware/authMiddleware');

router.post('/signup', signup);
router.post('/login', login);
router.get('/profile', authenticate, getProfile);
router.get('/:id', getUserById);


module.exports = router;