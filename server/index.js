const WebSocket = require('ws');

const wss = new WebSocket.Server({ host: '0.0.0.0', port: 8080 });

wss.on("connection", (ws) => {
  console.log("Client connected");
  ws.send(JSON.stringify({ event: "connection", data: "connected" }));

  ws.on("message", (data) => {
    console.log("Received message:", data);
    wss.clients.forEach((client) => {
      if (client !== ws && client.readyState === WebSocket.OPEN) {
        client.send(data);
      }
    });
  });
});

console.log("WebSocket signaling server running on ws://0.0.0.0:8080");
