# Infrastruktúra (műszaki háttér) és alkalmazás (pl. honlap) létrehozása (HU)

[![en](https://img.shields.io/badge/lang-English%20%F0%9F%87%AC%F0%9F%87%A7-white)](Onboarding.md)
[![hu](https://img.shields.io/badge/nyelv-magyar%20%F0%9F%87%AD%F0%9F%87%BA-white)](Onboarding2.md)

*Üdvözlöm az infrastruktúrájának és az webes alkalmazásának/honlapjának létrehozásának folyamatában!*

![HTML oldal betöltési ideje](/.github/assets/Page-html-load-time.png)

További részletek a [webes alkalmazás futtatásáról](/CV2.md)

- Ki lesz a Szolgáltatógazda
- Infrastruktúra szolgáltatók kiválasztása
- Fiók házirend
- Email (személyes, tranzakciós, tömeges) küldés
- Alkalmazás beállítása
- Miről készüljön biztonsági mentés
- Kiberbiztonság
- Belső kommunikációnk
- Fejlesztők informálása

### Speciális infrastruktúra szolgáltatók

Saját tárhely felépítése.

Az alábbiakat kell intézni minden egyes szolgáltatónál.

1. Pénzügyek
1. Felhasználókezelés
1. Szolgáltatások kezelése
1. Ügyfélszolgálattal való kapcsolattartás
1. Értesítésekre való reagálás

Kategóriánként **egy** szolgáltató.

1. Domain regisztrátor:
   **Gandi :eu:, AWS, Name.com by Donuts, Hexonet by CentralNic, Rackhost/.hu :eu:**
1. DNS szolgáltató:
   **AWS, HE, [Google](https://cloud.google.com/dns/pricing), Exoscale :eu:, Gandi :eu:**
1. Szerver szolgáltató:
   **UpCloud :eu:**
1. SSL tanúsítvány kiadó (HTTPS-hez):
   **[Cheapsslsecurity.com](https://cheapsslsecurity.com/rapidssl/rapidsslcertificate.html),
   [SSLMate](https://sslmate.com/),
   DigiCert,
   Certum :eu:,
   [Buypass](https://www.buypass.com/products/tls-ssl-certificates) :eu:**
1. CDN (fájl kiszolgáló hálózat) szolgáltató:
   **AWS, KeyCDN :eu:, Akamai from Selectel**
1. Tranzakciós email kiküldő:
   **AWS, SparkPost, SparkPost EU :eu:**
1. Biztonsági mentés szolgáltató:
   **AWS, Backblaze B2, Selectel, Oktawave :eu:**

[.hu domain regisztrátorok](https://www.domain.hu/regisztratorok/)

[Google Cloud Platform Prémium Támogatás $100/hó áron](https://cloud.google.com/support/?options=premium-support#support-options)

[AWS Europe számlázás](https://aws.amazon.com/legal/aws-emea/)

[AWS tanúsítványok csak belső használatra](https://aws.amazon.com/certificate-manager/faqs/#general)

### Irányelvek a szolgáltatóknál lévő fiókjainkhoz

- Ki a fiók jogos tulajdonosa?
- Kinek van hozzáférése a fiókhoz?
- Folytatunk jelszó megosztást?
- A főfióknál be van kapcsolva a két-faktoros hitelesítés (2FA)?
- Milyen más nem releváns szolgáltatás van a fiókunkban?
- A domain regisztrációhoz és DNS szolgáltatáshoz használt fiókoknál egy másik domain-en lévő email címet használjunk.
- A fiókhoz használt email cím/telefonszám/bankkártya napi használatban van?
- Használjunk alszámlához kötött virtuális bankkártyát a főszámlához kötött fizikai bankkártya helyett!

### Biztonságos böngésző egy pillanatnyi felhő szerveren

Ebben a részben a biztonságos regisztrációkra készülünk fel.

- Szerver indítás [Windows Server 2016 Standard](https://hub.upcloud.com/server/create) operációs rendszerrel
- A telepítés befejezése konzolon: nyelv beállítása
- Belépés `Administrator`-ként
  [RDP Windows PC-khez](https://ci.freerdp.com/job/freerdp-nightly-windows/arch=win64,label=vs2013/)
  vagy [RDP Mac gépekre](https://itunes.apple.com/us/app/microsoft-remote-desktop/id1295203466?mt=12)
- [Palemoon böngésző](https://www.palemoon.org/download.php?mirror=eu&bits=64&type=installer) letöltése
- UpCloud parancsikon kirakása az Asztalra: `basilisk.exe "https://www.upcloud.com/register/?promo=U29Q8S"`
- AWS parancsikon: `"https://portal.aws.amazon.com/gp/aws/developer/registration/index.html"`
- [`user.js`](https://github.com/szepeviktor/windows-workstation/blob/master/upcloud/user.js)
  letöltése a `%APPDATA%\Moonchild Productions\Basilisk\Profiles\` mappába
- Képernyő-billentyűzet kinyitása jelszó beíráshoz
- Böngésző használata regisztrációkhoz
- Felhő szerver letörlése

### UpCloud regisztráció

Ez a regisztráció angol nyelven folyik, így a jegyzet is.

- Ajánlói URL
- A [KeePass](https://keepass.info/) egy nyílt forráskódú jelszó menedzser
- **Enable 2FA** ([Google Authenticator](https://play.google.com/store/apps/details?id=com.google.android.apps.authenticator2))
- My Account / Billing / MANUAL
- My Account / Billing / AUTOMATED / Credit Card lenyíló lista
- Servers / Deploy a server / Add SSH public key
- IP _hírnév_ ellenőrzése (Security Trails, Project Honey Pot, HE BGP Toolkit, AbuseIPDB)
- Servers / Server listing / (szerver neve) / IP ADDRESSES / REVERSE DNS NAME Public IPv4 + IPv6
- Kilépés (ezzel megakadályozzuk a munkamenetünk eltérítését)
- Szerver IP címének leírása

### Amazon Web Services regisztráció

Ez a regisztráció is angol nyelven folyik, így a jegyzet is.

- https://aws.amazon.com/
- [KeePass](https://keepass.info/) egy nyílt forráskódú jelszó menedzser
- Account type: Business
- Verification phone call: dial numbers
- Support Plan: Basic
- **Enable 2FA** ([Google Authenticator](https://play.google.com/store/apps/details?id=com.google.android.apps.authenticator2))
- Billing preferences / Disable Free Tier Usage Alerts + Enable Billing Alerts
- CloudWatch / Create Alarm for EstimatedCharges
- Route53 / Domain + DNS
- CloudFront / CDN
- SES / Domain + SMTP credentials +
  [Move Out of the Sandbox](https://docs.aws.amazon.com/ses/latest/DeveloperGuide/request-production-access.html) +
  Bounce notification
- S3 / Server backup bucket
- IAM / Route53 API user + CloudFront API user + S3 API user
- Kilépés (ezzel megakadályozzuk a munkamenetünk eltérítését)
- A kapott belépési azonosítók leírása

### Cheapsslsecurity.com regisztráció

Ez a regisztráció is angol nyelven folyik, így a jegyzet is.

[RapidSSL DV](https://cheapsslsecurity.com/rapidssl/rapidsslcertificate.html)

- Buy Multiple Years: 2 Year
- Billing Address, Payment Method

[Dashboard](https://cheapsslsecurity.com/client/ordersummary.html)

- Generate Cert Now
- (1) New **or** Renewal
- (2) Switching from Another SSL Brand: No
- (3) DNS Based Authentication
- (4) Generate CSR: `cert-update-req-install.sh DOMAIN`
- (5) Webserver: Other
- (6) SHA-2

Verify your URL

- Check domain name
- Set TXT record in DNS
- Wait for issuance

[Dashboard / Manage Renewal Email Preferences](https://cheapsslsecurity.com/client/renewalemail-preferences.html)

- Select Admin/Technical contact: `[ ]` `[ ]`

### Email kézbesítés

- Az Interneten nem lehetséges az emailek kézbesítését garantálni
- [ESP (email fiók szolgáltató)](https://2fa.directory/#email)
  a *személyes* emailekhez ideértve a bejövő üzeneteket:
  **Google Workspace, [Protonmail :eu:](https://protonmail.com/signup), [DomainFactory :eu:](https://www.df.eu/int/e-mail-hosting/), [Почта Mail.Ru](https://biz.mail.ru/mail/)**
- Fájl megosztás/küldés/fogadás, nagyfájl küldés/fogadás: [WeTransfer :eu:](https://wetransfer.com/),
  [pCloud :eu:](https://transfer.pcloud.com/),
  [Smash :eu:](https://fromsmash.com/)
- *Tranzakciós (automata)* emailek és értesítő emailek napló kivonatok, riasztások:
  [lásd a szolgáltatók fent](#speci%C3%A1lis-infrastrukt%C3%BAra-szolg%C3%A1ltat%C3%B3k)
- *Tömeges* emailek hírlevélhez: [lásd a szolgáltatók fent](#speci%C3%A1lis-infrastrukt%C3%BAra-szolg%C3%A1ltat%C3%B3k)
- Visszapattanó üzenetek **mindhárom** email típushoz
- Feladó hamisítás és tartalom manipuláció elleni védelem **mindháromhoz**: SPF, DKIM, DMARC
- Egy email cím nekem: `webmaster@`
- Csapatmunka egy Gmail fiókban: [Drag](https://www.dragapp.com/)

### Kiberbiztonság

- Értesítés fiók adatok kiszivárgásánál: email cím keresés https://haveibeenpwned.com/
- Értesítés fiók adatok kiszivárgásánál: jelszó keresés https://haveibeenpwned.com/Passwords
- Minden munkatárs fel kell hagyjon a böngészőben tárolt jelszavakkal, űrlap adatokkal
- Adat-kiszivárgás elleni védelem az alkalmazásban/a honlapon:
  automatikus támadások és felbérelt hackerek
- **Katasztrófa elhárítási terv** (üzemszünetre, biztonsági incidensekre)
- Kéretlen levél (spam) szűrés
- Kártékony programok és adathalász emailek elleni védelem (**jelszó lopás**)
- Billentyűzet naplózó programok elleni védelem
- Kártékony mobil app-ok emailek elleni védelem
- Zsarolóprogramok elleni védelem
- Éves biztonsági ellenőrzés
