#include <WiFi.h>
#include <WiFiUdp.h>
#include <SPI.h>
#include <MFRC522.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

const char* DEVICE_NAME = "ESP32_RFID_Device";
const unsigned long STATUS_UPDATE_INTERVAL = 30000;
const unsigned long CONNECTION_CHECK_INTERVAL = 1000;

// Fixed WiFi credentials
const char* FIXED_SSID = "asdasda";
const char* FIXED_PASSWORD = "11111111";

#define RST_PIN 17
#define SS_PIN 5

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1
#define SCREEN_ADDRESS 0x3C

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

MFRC522 mfrc522(SS_PIN, RST_PIN);
MFRC522::MIFARE_Key key;
bool rfidPresent = false;
String lastRFIDUID = "";
unsigned long lastRFIDRead = 0;
const unsigned long RFID_READ_INTERVAL = 500;

String deviceStatus = "Booting...";
unsigned long deviceUptime = 0;
unsigned long lastStatusUpdate = 0;
unsigned long lastConnectionCheck = 0;
unsigned long lastClientActivity = 0;

WiFiUDP udp;
WiFiServer tcpServer(1234);
WiFiClient tcpClient;
bool tcpConnected = false;
bool handshakeCompleted = false;
const int UDP_PORT = 8888;
const int TCP_PORT = 1234;
const unsigned long CLIENT_TIMEOUT = 45000;

void setup() {
  Serial.begin(115200);
  
  // Initialize OLED display
  if(!display.begin(SSD1306_SWITCHCAPVCC, SCREEN_ADDRESS)) {
    Serial.println(F("SSD1306 allocation failed"));
    for(;;);
  }
  
  display.clearDisplay();
  display.setTextColor(SSD1306_WHITE);
  display.setTextSize(1);
  display.setCursor(0,0);
  display.println("Initializing...");
  display.display();
  delay(2000);

  SPI.begin();
  mfrc522.PCD_Init();

  for (byte i = 0; i < 6; i++) {
    key.keyByte[i] = 0xFF;
  }

  updateOLEDDisplay();

  // Connect to fixed WiFi
  connectToWiFi();

  startNetworkServices();

  deviceStatus = "Ready - Waiting for connections";
  lastClientActivity = millis();
  Serial.println("Device initialization complete");
  Serial.println("RFID Reader Ready - Scan RFID Cards");
  
  updateOLEDDisplay();
}

void loop() {
  deviceUptime = millis();

  handleRFIDReading();
  handleUDPDiscovery();
  handleTCPConnections();
  checkConnectionHealth();

  if (millis() - lastStatusUpdate > STATUS_UPDATE_INTERVAL) {
    updateDeviceStatus();
    lastStatusUpdate = millis();
  }

  // Update OLED display more frequently for real-time status
  static unsigned long lastOLEDUpdate = 0;
  if (millis() - lastOLEDUpdate > 1000) {
    updateOLEDDisplay();
    lastOLEDUpdate = millis();
  }

  delay(50);
}

void updateOLEDDisplay() {
  display.clearDisplay();
  display.setCursor(0,0);
  
  // Line 1: WiFi Status
  display.setTextSize(1);
  if (WiFi.status() == WL_CONNECTED) {
    display.print("WiFi: ");
    display.print(WiFi.SSID());
  } else {
    display.print("WiFi: Disconnected");
  }
  
  // Line 2: IP Address or Connection Status
  display.setCursor(0,10);
  if (WiFi.status() == WL_CONNECTED) {
    display.print("IP: ");
    display.print(WiFi.localIP().toString());
  } else {
    display.print("Connecting...");
  }
  
  // Line 3: TCP Connection Status
  display.setCursor(0,20);
  display.print("TCP: ");
  if (tcpConnected) {
    if (handshakeCompleted) {
      display.print("Connected");
    } else {
      display.print("Wait Handshake");
    }
  } else {
    display.print("Disconnected");
  }
  
  // Line 4: RFID Status
  display.setCursor(0,30);
  display.print("RFID: ");
  if (rfidPresent) {
    display.print("Present");
  } else {
    display.print("No Card");
  }
  
  // Line 5: Last RFID UID (truncated if too long)
  display.setCursor(0,40);
  display.print("UID: ");
  if (lastRFIDUID.length() > 0) {
    String shortUID = lastRFIDUID;
    if (shortUID.length() > 10) {
      shortUID = shortUID.substring(0, 10) + "...";
    }
    display.print(shortUID);
  } else {
    display.print("None");
  }
  
  // Line 6: Device Uptime
  display.setCursor(0,50);
  display.print("Uptime: ");
  display.print(deviceUptime / 1000);
  display.print("s");
  
  display.display();
}

