# InkLauncher

**InkLauncher** is a minimalist Android launcher designed specifically for **e-ink devices**. It prioritizes **battery efficiency**, **simplicity**, and **high readability**, using only pure black and white tones and no animations.

## Screenshots

| Pantalla principal | Configuración |
|--------------------|----------------|
| ![Home](screenshots/home_screen.png) | ![Settings](screenshots/settings_screen.png) |
| ![Search](screenshots/search_screen.png) | ![Columns View](screenshots/home_screen_columns.png) |


## Screenshots

<p align="center">
  <img src="screenshots/home_screen.png" alt="Home" width="200"/>
  <img src="screenshots/settings_screen.png" alt="Settings" width="200"/>
  <img src="screenshots/search_screen.png" alt="Search" width="200"/>
  <img src="screenshots/home_screen_columns.png" alt="Grid View" width="200"/>
</p>


## ✨ Features

- 📱 **Home Screen App List**
  - Display installed apps with **only names** (icons optional).
  - Option to make the list **scrollable** or static.
  - Support for **1 to 3 columns** layout.
  - Choose how many apps to show on the main screen.
  - Customize **font size** of app names.
  - Sort and select which apps to display.

- 🔍 **Search**
  - Quickly search for any installed app (even if hidden from home screen).

- ⚙️ **Configurable UI Elements**
  - Show or hide:
    - 🔧 Settings button
    - 🔎 Search button
    - 🕒 Time, date, and battery info (updated every minute, not every second to save battery)

- 🖼️ **Icon Toggle**
  - Option to show or hide app icons in the list.

- 🧠 **Built for e-ink**
  - No animations.
  - Black text, white background only.
  - Minimal redraw and screen refresh to preserve screen and battery.

## 📁 Project Structure

- `lib/screens/home_screen.dart` – Main launcher view
- `lib/screens/settings_screen.dart` – Configuration interface
- `lib/screens/search_screen.dart` – App search interface

## 🚀 Getting Started

To run the launcher:

```bash
flutter run
