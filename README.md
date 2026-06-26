# ModelGo 🚀

ModelGo is an open-source Flutter application designed to bridge the gap between mobile devices and local AI execution. It provides a seamless interface for users to search, download, and manage quantized Large Language Models (LLMs) directly from the Hugging Face Hub, optimized specifically for mobile hardware.

## ✨ Features

* **Hugging Face Hub Integration:** Search for any open-source model available on Hugging Face directly within the app.
* **Mobile-Optimized Filtering:** Automatically filters out massive models and displays only quantized `.gguf` files under 4GB, ensuring they can safely run on standard mobile hardware without memory crashes.
* **Direct-to-Disk Streaming:** Utilizes a robust background downloading system that streams massive AI weight files directly to the device's secure physical storage, bypassing RAM limitations.
* **Download Management:** Includes real-time download progress tracking and the ability to cancel massive downloads instantly, automatically cleaning up partial/corrupted files.
* **Local File Importing:** Allows users to import existing `.gguf` or `.bin` model files directly from their phone's local storage.
* **Persistent Model Library:** Uses a local SQLite database to track and manage the file paths of all downloaded and imported models for quick access.

## 🛠️ Tech Stack & Architecture

* **Framework:** Flutter (Dart)
* **Networking & Downloads:** `dio` (for REST API communication and chunked file streaming)
* **Local Storage:** `sqflite` (SQLite database for persistent model tracking)
* **File Management:** `path_provider` & `file_picker`

## 📂 Project Structure

* `lib/main.dart`: App entry point and theme configuration.
* `lib/home_screen.dart`: Main dashboard navigation.
* `lib/upload_model_screen.dart`: UI for picking local models and monitoring upload states.
* `lib/hugging_face_page.dart`: Core logic for the Hugging Face REST API, search, filtering, and streaming downloads.
* `lib/model_dao.dart`: Data Access Object for handling SQLite database operations.
* `lib/model_model.dart`: Data models representing the stored AI weights.

## 🚀 Getting Started

### Prerequisites

* Flutter SDK (v3.11.5 or higher)
* Android Studio (for Android deployment) or Xcode (for iOS deployment)
* A physical device with at least 6GB+ RAM (Recommended for running quantized LLMs)

### Installation

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/YourUsername/modelgo.git](https://github.com/YourUsername/modelgo.git)
   cd modelgo

2. **Fetch Dependencies:**
    ```bash
    flutter pub getflutter pub get

3. **Run the app on your connected device:**
    ```bash
    flutter run

## 🗺️ Roadmap (Upcoming Features)

* **Local Inference Engine:** Integrating a C++ bridge (like `llama.cpp` via FFI) to actually load the downloaded `.gguf` weights into memory and generate text offline.
* **Chat Interface:** Building a conversational UI to interact with the downloaded models.
* **Model Deletion:** Adding a UI to remove models from the SQLite database and delete the multi-gigabyte files from physical storage to free up space.

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the issues page on GitHub.

---

## 📄 License

MIT License

Copyright (c) 2026 [Your Name or Organization]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.