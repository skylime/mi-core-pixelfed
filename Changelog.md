# Changelog

## 24.4.2

### New

* Pixelfed update to 0.12.5. [Thomas Merkel]

## 24.4.1

### Fix

- Fix permissions and variable. [Thomas Merkel]

## 24.4.0

### New

- The real initial commit to successfully provide Pixelfed. [Thomas
  Merkel]

  * Configure PixelFed via metadata
  * Configure MariaDB and PHP-FPM
  * Fix file permissions in PixelFed because the application is running as
    different user. A patch file is provided and used after the
    application installation.