void handleRFIDReading() {
  if (millis() - lastRFIDRead < RFID_READ_INTERVAL) {
    return;
  }

  if (!mfrc522.PICC_IsNewCardPresent()) {
    if (rfidPresent) {
      rfidPresent = false;
      sendRFIDRemoved();
      updateOLEDDisplay(); // Update display when RFID is removed
    }
    return;
  }

  if (!mfrc522.PICC_ReadCardSerial()) {
    return;
  }

  String uidString = "";
  for (byte i = 0; i < mfrc522.uid.size; i++) {
    if (mfrc522.uid.uidByte[i] < 0x10) {
      uidString += "0";
    }
    uidString += String(mfrc522.uid.uidByte[i], HEX);
  }
  uidString.toUpperCase();

  // Always send RFID UID regardless of whether it's the same card
  lastRFIDUID = uidString;
  rfidPresent = true;
  lastRFIDRead = millis();

  Serial.println("RFID Detected: " + uidString);
  handleRFIDData(uidString);
  updateOLEDDisplay(); // Update display when new RFID is detected

  mfrc522.PICC_HaltA();
  mfrc522.PCD_StopCrypto1();
}

void sendRFIDRemoved() {
  String response = "{";
  response += "\"type\":\"rfid_removed\",";
  response += "\"status\":\"removed\",";
  response += "\"timestamp\":" + String(millis());
  response += "}";

  if (tcpClient && tcpClient.connected()) {
    tcpClient.println(response);
    Serial.println("RFID card removed");
  }
}

void startNetworkServices() {
  if (udp.begin(UDP_PORT)) {
    Serial.println("UDP Discovery started on port " + String(UDP_PORT));
  } else {
    Serial.println("Failed to start UDP server!");
  }

  tcpServer.begin();
  tcpServer.setNoDelay(true);
  Serial.println("TCP Server started on port " + String(TCP_PORT));
  Serial.println("Device IP: " + WiFi.localIP().toString());
}

void handleUDPDiscovery() {
  int packetSize = udp.parsePacket();
  if (packetSize) {
    char packetBuffer[255];
    int len = udp.read(packetBuffer, 254);
    if (len > 0) {
      packetBuffer[len] = '\0';
      String request = String(packetBuffer);

      Serial.println("UDP Request from " + udp.remoteIP().toString() + ": " + request);

      if (request == "FLUTTER_DISCOVERY_REQUEST" || request == "ESP32_DISCOVERY_REQUEST") {
        sendDiscoveryResponse(udp.remoteIP(), udp.remotePort());
      }
    }
  }
}

void sendDiscoveryResponse(IPAddress remoteIP, unsigned int remotePort) {
  String response = "{";
  response += "\"device\":\"ESP32_RFID_Device\",";
  response += "\"type\":\"RFID_Learning_Device\",";
  response += "\"ip\":\"" + WiFi.localIP().toString() + "\",";
  response += "\"ssid\":\"" + WiFi.SSID() + "\",";
  response += "\"status\":\"" + deviceStatus + "\",";
  response += "\"rssi\":" + String(WiFi.RSSI()) + ",";
  response += "\"uptime\":" + String(deviceUptime) + ",";
  response += "\"version\":\"2.0\",";
  response += "\"tcp_port\":" + String(TCP_PORT);
  response += "}";

  udp.beginPacket(remoteIP, remotePort);
  udp.print(response);
  udp.endPacket();

  Serial.println("Sent UDP response to " + remoteIP.toString());
}

