#include "DFRobotDFPlayerMini.h"

DFRobotDFPlayerMini myDFPlayer;
HardwareSerial mySerial(1); // gunakan UART1 di ESP32

void setup()
{
    Serial.begin(115200);
    mySerial.begin(9600, SERIAL_8N1, 16, 17); // RX=16, TX=17
    delay(1000);
    Serial.println("Mulai inisialisasi DFPlayer...");
    if (!myDFPlayer.begin(mySerial))
    {
        Serial.println("❌ Gagal inisialisasi DFPlayer!");
        while (true)
            ;
    }

    Serial.println("✅ DFPlayer berhasil diinisialisasi!");
    myDFPlayer.volume(25);

    int fileCount = myDFPlayer.readFileCounts();
    Serial.print("Jumlah file terdeteksi: ");
    Serial.println(fileCount);

    if (fileCount > 0)
    {
        Serial.println("▶️ Memutar file pertama...");
        myDFPlayer.play(1);
    }
    else
    {
        Serial.println("⚠️ Tidak ada file MP3 terdeteksi.");
    }
}

void loop() {}