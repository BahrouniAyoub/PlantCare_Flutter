const jwt = require('jsonwebtoken');

const authenticate = (req, res, next) => {
  const token = req.header('Authorization')?.replace('Bearer ', '');  
  if (!token) return res.status(401).json({ msg: 'No token, authorization denied' });

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {

    res.status(401).json({ msg: 'Token is not valid' });
  }
};

const refreshAccessToken = async (req, res) => {
  const { refreshToken } = req.body;
  
  if (!refreshToken) {
    return res.status(401).json({ msg: 'No refresh token provided' });
  }

  try {
    // Verify refresh token
    const decoded = jwt.verify(refreshToken, process.env.JWT_SECRET);
    
    // Find user based on decoded userId
    const user = await User.findById(decoded.userId);
    if (!user || user.refreshToken !== refreshToken) {
      return res.status(401).json({ msg: 'Invalid refresh token' });
    }

    // Create a new access token
    const newAccessToken = jwt.sign({ userId: user._id }, process.env.JWT_SECRET, {
      expiresIn: '1h', // 1 hour expiry for new access token
    });

    res.json({ accessToken: newAccessToken });
  } catch (error) {
    return res.status(401).json({ msg: 'Invalid refresh token' });
  }
};
module.exports = { authenticate, refreshAccessToken }
