const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User.js')


const signup = async (req, res) => { 
  const { name, email, password } = req.body;
  try {
    const userExists = await User.findOne({ email });
    if (userExists) return res.status(400).json({ msg: 'User already exists' });

    const user = new User({ name, email, password: await bcrypt.hash(password, 10) });
    await user.save();

    const token = jwt.sign({ id: user.id, role: user.role }, process.env.JWT_SECRET, { expiresIn: '1h' });
    res.json({ token });
  } catch (err) {
    res.status(500).send('Server error');
  }
};

const login = async (req, res) => {
  const { email, password } = req.body;

  try {
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ msg: 'User not found' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ msg: 'Invalid credentials' });
    }

    // Generate access token (expires in 1 hour)
    const accessToken = jwt.sign({ userId: user._id }, process.env.JWT_SECRET, {
      expiresIn: '1h',
    });

    // Generate refresh token (expires in 7 days)
    const refreshToken = jwt.sign({ userId: user._id }, process.env.JWT_SECRET, {
      expiresIn: '7d',
    });

    // Save refresh token to the database (Optional, but recommended)
    user.refreshToken = refreshToken;
    await user.save();

    res.json({
      userId: user._id,
      accessToken,
      refreshToken,
    });
  } catch (error) {
    console.log(error);
    res.status(500).json({ msg: 'Server error' });
  }
};

const getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');
    if (!user) {
      return res.status(404).json({ msg: 'User not found' });
    }
    res.json(user);
  } catch (err) {
    console.error(err); // Log the error to the console for debugging
    res.status(500).send('Server error');
  }
};

module.exports = {
  login,
  signup,
  getProfile,
}
