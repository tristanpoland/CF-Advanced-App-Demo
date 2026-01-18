const express = require('express');
const app = express();
const port = process.env.PORT || 8080;

app.get('/api/data', (req, res) => {
  res.json({
    message: 'Hello from Backend!',
    source: 'backend-app via C2C networking',
    timestamp: new Date().toISOString()
  });
});

app.get('/', (req, res) => {
  res.send(`
    <html>
      <head><title>Backend App</title></head>
      <body>
        <h1>Backend App</h1>
        <p>This app should only be accessible via internal routing!</p>
        <p>API endpoint: /api/data</p>
      </body>
    </html>
  `);
});

app.listen(port, () => {
  console.log(`Backend app listening on port ${port}`);
});