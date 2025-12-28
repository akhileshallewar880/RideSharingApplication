# How to Add the Vanyatra Logo

## Steps:

1. Save your Vanyatra logo image with the name: **vanyatra_logo.png**
2. Place it in this folder: `/Users/akhileshallewar/project_dev/taxi-booking-app/mobile/assets/images/`
3. The image should be in PNG format with transparent background for best results
4. Recommended dimensions: 400x200 pixels or similar aspect ratio

## What's Been Updated:

✅ **pubspec.yaml** - Added assets configuration
✅ **passenger_home_screen.dart** - Updated to use the logo image with fallback

## Next Steps:

1. **Save the logo**: Copy your Vanyatra logo image to this folder as `vanyatra_logo.png`
2. **Run flutter**: Execute `flutter pub get` in the terminal
3. **Hot reload**: Press `r` in the terminal or click the hot reload button

The logo will appear in the top header of the passenger home screen, replacing the taxi icon and text.

If the image is not found, it will automatically fall back to the original icon + text design.
