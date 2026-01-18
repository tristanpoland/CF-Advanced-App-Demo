const express = require('express');
const axios = require('axios');
const app = express();
const port = process.env.PORT || 8080;

app.get('/', (req, res) => {
  res.send(`
    <html>
      <head><title>External Service Client</title></head>
      <body>
        <h1>External Service Client</h1>
        <p><a href="/test-external">Test External API Call</a></p>
        <p><a href="/test-dns">Test DNS Resolution</a></p>
        <p>This demonstrates Application Security Groups (ASGs)!</p>
      </body>
    </html>
  `);
});

app.get('/test-external', async (req, res) => {
  try {
    // Try to call external API (will be blocked/allowed based on ASG)
    const response = await axios.get('https://httpbin.org/json', { timeout: 5000 });
    res.send(`
      <html>
        <body>
          <h1>External API Call Succeeded!</h1>
          <p>Successfully called httpbin.org</p>
          <p>ASG allows this traffic ✓</p>
          <pre>${JSON.stringify(response.data, null, 2)}</pre>
          <p><a href="/">Back</a></p>
        </body>
      </html>
    `);
  } catch (error) {
    res.send(`
      <html>
        <body>
          <h1>External API Call Failed</h1>
          <p>Error: ${error.message}</p>
          <p>ASG likely blocking this traffic ✗</p>
          <p>This is expected if restrictive ASG is applied!</p>
          <p><a href="/">Back</a></p>
        </body>
      </html>
    `);
  }
});

app.get('/test-dns', async (req, res) => {
  const dns = require('dns').promises;
  try {
    const addresses = await dns.resolve4('httpbin.org');
    res.send(`
      <html>
        <body>
          <h1>DNS Resolution Succeeded!</h1>
          <p>Domain: httpbin.org</p>
          <p>IP Addresses: ${addresses.join(', ')}</p>
          <p>DNS ASG is working ✓</p>
          <p><a href="/">Back</a></p>
        </body>
      </html>
    `);
  } catch (error) {
    res.send(`
      <html>
        <body>
          <h1>DNS Resolution Failed</h1>
          <p>Error: ${error.message}</p>
          <p>DNS ASG might be missing ✗</p>
          <p><a href="/">Back</a></p>
        </body>
      </html>
    `);
  }
});

app.listen(port, () => {
  console.log(`External service client listening on port ${port}`);
});