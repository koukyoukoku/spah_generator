#include <WiFi.h>
#include <EEPROM.h>
#include <WiFiUdp.h>
#include <SPI.h>
#include <MFRC522.h>

const char* DEVICE_NAME = "ESP32_RFID_Device";
const unsigned long STATUS_UPDATE_INTERVAL = 30000;
const unsigned long CONNECTION_CHECK_INTERVAL = 1000;

#define EEPROM_SIZE 512
#define SSID_ADDR 0
#define PASS_ADDR 32

#define RST_PIN 21
#define SS_PIN 5

MFRC522 mfrc522(SS_PIN, RST_PIN);
MFRC522::MIFARE_Key key;
bool rfidPresent = false;
String lastRFIDUID = "";
unsigned long lastRFIDRead = 0;
const unsigned long RFID_READ_INTERVAL = 500;

String storedSSID = "";
String storedPassword = "";
String deviceStatus = "Booting...";
unsigned long deviceUptime = 0;
unsigned long lastStatusUpdate = 0;
unsigned long lastConnectionCheck = 0;
unsigned long lastClientActivity = 0;

WiFiUDP udp;
WiFiServer tcpServer(1234);
WiFiClient tcpClient;
bool tcpConnected = false;
const int UDP_PORT = 8888;
const int TCP_PORT = 1234;
const unsigned long CLIENT_TIMEOUT = 45000;

void setup() {
  Serial.begin(115200);
  SPI.begin();
  mfrc522.PCD_Init();
  
  for (byte i = 0; i < 6; i++) {
    key.keyByte[i] = 0xFF;
  }
  
  EEPROM.begin(EEPROM_SIZE);
  readWiFiCredentials();
  
  if (storedSSID.length() > 0 && isValidSSID(storedSSID)) {
    connectToWiFi();
  } else {
    Serial.println("No valid WiFi credentials, starting SmartConfig...");
    storedSSID = "";
    storedPassword = "";
    startSmartConfig();
  }

  startNetworkServices();
  
  deviceStatus = "Ready - Waiting for connections";
  lastClientActivity = millis();
  Serial.println("Device initialization complete");
  Serial.println("RFID Reader Ready - Scan RFID Cards");
}

bool isValidSSID(String ssid) {
  if (ssid.length() == 0 || ssid.length() > 32) return false;
  for (int i = 0; i < ssid.length(); i++) {
    if (ssid[i] < 32 || ssid[i] > 126) return false;
  }
  return true;
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
  
  delay(50);
}

void handleRFIDReading() {
  if (millis() - lastRFIDRead < RFID_READ_INTERVAL) {
    return;
  }
  
  if (!mfrc522.PICC_IsNewCardPresent()) {
    if (rfidPresent) {
      rfidPresent = false;
      sendRFIDRemoved();
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
      lastClientActivity = millis();
      
      String clientIP = tcpClient.remoteIP().toString();
      Serial.println("New TCP client connected: " + clientIP);
      
      tcpClient.setNoDelay(true);
      tcpClient.setTimeout(1000);
      
      sendWelcomeMessage();
      deviceStatus = "Connected to " + clientIP;
      sendDeviceStatus();
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
      deviceStatus = "Connection lost - Waiting for reconnect";
      return;
    }
    
    if (millis() - lastClientActivity > CLIENT_TIMEOUT) {
      Serial.println("Client timeout, disconnecting...");
      tcpClient.stop();
      tcpConnected = false;
      deviceStatus = "Client timeout - Waiting for connection";
    }
  }
}

