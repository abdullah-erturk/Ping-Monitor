<div align="center">

<a href="https://buymeacoffee.com/abdullaherturk" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>

# 🖥️ Ping Monitor Enterprise 📡

![Platform](https://img.shields.io/badge/Platform-Windows-0078D6?style=for-the-badge)
![Tech](https://img.shields.io/badge/Tech-Batch_&_PowerShell-blue?style=for-the-badge)

[![made-for-windows](https://img.shields.io/badge/Made%20for-Windows-00A4E3.svg?style=flat&logo=microsoft)](https://www.microsoft.com/)
![Open Source?](https://img.shields.io/badge/Open%20source%3F-Of%20course%21%20%E2%9D%A4-009e0a.svg?style=flat)

![sample](https://github.com/abdullah-erturk/Ping-Monitor/blob/main/preview.jpg)

### Nedir
Bu proje, hedef cihazları ve internet servislerini eş zamanlı olarak takip eden, kesinti durumunda anlık e-mail bildirimleri gönderen kurumsal izleme hizmetidir.

### What is it
This project is an enterprise monitoring service that simultaneously tracks target devices and internet services, sending instant email notifications in case of outages.

</div>

---

## Download Link:
[![Stable?](https://img.shields.io/badge/Release-v1.svg?style=flat)](https://github.com/abdullah-erturk/Ping-Monitor/archive/refs/heads/main.zip)

<details>
<summary><strong>Türkçe Tanıtım</strong></summary>

### 🚀 Genel Bakış
**Ping Monitor Enterprise**, ağınızdaki kritik IP adreslerini, web sitelerini ve cihazları 7/24 kesintisiz olarak izleyen kurumsal düzeyde bir ağ takip yazılımıdır. PowerShell tabanlı modern bir arayüz (GUI) ile Windows Servisi (`Windows Service`) mimarisini birleştirerek hem kullanıcı dostu hem de sistem seviyesinde kararlı bir çözüm sunar.

### 🛡️ Öne Çıkan Özellikler
- **Windows Servis Mimarisi**: Uygulama arayüzünü kapatsanız dahi arka planda sistem seviyesinde çalışmaya devam eder.
- **Paralel İzleme (TPL)**: Çoklu hedef takibi tek tek değil, eş zamanlı (parallel) yapılır. 100 hedef bile olsa saniyeler içinde kontrol edilir.
- **Akıllı Bildirim (Anti-Spam)**: Bir hedef düştüğünde sizi mail yağmuruna tutmaz. 30 dakikalık "Alert Cooldown" mekanizması ile spamları önler.
- **Kurtarma Bildirimleri (Recovery)**: Bağlantı geri geldiğinde sizi anlık olarak yeşil temalı bir "RECOVERY" maili ile bilgilendirir.
- **Üst Seviye Güvenlik (DPAPI)**: SMTP şifreleriniz donanım tabanlı şifreleme ile korunur; `config.ini` içinde düz metin olarak asla saklanmaz.
- **Otomatik Yönetici Yetkisi (Self-Elevation)**: Uygulama açıldığı anda gerekli izinleri otomatik olarak talep eder; manuel müdahale gerektirmez.
- **Log Yönetimi**: 1000 satırlık dinamik log rotasyonu ve yerleşik "Logu Temizle" özelliği ile disk şişmesini önler.
- **Çoklu Dil Desteği**: Tamamen yerelleştirilmiş Türkçe ve İngilizce arayüz/bildirim desteği. INI dosyalarının çevrilmesi ile farklı dil desteği eklenebilir.

### 🛠️ Kurulum ve Kullanım
1. **Dosyaları İndirin**: Tüm proje dosyalarını bir klasöre çıkartın.
2. **Uygulamayı Çalıştırın**: `monitor.cmd` dosyasına sağ tıklayıp "Yönetici Olarak Çalıştır" seçeneğini seçin.
3. **Ayarları Yapılandırın**:
   - İzlenecek IP/Domain adreslerini girin.
   - SMTP (Mail) ayarlarınızı yapın.
   - Pingleme aralığını (saniye) belirleyin.
4. **Kaydedin**: "Kaydet" butonuna basarak ayarlarınızı `config.ini` dosyasına işleyin.
5. **Servis Kurulumu**: "Hizmet Olarak Yükle" butonuna basarak izlemeyi Windows sistem servislerine dahil edin.

### 💻 Teknik Detaylar
- **Dil**: PowerShell Core + C# Snippets (TPL & ServiceBase)
- **Şifreleme**: Windows Data Protection API (DPAPI)
- **Arayüz**: WinForms (Modern Glassmorphism-ish UI)
- **Bağımlılıklar**: .NET Framework 4.5+
- **İşletim Sistemi**: Windows 10+
  
### 📬 Bildirim Mantığı ve Çalışma Prensibi
Uygulama, kurumsal süreklilik ve e-mail verimliliği için şu mantıkla çalışır:
- **Bağımsız Takip**: Her hedef birbirinden bağımsız olarak paralel işlenir. Bir cihazın çökmesi diğerlerini etkilemez.
- **Hata Eşiği (6 Deneme)**: Gereksiz uyarıları (false positive) önlemek için bir cihaz ancak üst üste 6 kontrol boyunca erişilemez olursa "Down" sayılır ve mail atılır.
- **Hedef Bazlı Mail**: Her hedef, kendi özel başlığıyla ("Ping Alert: [Hedef]") ayrı bir mail olarak gönderilir.
- **Anti-Spam (30 Dakika)**: Bir cihaz down kalmaya devam ederse, her döngüde mail atmak yerine 30 dakikada bir hatırlatma maili gönderir.
- **Kurtarma (Recovery)**: Cihaz tekrar erişilebilir olduğunda anında yeşil renkli bir düzelme bildirimi gönderilir.

---

</details>

<details>
<summary><strong>English Description</strong></summary>

### 🚀 Overview
**Ping Monitor Enterprise** is an enterprise-grade network monitoring suite that tracks critical IP addresses, websites, and devices 24/7. Combining a modern PowerShell-based GUI with a robust Windows Service architecture, it provides both a user-friendly experience and system-level stability.

### 🛡️ Key Features
- **Windows Service Integration**: Continues to run in the background as a system service even if the GUI is closed.
- **Parallel Monitoring (TPL)**: Multi-target tracking is performed simultaneously (parallel) using the Task Parallel Library.
- **Smart Alerts (Anti-Spam)**: Prevents email fatigue with a 30-minute "Alert Cooldown" mechanism.
- **Recovery Notifications**: Sends an instant green-themed "RECOVERY" email when a connection is restored.
- **Hardware-Level Security (DPAPI)**: SMTP passwords are encrypted using Windows DPAPI; they are never stored as plain text.
- **Pro Log Management**: Features 1000-line dynamic log rotation and a built-in "Clear Log" button to prevent disk bloat.
- **Full Localization**: Seamlessly switch between English and Turkish for all UI elements and email notifications. Support for different languages ​​can be added by translating the INI files.

### 🛠️ Setup & Usage
1. **Download**: Extract all project files into a dedicated folder.
2. **Run Application**: Right-click `monitor.cmd` and select "Run as Administrator".
3. **Configure Settings**:
   - Enter Target IP/Domain addresses.
   - Set up your SMTP (Email) server settings.
   - Define the ping interval (seconds).
4. **Save**: Click the "Save" button to encrypt and store your settings in `config.ini`.
5. **Install Service**: Click "Install Service" to enable monitoring as a permanent Windows system service.

### 💻 Technical Stack
- **Languages**: PowerShell + C# (ServiceBase & TPL Integration)
- **Encryption**: Microsoft DPAPI (Data Protection API)
- **GUI**: WinForms (Clean & Professional side-by-side design)
- **Requirements**: .NET Framework 4.5 or higher
- **Operating System**: Windows 10+

### 📬 Notification Logic & Operating Principle
The application operates with the following logic for enterprise continuity and email efficiency:
- **Independent Tracking**: Each target is processed in parallel and independently. One device failure does not affect others.
- **Failure Threshold (6 Attempts)**: To prevent false positives, a device is only considered "Down" and an email sent after 6 consecutive failed checks.
- **Target-Specific Emails**: Each unreachable target triggers its own unique email alert with a specific subject ("Ping Alert: [Target]").
- **Anti-Spam (30 Minutes)**: If a device remains down, the system sends reminder emails every 30 minutes instead of every cycle.
- **Recovery**: As soon as a device becomes reachable again, a green-themed recovery notification is sent instantly.

---
</details>

<div align="center">

Made with ❤️ by [Abdullah ERTÜRK](https://github.com/abdullah-erturk)

[🌐 erturk.netlify.app](https://erturk.netlify.app)

</div>