void handleTCPConnections() {
  if (!tcpConnected) {
    WiFiClient newClient = tcpServer.available();
    if (newClient && newClient.connected()) {
      if (tcpClient) {
        tcpClient.stop();
      }

      tcpClient = newClient;
      tcpConnected = true;
      handshakeCompleted = false; // Reset handshake status for new connection
      lastClientActivity = millis();

      String clientIP = tcpClient.remoteIP().toString();
      Serial.println("New TCP client connected: " + clientIP);

      tcpClient.setNoDelay(true);
      tcpClient.setTimeout(1000);

      sendWelcomeMessage();
      deviceStatus = "Connected to " + clientIP;
      sendDeviceStatus();
      updateOLEDDisplay(); // Update display when TCP connects
    }
  }

  if (tcpConnected && tcpClient.connected()) {
    while (tcpClient.available()) {
      String message = tcpClient.readStringUntil('\n');
      message.trim();

      if (message.length() > 0) {
        Serial.println("TCP Received: " + message);
        lastClientActivity = millis();
        processTCPMessage(message);
      }
    }
  }
}

void sendWelcomeMessage() {
  if (tcpClient && tcpClient.connected()) {
    String welcome = "{";
    welcome += "\"type\":\"welcome\",";
    welcome += "\"device\":\"ESP32_RFID_Device\",";
    welcome += "\"status\":\"connected\",";
    welcome += "\"timestamp\":" + String(millis());
    welcome += "}";

    tcpClient.println(welcome);
    Serial.println("Sent welcome message to client");
  }
}

void checkConnectionHealth() {
  if (tcpConnected) {
    bool currentlyConnected = tcpClient.connected();

    if (!currentlyConnected) {
      Serial.println("Client connection lost");
      tcpClient.stop();
      tcpConnected = false;
      handshakeCompleted = false; // Reset handshake status
      deviceStatus = "Connection lost - Waiting for reconnect";
      updateOLEDDisplay(); // Update display when TCP disconnects
      return;
    }

    if (millis() - lastClientActivity > CLIENT_TIMEOUT) {
      Serial.println("Client timeout, disconnecting...");
      tcpClient.stop();
      tcpConnected = false;
      handshakeCompleted = false; // Reset handshake status
      deviceStatus = "Client timeout - Waiting for connection";
      updateOLEDDisplay(); // Update display when TCP times out
    }
  }
}

void processTCPMessage(String message) {
  if (message == "HANDSHAKE") {
    sendHandshakeAck();
    handshakeCompleted = true;
    updateOLEDDisplay(); // Update display after handshake
  } else if (message == "GET_STATUS") {
    sendDeviceStatus();
  } else if (message == "GET_WIFI_INFO") {
    sendWiFiInfo();
  } else if (message.startsWith("PING:")) {
    String timestamp = message.substring(5);
    sendPong(timestamp);
  } else if (message == "\"type\":\"handshake\"") {
    sendHandshakeAck();
    handshakeCompleted = true;
    updateOLEDDisplay(); // Update display after handshake
  } else {
    if (message.startsWith("{")) {
      processJSONMessage(message);
    } else {
      sendUnknownCommand();
    }
  }
}

void processJSONMessage(String jsonMessage) {
  if (jsonMessage.indexOf("\"type\":\"handshake\"") != -1) {
    sendHandshakeAck();
    handshakeCompleted = true;
    updateOLEDDisplay(); // Update display after handshake
  } else if (jsonMessage.indexOf("\"type\":\"get_status\"") != -1) {
    sendDeviceStatus();
  } else if (jsonMessage.indexOf("\"type\":\"get_wifi_info\"") != -1) {
    sendWiFiInfo();
  } else if (jsonMessage.indexOf("\"type\":\"ping\"") != -1) {
    int tsStart = jsonMessage.indexOf("\"timestamp\":") + 12;
    int tsEnd = jsonMessage.indexOf(",", tsStart);
    if (tsEnd == -1) tsEnd = jsonMessage.indexOf("}", tsStart);
    String timestamp = jsonMessage.substring(tsStart, tsEnd);
    sendPong(timestamp);
  } else {
    sendUnknownCommand();
  }
}

void sendHandshakeAck() {
  String ack = "{";
  ack += "\"type\":\"handshake_ack\",";
  ack += "\"device\":\"ESP32_RFID_Device\",";
  ack += "\"status\":\"ready\",";
  ack += "\"timestamp\":" + String(millis());
  ack += "}";

  if (tcpClient && tcpClient.connected()) {
    tcpClient.println(ack);
    Serial.println("Sent handshake ACK");
  }
}