void processTCPMessage(String message) {
  if (message == "HANDSHAKE") {
    sendHandshakeAck();
  }
  else if (message == "GET_STATUS") {
    sendDeviceStatus();
  }
  else if (message == "GET_WIFI_INFO") {
    sendWiFiInfo();
  }
  else if (message.startsWith("PING:")) {
    String timestamp = message.substring(5);
    sendPong(timestamp);
  }
  else if (message == "\"type\":\"handshake\"") {
    sendHandshakeAck();
  }
  else {
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
  }
  else if (jsonMessage.indexOf("\"type\":\"get_status\"") != -1) {
    sendDeviceStatus();
  }
  else if (jsonMessage.indexOf("\"type\":\"get_wifi_info\"") != -1) {
    sendWiFiInfo();
  }
  else if (jsonMessage.indexOf("\"type\":\"ping\"") != -1) {
    int tsStart = jsonMessage.indexOf("\"timestamp\":") + 12;
    int tsEnd = jsonMessage.indexOf(",", tsStart);
    if (tsEnd == -1) tsEnd = jsonMessage.indexOf("}", tsStart);
    String timestamp = jsonMessage.substring(tsStart, tsEnd);
    sendPong(timestamp);
  }
  else {
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
  wifiInfo += "\"stored_ssid\":\"" + storedSSID + "\"";
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

void scanWiFiNetworks() {
  Serial.println("Scanning WiFi networks...");
  int numNetworks = WiFi.scanNetworks();
  
  String networks = "{";
  networks += "\"type\":\"networks\",";
  networks += "\"networks\":[";
  
  for (int i = 0; i < numNetworks; i++) {
    if (i > 0) networks += ",";
    networks += "{";
    networks += "\"ssid\":\"" + WiFi.SSID(i) + "\",";
    networks += "\"rssi\":" + String(WiFi.RSSI(i)) + ",";
    networks += "\"encryption\":" + String(WiFi.encryptionType(i));
    networks += "}";
  }
  networks += "]}";
  
  tcpClient.println(networks);
  WiFi.scanDelete();
}

void updateDeviceStatus() {
  if (WiFi.status() != WL_CONNECTED) {
    deviceStatus = "WiFi disconnected - Reconnecting";
    Serial.println("WiFi disconnected, attempting reconnect...");
    connectToWiFi();
  }
}

void connectToWiFi() {
  if (WiFi.status() == WL_CONNECTED) {
    return;
  }

  Serial.println("Connecting to WiFi: " + storedSSID);
  deviceStatus = "Connecting to WiFi...";
  
  WiFi.disconnect(true);
  delay(2000);
  
  WiFi.mode(WIFI_STA);
  WiFi.begin(storedSSID.c_str(), storedPassword.c_str());
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(1000);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("WiFi Connected!");
    Serial.println("IP Address: " + WiFi.localIP().toString());
    deviceStatus = "Connected to " + storedSSID;
    startNetworkServices();
  } else {
    Serial.println("WiFi connection failed");
    deviceStatus = "WiFi connection failed";
    storedSSID = "";
    storedPassword = "";
    saveWiFiCredentials();
    ESP.restart();
  }
}

void startSmartConfig() {
  Serial.println("Starting SmartConfig...");
  deviceStatus = "SmartConfig Mode";
  
  WiFi.mode(WIFI_STA);
  WiFi.beginSmartConfig();
  
  Serial.println("Waiting for SmartConfig...");
  
  int timeout = 0;
  while (!WiFi.smartConfigDone() && timeout < 120) {
    delay(500);
    Serial.print(".");
    timeout++;
  }
  
  if (WiFi.smartConfigDone()) {
    Serial.println("SmartConfig Received!");
    
    timeout = 0;
    while (WiFi.status() != WL_CONNECTED && timeout < 30) {
      delay(1000);
      Serial.print(".");
      timeout++;
    }
    
    if (WiFi.status() == WL_CONNECTED) {
      storedSSID = WiFi.SSID();
      storedPassword = WiFi.psk();
      if (isValidSSID(storedSSID)) {
        saveWiFiCredentials();
        Serial.println("WiFi connected and credentials saved!");
        deviceStatus = "SmartConfig success - Connected";
      } else {
        Serial.println("Invalid SSID from SmartConfig");
        storedSSID = "";
        storedPassword = "";
        deviceStatus = "SmartConfig failed - Invalid SSID";
      }
    }
  } else {
    Serial.println("SmartConfig timeout");
    deviceStatus = "SmartConfig failed";
    ESP.restart();
  }
}

void readWiFiCredentials() {
  storedSSID = readFromEEPROM(SSID_ADDR, 32);
  storedPassword = readFromEEPROM(PASS_ADDR, 64);
  Serial.println("Read from EEPROM - SSID: " + storedSSID);
}

void saveWiFiCredentials() {
  writeToEEPROM(SSID_ADDR, storedSSID);
  writeToEEPROM(PASS_ADDR, storedPassword);
  EEPROM.commit();
  Serial.println("Saved credentials to EEPROM");
}

void resetWiFiCredentials() {
  storedSSID = "";
  storedPassword = "";
  writeToEEPROM(SSID_ADDR, "");
  writeToEEPROM(PASS_ADDR, "");
  EEPROM.commit();
  Serial.println("WiFi credentials reset");
}

void writeToEEPROM(int address, String data) {
  for (int i = 0; i < data.length(); i++) {
    EEPROM.write(address + i, data[i]);
  }
  EEPROM.write(address + data.length(), '\0');
}

String readFromEEPROM(int address, int maxLength) {
  String result = "";
  for (int i = 0; i < maxLength; i++) {
    char c = EEPROM.read(address + i);
    if (c == 0) break;
    result += c;
  }
  return result;
}