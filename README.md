# TypeTuner Web

This repo contains sources for SIL's TypeTuner Web (TTW) service.

This service enables users to select the SIL font they want to tune along with exactly what features they want enabled or disabled. The service then runs SIL TypeTuner and delivers the customized font to the user via zip-file download.

For more information about using TTW to obtain custom variants of SIL fonts, please see https://scripts.sil.org/ttw.

**Note:** While this repo contains a copy of the command-line TypeTuner program itself, it is maintained as part of [font-ttf-scripts](https://github.com/silnrsi/font-ttf-scripts).

## TypeTuner Web URLs

The URL to access TypeTuner Web in interactive mode is:

```
http://scripts.sil.org/ttw/fonts2go.cgi
```

In interactive mode, only the most recent releases of fonts are visible (but see [Control files](#control-files)).

TTW also supports non-interactive or "direct download" URLs whereby
specific feature combinations defined on the server (see [`.packages`](#packages)) can be selected by specially crafted URLs. The URL options include:
- `family` (required): Specifies the font family tag (without spaces and without any version information)
- `pkg` (required): Specifies the TypeTuner configuration file to use (with spaces removed).
- `ver` (optional): The specific font version desired.

Examples:

To retrieve the current SIL Charis Literacy Compact font, the URL would be:

```
http://scripts.sil.org/ttw/fonts2go.cgi?family=CharisSIL&pkg=LiteracyCompact
```

and to retrieve an older version, say 4.106:

```
http://scripts.sil.org/ttw/fonts2go.cgi?family=CharisSIL&pkg=LiteracyCompact&ver=4.106
```

## Adding fonts to TypeTuner Web

Once a tunable font family is ready, it can be added to TTW by adding an appropriate subfolder tree to this repo under `web/server/TypeTuner/tunable-fonts`. The name of the folder at the root of this subfolder tree should be the name of the font followed by its version, for example `Charis SIL 5.000`.

Under that root subfolder should be all the files that are intended to be delivered to the user, in the desired folder hierarchy. In addition, there can be _control files_ (that are not delivered to the user) and _tt files_ (that are modified prior to delivery to the user).

### Control files
Control files (or folders) provide configuration information to TTW and are not included in the downloaded font package. Their names always start with a `.` (period) character. The following control files/folders are recognized at the root of the subfolder tree:

#### `.hide`
If present, the font will be hidden from all interactive users.

#### `.test`
If present, the font will be hidden from interactive users unless one of the following conditions is met:
- The URL uses something other than `fonts2go.cgi`
- The URL includes a `dev` parameter

This is useful for testing a font prior to making it publicly available.

#### `.ttwrc`
This file uses `keyword=value` format to provide additional configuration information. Whitespace is ignored before or after the keyword or value, and preserved within the value. Supported keywords are:

- `helpurl` - value is the URL of a page or document that provides user help regarding the features supported by this font release.
- `omittedfeature` - value is the name of a feature that should be completely omitted from TTW's UI
- `omittedvalue` - value is a compound string identifying a feature value that should be omitted from TTW's UI. The format of this compound string is:  `feature name : feature value`

Example:

```
helpurl = http://software.sil.org/charis/support/smart-font-features/#user
omittedfeature = Small Caps
omittedvalue = Line spacing : Imported 
```

#### `.help_url` (deprecated)
The first ine of this file should be the URL of a page or document that provides user help regarding the features supported by this font release. This file is deprecated; use [`.ttwrc`](#.ttwrc) instead.

#### `.packages`
This is a subfolder containing TypeTuner feature settings files for preconfigured font downloads, thus making it possible to easily specify a URL that is a direct download of the specific configuration. 

Example:

The file `web/server/TypeTuner/tunable-fonts/Charis SIL/.packages/Literacy Compact` contains the TypeTuner feature settings for selecting the Literacy Alternates and Tight Line Spacing, and thus the following URL is a direct download link for that package:

```
http://scripts.sil.org/ttw/fonts2go.cgi?family=CharisSIL&pkg=LiteracyCompact
```

(Note the removal of the spaces in the parameter values.)

### TT files
For certain files, e.g., `FONTLOG.txt`, it can be useful to adjust the file contents prior to download. Files with a basename ending in `_tt` (case insensitive; for example, `FONTLOG_TT.txt`) will be renamed without the `_tt` and undergo field substitution within the text of the file. The following substitutions are available:

- `%DATE%` replaced with current date in format `dd MMM yyyy`, e.g., 09 Jul 2019
- `%ISODATE%` replaced with current date in format `yyy-mm-dd`, e.g., 2019-07-09

Example:

```
ChangeLog
---------
(This should list both major and minor changes, most recent first.)

%ISODATE% (SIL TypeTuner) Tuned version of Scheherazade Version 2.020 (maintenance release)
-- Tuned and delivered by SIL TypeTuner (http://scripts.sil.org/ttw/fonts2go.cgi).
-- See included xml file for details of feature changes.
```
