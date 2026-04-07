# 🚀 Parkwise App Enhancement PRD

## 🎯 Goal
Improve UI/UX, performance, and smoothness of the app WITHOUT breaking existing logic.

---

## ⚠️ Constraints

- Do NOT change business logic
- Do NOT modify Firebase/API
- Do NOT break navigation
- Do NOT change app flow
- Only UI/UX + performance improvements

---

## 🎬 Animations

- Smooth page transitions (fade/slide)
- Button tap animations (scale + ripple)
- Smooth dialog and bottom sheet animations

---

## 🔍 Search Bar

- Rounded corners
- Premium design (Google Maps style)
- Search + clear icon
- Smooth focus animation
- Fast suggestions

---

## 🌗 Theme

- Remove manual theme switching
- Use `adaptive_theme` package
- Support light/dark/system mode

---

## 🎚️ Booking Slider

- Smooth dragging (no lag)
- No heavy rebuilds
- Real-time UI update

---

## 📍 Location System

- Remove city selection
- Keep only sub-area
- Filter parkings based on sub-area

- Improve UI:
  - Bottom sheet
  - Search inside
  - Clean list UI

---

## 🗺️ Map Improvements

- Smooth loading
- Blue marker → user location
- Red marker → searched location
- Auto zoom to user

---

## 🧭 Navigation

- Google Maps-like navigation
- Smooth camera movement
- Draw route polyline
- Center user on start

---

## 📌 Layout Fix

- Buttons must be between:
  - Top search bar
  - Bottom nav bar

---

## ⚡ Suggestions

- Fast and smooth place suggestions
- Show loading state
- Clean dropdown UI

---

## 📑 Booking Screen

- Add tabs:
  - Active
  - Expired

- Smooth tab animation
- Wider tab touch area

---

## 🧭 Bottom Nav Bar

- Increase height slightly
- Smooth tab transitions
- Better spacing

---

## ⚡ Performance

- Use const widgets
- Optimize lists (ListView.builder)
- Avoid unnecessary rebuilds
- Keep animations lightweight

---

## ✅ Final Check

- App runs without errors
- UI improved but unchanged structure
- Navigation works
- Firebase works same