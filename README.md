# Thisayanvilai - Instant Grocery Delivery Flutter Native App 🛒⚡

Flutter Native E-Commerce App for **Thisayanvilai** (`https://thisayanvilai.shop`), fully integrated with WooCommerce REST API and Razorpay Payment Gateway.

## 🚀 Features
- **Live WooCommerce Sync:** All products (Pillsbury Atta, Frooti, Dal, Snacks, Beauty items) load directly from WordPress.
- **Smart Category Filter:** Atta & Rice, Drinks & Juices, Dal & Salt, Health & Wellness, etc.
- **Instant Search:** Fast search across the entire store inventory.
- **Blinkit/Zepto-style Cart:** Real-time quantity adjustments, free delivery badge, dynamic bill calculation.
- **Razorpay Live Gateway:** Supports UPI (GPay, PhonePe, Paytm), Credit/Debit Cards, and Cash on Delivery (COD).
- **Automated Order Creation:** When an order is placed, it is automatically posted to WordPress Admin with complete delivery address and items.

---

## 📱 How to Get Your APK File (Two Ways)

### Method 1: Automatic Cloud Build (Recommended - No PC Setup Needed)
1. Push this `thisayanvilai_flutter_app` folder to your GitHub repository.
2. Go to your repository on GitHub and click the **Actions** tab.
3. The **"Build Thisayanvilai Android APK"** workflow will automatically run.
4. After 3-4 minutes, click the completed run and download **`Thisayanvilai-App-Release-APK`**.
5. Transfer the `.apk` file to your Android phone and install!

### Method 2: Build Locally (If you install Flutter SDK & Android Studio)
```bash
# Navigate to project directory
cd thisayanvilai_flutter_app

# Install packages
flutter pub get

# Run on connected phone / emulator
flutter run

# Build release APK
flutter build apk --release
```
The generated APK will be at:
`build/app/outputs/flutter-apk/app-release.apk`
