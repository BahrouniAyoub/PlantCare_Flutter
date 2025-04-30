const express = require('express');
const connectDB = require('./config/db');
require('dotenv').config();
const app = express();
const cors = require('cors');
const bodyParser = require('body-parser');
const authRoutes = require('./routes/authRoutes.js');
const plantRoutes = require('./routes/plantRoutes.js');

connectDB();
app.use(cors());
app.use(bodyParser.json());
app.use(express.json());


app.use('/api/auth', authRoutes);
app.use('/plants', plantRoutes);
app.use('/api/sensors', require('./routes/sensors'));



const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