void sendDeviceStatus() {
  String status = "{";
  status += "\"type\":\"status\",";
  status += "\"device\":\"ESP32_RFID_Device\",";
  status += "\"ip\":\"" + WiFi.localIP().toString() + "\",";
  status += "\"status\":\"" + deviceStatus + "\",";
  status += "\"rssi\":" + String(WiFi.RSSI()) + ",";
  status += "\"uptime\":" + String(deviceUptime) + ",";
  status += "\"ssid\":\"" + WiFi.SSID() + "\",";
  status += "\"connected\":" + String(tcpConnected ? "true" : "false") + ",";
  status += "\"free_heap\":" + String(ESP.getFreeHeap()) + ",";
  status += "\"rfid_present\":" + String(rfidPresent ? "true" : "false") + ",";
  status += "\"last_rfid\":\"" + lastRFIDUID + "\"";
  status += "}";

  if (tcpClient && tcpClient.connected()) {
    tcpClient.println(status);
  }
}

void sendWiFiInfo() {
  String wifiInfo = "{";
  wifiInfo += "\"type\":\"wifi_info\",";
  wifiInfo += "\"ssid\":\"" + WiFi.SSID() + "\",";
  wifiInfo += "\"ip\":\"" + WiFi.localIP().toString() + "\",";
  wifiInfo += "\"gateway\":\"" + WiFi.gatewayIP().toString() + "\",";
  wifiInfo += "\"subnet\":\"" + WiFi.subnetMask().toString() + "\",";
  wifiInfo += "\"rssi\":" + String(WiFi.RSSI()) + ",";
  wifiInfo += "\"fixed_ssid\":\"Dorian\"";
  wifiInfo += "}";

  if (tcpClient && tcpClient.connected()) {
    tcpClient.println(wifiInfo);
    Serial.println("Sent WiFi info");
  }
}

void sendPong(String timestamp) {
  String pong = "{";
  pong += "\"type\":\"pong\",";
  pong += "\"original_timestamp\":" + timestamp + ",";
  pong += "\"response_timestamp\":" + String(millis());
  pong += "}";

  if (tcpClient && tcpClient.connected()) {
    tcpClient.println(pong);
    Serial.println("Sent pong response");
  }
}

void sendUnknownCommand() {
  String response = "{";
  response += "\"type\":\"error\",";
  response += "\"message\":\"Unknown command\",";
  response += "\"timestamp\":" + String(millis());
  response += "}";

  if (tcpClient && tcpClient.connected()) {
    tcpClient.println(response);
  }
}

void handleRFIDData(String rfidData) {
  Serial.println("Processing RFID: " + rfidData);

  String response = "{";
  response += "\"type\":\"rfid_detected\",";
  response += "\"uid\":\"" + rfidData + "\",";
  response += "\"timestamp\":" + String(millis());
  response += "}";

  if (tcpClient && tcpClient.connected()) {
    tcpClient.println(response);
  }

  deviceStatus = "RFID: " + rfidData;
}

void updateDeviceStatus() {
  if (WiFi.status() != WL_CONNECTED) {
    deviceStatus = "WiFi disconnected - Reconnecting";
    Serial.println("WiFi disconnected, attempting reconnect...");
    connectToWiFi();
    updateOLEDDisplay(); // Update display when WiFi status changes
  }
}

void connectToWiFi() {
  if (WiFi.status() == WL_CONNECTED) {
    return;
  }

  Serial.println("Connecting to WiFi: " + String(FIXED_SSID));
  deviceStatus = "Connecting to WiFi...";
  updateOLEDDisplay();

  WiFi.disconnect(true);
  delay(2000);

  WiFi.mode(WIFI_STA);
  WiFi.begin(FIXED_SSID, FIXED_PASSWORD);

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(1000);
    Serial.print(".");
    attempts++;
    updateOLEDDisplay(); // Update display during connection attempt
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("WiFi Connected!");
    Serial.println("IP Address: " + WiFi.localIP().toString());
    deviceStatus = "Connected to " + String(FIXED_SSID);
    startNetworkServices();
    updateOLEDDisplay(); // Update display when connected
  } else {
    Serial.println("WiFi connection failed");
    deviceStatus = "WiFi connection failed";
    // Don't restart, just keep trying
    updateOLEDDisplay();
  }
}
