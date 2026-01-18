const express = require('express');
const axios = require('axios');
const app = express();
const port = process.env.PORT || 8080;

app.get('/', (req, res) => {
  res.send(`
    <html>
      <head><title>Frontend App</title></head>
      <body>
        <h1>CF Networking Demo - Frontend</h1>
        <p><a href="/call-backend">Call Backend App (C2C Networking)</a></p>
        <p>This demonstrates container-to-container networking!</p>
      </body>
    </html>
  `);
});

app.get('/call-backend', async (req, res) => {
  try {
    // Call backend using internal route
    const response = await axios.get('http://backend-app.apps.internal:8080/api/data');
    res.send(`
      <html>
        <head><title>Backend Response</title></head>
        <body>
          <h1>Response from Backend App</h1>
          <p>Message: ${response.data.message}</p>
          <p>Source: ${response.data.source}</p>
          <p><a href="/">Back</a></p>
        </body>
      </html>
    `);
  } catch (error) {
    res.status(500).send(`
      <html>
        <body>
          <h1>Error calling backend</h1>
          <p>${error.message}</p>
          <p>Make sure C2C network policy is configured!</p>
          <p><a href="/">Back</a></p>
        </body>
      </html>
    `);
  }
});

app.listen(port, () => {
  console.log(`Frontend app listening on port ${port}`);
});