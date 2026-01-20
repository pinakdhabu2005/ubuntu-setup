# ubuntu-setup

All-in-one setup for Ubuntu, focused on SPPU practicals and related tools.

This project helps you quickly set up:

- Google Chrome  
- Visual Studio Code (VS Code)  
- VS Code settings (for a better default experience)  
- Python tools required for DSBDA (Data Science & Big Data Analytics)

---

## 1. Basic Setup

Installs:

- `curl`
- Google Chrome  
- VS Code  
- Python tools for DSBDA  

Run this in your terminal:

```sh
curl -fsSL is.gd/ubuntubase | sh
```

---

## 2. Extra Setup (Recommended)

Installs everything from **Basic Setup**, plus:

- Extra VS Code configuration / settings

Run this in your terminal:

```sh
curl -fsSL is.gd/ubuntuextra | sh
```

---

## Requirements

- Ubuntu (or a Debian-based system with `apt`)
- Internet connection
- A user with `sudo` privileges

---

## Notes

- These commands download and execute remote scripts.  
  Read the script content (from the short URLs) if you want to verify what is being run.
- If prompted for your password, it is for `sudo` (administrator) access to install packages.
