---
title: Abyssinica SIL - Resources
fontversion: 2.201
---

## Requirements

This font is supported by all major operating systems (macOS, Windows, Linux-based, iOS, and Android), however the extent of that support depends on the individual OS and application.

## Installation

Install the font by decompressing the .zip archive and installing the font using the standard font installation process for .ttf (TrueType/OpenType) fonts for your platform. For additional tips see the help page on [Font installation](https://software.sil.org/fonts/installation).

## Keyboarding and character set support

This font does not include keyboards or other software for entering text. To type the symbols in this font use the keyboarding systems provided in your OS or use a separate utility. SIL’s [Keyman](https://keyman.com/) is a cross-platform keyboarding system and a number of Ethiopic keyboards are available:

- [SIL Power-G Ethiopic keyboard](https://keyman.com/keyboards/sil_ethiopic_power_g)
- [SIL Ethiopic keyboard](https://keyman.com/keyboards/sil_ethiopic)
- [GFF Blin Keyboard](https://keyman.com/keyboards/gff_blin)
- [GFF Ge'ez Keyboard](https://keyman.com/keyboards/gff_geez)
- [Amharic keyboard](https://keyman.com/keyboards/gff_amharic)
- [GFF Tigrinya-Ethiopia Keyboard](https://keyman.com/keyboards/gff_tigrinya_ethiopia)
- [GFF Tigrinya-Eritrean Keyboard](https://keyman.com/keyboards/gff_tigrinya_eritrea)

Various other means may be available for different operating-system platforms to create additional input methods. For instance, Windows (Vista and above) provides an Ethiopic IME. 

For information on other keyboarding options see the overview at [Keyboard Systems Overview (ScriptSource)](https://scriptsource.org/entry/ytr8g8n6sw).

See [Character set support](charset.md) for details of the Unicode characters supported by this font.

## Rendering and application support

This font will work normally like any other font in most applications. If the writing system requires special diacritic positioning the application/OS will need to support OpenType.

Abyssinica SIL is designed to work with two advanced font technologies, [Graphite](https://graphite.sil.org/) and OpenType. To take advantage of the advanced typographic capabilities of this font, you must be using applications that provide an adequate level of support for Graphite or OpenType.

Other suggestions are listed here: [Using Font Features](https://software.sil.org/fonts/features/). 

## Web fonts

Web font versions of this font (in WOFF and WOFF2 formats) are available in the `web` folder. These can be copied to a web server and used as fonts on web pages. A very basic HTML/CSS demo page is also included. For more information on the options and techniques available for using these fonts on web pages see [Using SIL Fonts on Web Pages](https://software.sil.org/fonts/webfonts).

## Text conversion

This font is encoded according to [The Unicode Standard](https://unicode.org). If you have text that uses a legacy, non-Unicode encoding there are tools that can help you convert that text for use with Unicode fonts. See [Introduction to Text Conversion and Transliteration](https://scriptsource.org/entry/xlzd6n5aqt).

In order to use this font with existing data that was created for use with fonts developed using custom-encoded fonts, it is necessary to re-type or convert data to produce data that is encoded in conformance with the Unicode Standard. [SIL Converters](https://software.sil.org/silconverters/) and/or [TECkit](https://software.sil.org/teckit/) can be used for character encoding conversion. TECkit allows users to write their own custom conversion mappings.

Three [TECkit](https://software.sil.org/teckit/) mapping files (compiled and uncompiled) are available as a separate download [SIL-Ethiopia (Latin to Fidel) Unicode mapping](https://github.com/silnrsi/wsresources/tree/master/scripts/Ethi/mappings/latn-ethi). They are intended for use where text has been input “phonetically” as a syllable ("be", "ppii", etc.) and conversion to fidel is desired (U+1264 ቤ, U+1352 ፒ, etc.). 

If you used an earlier version of the **Abyssinica SIL** font, and used some of the Private Use Area (PUA) codepoints in your data, you may wish to use the [PUA to Unicode mapping file](https://github.com/silnrsi/wsresources/tree/master/scripts/Ethi/mappings/sil-pua-unicode) to convert your data from PUA codepoints to Unicode 6.0.  

The TECkit package is available for download from SIL’s [TECkit](https://software.sil.org/teckit/) Web site.

The SIL Converters package is available for download from SIL’s [SIL Converters](https://software.sil.org/silconverters/) Web site.

[Docx Converter for Legacy Ethiopic Font Encoding Systems](https://github.com/geezorg/DocxConverter) -- This tool is available (non-SIL) to assist in migrating Microsoft Word documents in pre-Unicode Ethiopic fonts into a Unicode font supporting Ethiopic script.

