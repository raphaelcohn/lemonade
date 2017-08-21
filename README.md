# lemonade

Creating websites should be as easy as making lemonade - gather your ingredients, follow a simple process and enjoy!

`lemonade` creates static, minified and compressed websites using Hugo, Caddy and RealFaviconGenerator which can deployed by rsync to any Linux host or container with no additional dependencies (not even an installed webserver). All the inputs to the website can be stored in git. Websites can also run locally on any operating system that Caddy supports. It checks the output for common problems, including spelling mistakes, missing files, inappropriate files and the like.

`lemonade` understands about environments (eg production) and lets you separate out the small pieces of configuration (and any secrets) that need to differ.

`lemonade`, wherever, possible, will install its own dependencies - but **only** on the build machine - never on a webserver. It works best on Mac OS X with Homebrew.

If you find lemonade's checks a bit slow, you can speed it up for development by doing `lemonade --development`.


## Making Small Sites

* All PNG, JPG, GIF and SVG images are cleaned and crushed losslessly
* Optionally, PNG and JPG images can be lossly crushed on a per-file basis
* All HTML, CSS, JavaScript, JSON and SVG files are minified
* All textual resources, along with ICO, EOT and TTF binary files are maximally compressed to brotli and gzip (`zopfli -11`)


## Making Robust Sites

* The final output is a completely self-contained folder
* The only dependencies your deployment machine needs are `sh` and `uname`, ie BusyBox
* All configuration and command line settings for `caddy` are in source control
* Configuration can have per-environment overrides
* Configuration can be split, so that 'secret' data (eg passwords, API keys, etc) does not need to put in source control


## Making Safe Sites

`lemonade` has extensive hardenings, build failures and warnings to check that you don't produce a potentially broken or unsafe site. These include:-


### Hardenings

* Changing all file permissions to `0400`, read-only by the current user and no one else
* Changing all folder permissions to `0500`, read and search (list) only to the current user and no one else
* Making sure only the caddy binaries are executable


### Build Failures

* Validating that only files and folders are present (ie not block or char devices, etc)
* There are no broken symbolic links
* There are no absolute symbolic links
* There are no symbolic links which resolve outside of the site
* There are no files other than HTML for errors
* All HTML, XML, SVG, CSS, JavaScript, JSON, CSV, TSV and TXT files are encoded in UTF-8 (or its subset, US-ASCII)
* All PNG, JPEG, GIF, SVG, ICO, HTML, XML, WOFF, TFF and TXT files have a MIME type that matches their file extension\*
* All CSS, CSV, TSV, JavaScript and JSON files are textual†
* All WOFF2 and EOT files are binary†
* All HTML, XML, SVG and JSON files are not empty
* All WOFF2 and EOT files are not empty

\* We can't do this currently for JavaScript, JSON, CSS, CSV, TSV, WOFF2 and EOT because the `file` tool we use can't detect them.
† This is the best we can do currently because of the `file` tools limitations. At least it mitigates problems with FTP and ASCII / binary mode (but you're not still using FTP, are you)?


### Build Warnings

* Checks for `.htm` and `.jpeg` files, which are likely to be mistakes (`lemonade` treats `.html` and `.jpg` as the canonical file extensions)
* Checks for build artifacts from SASS, LESS, Photoshop, etc
* Checks for obsolete Flash files
* Checks for obsolete or rarely supported image formats
* Checks for binary libraries for Windows or Unix
* Checks that the *only* ICO file is `favicon.ico`; ICO files are obsolete otherwise
* Checks for resources which shouldn't exist in a modern site (`.cgi`, `.php`, `.asp`, `.jsp` and `.aspx`)


## Making Good Sites

* Checks for URLs which are not simple, ie composed of a-z, 0-9, hyphen and, for files, period
* Checks for HTML meta-tag descriptions
	* which are empty or missing
	* which are over 160 characters
	* which are not simple
	* which do not end with `.`, `?` or `!`
* Checks for HTML titles
	* which are empty or missing
	* which are over 60 characters
	* which are not simple
	* which end in ` `, `|` or `:`
* Checks spellings in HTML files using `aspell`


## To use

### Preparation

Create a new git repository and add lemonade as a submodule:-

```bash
mkdir my-site
cd my-site
git init
mkdir tools
cd tools
git submodule add https://github.com/raphaelcohn/lemonade.git
cd ../..
ln -s tools/lemonade/lemonade
mkdir -p input
printf '%s\n' 'output/' >.gitignore
```

You'll need to set up a folder structure inside `input`. See Configuration below.


### Creating a Static Website

From the root of your repository, do:-

```bash
./lemonade
```


### Using your Website

Your website, including Caddy and all dependencies, can then be deployed simply by doing `rsync --archive --quiet ./output/site/ USER@REMOTE_SERVER:/path/to/remote/host`.

You can then start your website by doing `./caddy-wrapper serve production` from inside `./output/site`.

The documentation of this step will be improved following operational experience.


### Configuration

All configuration goes into a folder called `input`.

As a general rule, all configuration files, and anything that can be considered to be textual should be UTF-8 encoded (have a UTF-8 character set). If you check your files using the `file` command, it will report the charset as UTF-8, or, in some cases, `ASCII`.

Additionally, all configuration files use line feeds (LF) to terminate lines, not carriage return (CR) and line feed, even on Windows. You may need to adjust your gitconfig to make this work correctly for you if using Windows.


#### Simple Stuff


##### `configuration.sh`

This file contains details of caddy plugins to use and which deployment targets (Operating Systems) to download caddy for.

It can also be used to run custom build commands, as it is just shell script. A much easier alternative to gulp, grunt and Node-JS junkery.

An example:-

```bash
# MUST be listed first
caddy_plugin dns
caddy_plugin net
caddy_plugin http.cache
caddy_plugin http.cors
caddy_plugin http.expires
caddy_plugin http.filter
caddy_plugin http.minify
caddy_plugin http.nobots
caddy_plugin http.proxyprotocol
caddy_plugin http.ratelimit
caddy_plugin http.realip
caddy_plugin http.restic
caddy_plugin tls.dns.digitalocean
caddy_plugin tls.dns.vultr


# First argument is operating system as would be reported by `uname` (with trailing line feed stripped)
# Second argument is architecture as would be reported by `uname -m` (with trailing line feed stripped)
deployment_target Linux x86_64


# Custom build command
# Additional SASS / SCSS processing for AMP (optional)
lemonade_css_compileSassToCssAndAutoprefix "$lemonade_inputPath"/hugo/layouts/partials "$lemonade_inputPath"/hugo/layouts/partials
```

#### Spellchecking

Spellchecking currently uses `aspell`. It's possible to supply additional spellings and replacement words for common spelling mistakes by putting files in the `input/spellchecking` folder for each ISO language code you're using in your website, eg:-

```
	en.wordlist       (Symlink to en_US.wordlist or any other variant)
	en_US.wordlist
```

Spellchecking uses the value of the `html lang` attribute which is then converted to the correct ISO form, eg for `en-gb` it becomes `en_GB` and for `en` it stays as `en`. If this is missing, it defaults to `en_US`. If a file is missing for a language then it is ignored.

Inside each `.wordlist` simply list one word per line, eg

```
tech
MyAppName
```

It is a good idea to make sure words in `.wordlist` files are kept in sort order. The following command will sort your file by byte-order:-

```bash
mv FILE.wordlist FILE.wordlist.orig && LANG=C sort -u -f FILE.wordlist.orig >FILE.wordlist
```

Spelling mistakes are output to the `output/temporary/spelling-mistakes` folder.


#### Favicons & App Manifests

lemonade will generate your favicon and app manifests using the Real Favicon Generator. You'll need to add a little configuration to `input/favicon`:-

```
	master-picture.png
	RealFaviconGenerator.request.template.json
	RealFaviconGenerator.api-key
```

##### `master-picture.png`

This is your favicon input. It should be a square, 512 × 512 PNG image. It can be a symlink.


##### `RealFaviconGenerator.request.template.json`

This is the JSON request template that the Real Favicon Generator API creates for you interactively. For example, mine looks like this:-


```json
{
    "favicon_generation": {
        "api_key": "[TODO: Copy your API key here]",
        "master_picture": {
            "type": "inline",
            "content": "[TODO: Copy the base64-encoded content of the image here]"
        },
        "favicon_design": {
            "ios": {
                "picture_aspect": "background_and_margin",
                "background_color": "#ffffff",
                "margin": "14%",
                "assets": {
                    "ios6_and_prior_icons": true,
                    "ios7_and_later_icons": true,
                    "precomposed_icons": true,
                    "declare_only_default_icon": true
                },
                "app_name": "My App Name"
            },
            "desktop_browser": [

            ],
            "windows": {
                "picture_aspect": "white_silhouette",
                "background_color": "#da532c",
                "on_conflict": "override",
                "assets": {
                    "windows_80_ie_10_tile": true,
                    "windows_10_ie_11_edge_tiles": {
                        "small": true,
                        "medium": true,
                        "big": true,
                        "rectangle": true
                    }
                },
                "app_name": "My App Name"
            },
            "android_chrome": {
                "picture_aspect": "shadow",
                "theme_color": "#ffffff",
                "manifest": {
                    "name": "My App Name",
                    "start_url": "https:\/\/xxxx.com\/",
                    "display": "standalone",
                    "orientation": "not_set",
                    "on_conflict": "override",
                    "declared": true
                },
                "assets": {
                    "legacy_icon": true,
                    "low_resolution_icons": true
                }
            },
            "safari_pinned_tab": {
                "picture_aspect": "silhouette",
                "theme_color": "#5bbad5"
            }
        },
        "settings": {
            "scaling_algorithm": "Mitchell",
            "error_on_image_too_small": false
        },
        "versioning": {
            "param_name": "v",
            "param_value": "FvkkE2q9Wy"
        }
    }
}
```


##### `RealFaviconGenerator.api-key`

This is API key the Real Favicon Generator uses. You may not want to check this into source control.

It should be 40 bytes long. For example, this has been mutilated from mine:-

```
a8627a89584532f46583884e6172a25038857daa
```


#### Caddy

All caddy configuration goes into `input/caddy`.

This contains the following structure:-

```
root/
errors/
markdown-templates/
Caddyfile
caddy.configuration.sh
environments/
	.gitignore
	production/
		public.caddy.configuration.sh
		secret.caddy.configuration.sh
		caddyfiles/
			public.Caddyfile
			secret.Caddyfile
```

The folders under `environments/` contain settings for named deployment environments. The `production` environment is mandatory. One can add other environments, such as `development`, by copying the `production` folder to `development` and editing the associated files.


#### `root/`

Put static content to be served by Caddy here. Alternatively, it can also be stored in `input/hugo/static`.

If you have no static content put an empty `.gitignore` file in this folder (do not use `.gitkeep`, it's non-standard).


#### `errors/`

Put HTML5 error pages here, such as `500.html` or `default.html`. Only files ending `.html` are permitted.

You may want to use Hugo to generate them, however.

Make sure your `Caddyfile` contains an errors directive such as this for each file:-

```
errors syslog {
	404 ../errors/404.html
	* ../errors/default.html
	rotate_size 1
	rotate_age 1
	rotate_keep 30
	rotate_compress
}
```


#### `markdown-templates/`

Put Caddy markdown templates in here. For instance, put files `default.markdown-template.md` and `blog.markdown-template.md` for the following Caddyfile snippet:-

```	
markdown / {
	ext .md
	template ../markdown-templates/default.markdown-template.html
	template blog ../markdown-templates/blog.markdown-template.html
}
```

If you have no markdown templates put an empty `.gitignore` file in this folder (do not use `.gitkeep`, it's non-standard).


##### `Caddyfile`

This should be normal caddy file. When caddy is run, the environment variable `CADDY_WRAPPER_ENVIRONMENT` will be set. This can be used to load environment-particular Caddyfiles. For instance, the following snippet loads all Caddyfiles for, say, the production environment:-

```
localhost {
	import environments/{$CADDY_WRAPPER_ENVIRONMENT}/caddyfiles/*.Caddyfile
}
```

Any caddy headers specified should be US-ASCII encoded, not UTF-8 or ISO-8859-1 ("Latin 1") encoded. This is because confusion will always exist about the correct encoding of HTTP/1.1 headers as early standards were not authoritative.


##### `public.Caddyfile` and `secret.Caddyfile`

These are optional, but provide a way to split up Caddyfile configuration into that which can go into git (`public.Caddyfile`) and that which shouldn't (`secret.Caddyfile`).


##### `caddy.configuration.sh`

This is a POSIX-shell compatible text file which contains configuration to be used when starting Caddy.

The defaults are as follows:-

```bash
caddy_wrapper_set ULIMIT 8192
caddy_wrapper_set ACME_AGREE true
caddy_wrapper_set LOG_STANDARD_ERROR false
caddy_wrapper_set ACME_CA 'https://acme-v01.api.letsencrypt.org/directory'
caddy_wrapper_set ACME_CA_TIMEOUT '10s'
caddy_wrapper_set CPU '100%'  # Can also be a number of cores, eg 3
caddy_wrapper_set ACME_DISABLE_HTTP_CHALLENGE false
caddy_wrapper_set ACME_DISABLE_TLS_SNI_CHALLENGE false
caddy_wrapper_set DNS_PORT 53
caddy_wrapper_set ACME_EMAIL 'webmaster@stormmq.com'
caddy_wrapper_set GRACEFUL_SHUTDOWN_DURATION '5s'
caddy_wrapper_set DEFAULT_HOST 'localhost'
caddy_wrapper_set HTTP_PORT 80
caddy_wrapper_set HTTPS_PORT 443
caddy_wrapper_set DEFAULT_PORT 2015
caddy_wrapper_set ENABLE_HTTP2_PROTOCOL true
caddy_wrapper_set ENABLE_QUIC_PROTOCOL false
caddy_wrapper_set SERVER_TYPE 'http'
```

One might want to change some of these defaults:-
	* `ULIMIT` could be raised;
	* `ACME_CA` could be different for development environments to avoid being rate-limited
	* `ACME_EMAIL` likewise could be different for production

All of these defaults, with the exception of `ULIMIT`, relate to caddy command line settings.

Additionally, since this is shell script, one can also set environment variables to be exported and so be available in the Caddyfile (or `public.Caddyfile`, etc). It is recommended to NOT export environment variables that contain sensitive data, as other users can (maliciously) discover them via `/proc`, etc.

For example, the following will make the environment variable `CADDY_NAME` available:-

```bash
export CADDY_NAME='Raphael Cohn'
```


##### `public.caddy.configuration.sh` and `secret.caddy.configuration.sh`

These are optional, but provide a way to split up caddy start-up configuration int that which can go into git (`public.caddy.configuration.sh`) and that which shouldn't (`secret.caddy.configuration.sh`).

These complement `caddy.configuration.sh`. If present `public.caddy.configuration.sh` is loaded after `caddy.configuration.sh`. If present `secret.caddy.configuration.sh` is then loaded.


#### `environments/.gitignore`

This file stops secret data going into Git. Typically its contents are:-

```
secret.*

```


#### Hugo

Hugo data goes in `input/hugo`. The following structure **MUST** be present:-

```
archectypes/
content/
data/
layouts/
	partials/
		structure/
			.gitignore
static/
themes/
config.toml
```

If any folder contains no content, simply put an empty `.gitignore` file in it.


#### `layouts/partials/structure/.gitignore`

This must contain the following so that generated favicons do not get checked in:-

```
header.favicons.html
```


##### `archetypes/`

Put Hugo archetypes such as `default.md` in here.


##### `content/`

Put blog posts, recipes, courses, etc that will become URLs in here.


##### `data/`

Put Hugo site data `.json` files in here.


##### `layouts/`

Put Hugo layouts in here.


##### `themes/`

Put Hugo themes in here.


#### SASS

SASS and SCSS files can be compiled and autoprefix. Create the following folder structure in `input/sass`:-


```
root/
imports/
plugins/
```

If any folder contains no content, simply put an empty `.gitignore` file in it.


##### `root/`

Put `.sass` and `.scss` files in here. All files ending in `.sass` or `.scss` will be compiled and put into `output/site/root`. If a file is in a subfolder, it will be put into the same subfolder under `output/site/root`. The extension `.sass` or `.scss` will be removed. For example:-

* `files/styles.css.sass` will go to `output/site/root/styles.css`
* `files/more.css.scss` will go to `output/site/root/more.css``
* `files/css/extra/mine.css.scss` will go to `output/site/root/css/extra/mine.css` (ie at a URL of `https://mysite.com/css/extra/mine.css`)

If there is both a `.scss` and a `.sass` file with the same base name then the `.scss` file 'wins'


##### `imports/`

Put folders, or symlinks to folders, in here that are SASS import (load) paths. For example, this is how I customize bootstrap:-

```
	input/
		bootstrap/    Unpacked tarball or git submodule (preferable)
		sass/
			files/
				my-bootstrap-customized.css.sass
			imports/
				bootstrap   (Symlink: ../../bootstrap/scss)
				bootstrap-customization
					_bootstrap-overrides.scss            (Symlink: ../bootstrap/bootstrap.scss)
					_bootstrap-variables-original.scss   (Symlink: ../bootstrap/_variables.scss)
					_variables-overrides.scss            (Replacements for values in bootstrap's _variables.scss, without !default prefix)
	...
```

`my-bootstrap-customized.css.sass` is as follows:-

```
@import "functions";
@import "bootstrap-variables-original";
@import "variables-overrides";
@import "bootstrap-overrides";
```


#### PNG Images

All PNG images must have the file extension `.png`

Any PNG image that ends up in the site root or its subfolders (`<OUTPUT>/site/root` and below) will be crushed. Crushing can be controlled by a `IMAGE.png.options` file parallel with the image in the site root where `IMAGE.png` is the same as your PNG image file name. This is a simple text / shell script file that can contain the following:-

```bash
minimum MINIMUM
maximum MAXIMUM
```

where:-
* `MINIMUM` is a value between 0 and 100. The default if unspecified is 100.
* `MAXIMUM` is a value between 0 and 100. The default if unspecified is 100.

If the file `IMAGE.png.options` is ommitted then no lossy compression is done. If `MINIMUM` is 100 then no lossy compression is done.

The file `IMAGE.png.options` will be removed.

The `IMAGE.png.options` file could be stored in:-

* `input/hugo/static`
* `input/caddy/root`


#### JPEG Images

All JPEG images must have the file extension `.jpg` and **not** `.jpeg`.

Any JPEG image that ends up in the site root or its subfolders (`<OUTPUT>/site/root` and below) will be crushed. Crushing can be controlled by a `IMAGE.jpg.options` file parallel with the image in the site root where `IMAGE.jpg` is the same as your JPEG image file name. This is a simple text / shell script file that can contain the following:-

```bash
maximum MAXIMUM
```

where:-
* `MAXIMUM` is a value between 0 and 100. The default if unspecified is 100.

If the file `IMAGE.jpg.options` is ommitted then no lossy compression is done. If `MAXIMUM` is 100 then no lossy compression is done.

The file `IMAGE.jpg.options` will be removed.

The `IMAGE.jpg.options` file could be stored in:-

* `input/hugo/static`
* `input/caddy/root`


#### GIF Images

All GIF images must have the file extension `.gif`.

Any GIF image that ends up in the site root or its subfolders (`<OUTPUT>/site/root` and below) will be crushed. GIF crushing has no configurable options and is not lossy.


#### SVG Images

All SVG images must have the file extension `.svg`.

Any SVG image that ends up in the site root or its subfolders (`<OUTPUT>/site/root` and below) will be crushed. SVG crushing has no configurable options and is not lossy.


### Build Steps


### Create a clean output folder

* An output folder `output/` is created.
* If there is an `output/temporary` folder then it is deleted.
* If there is an `output/site` folder then it is deleted.


### Clean the cache (optional)

The cache folder `output/cache` is deleted if `--clean-cache` was passed to lemonade on the command line.


### Copy caddy folder structure to output

The caddy folder structure `input/caddy` forms the basic site output. This is copied verbatim, excluding `.git*` files, to `output/site`.

Support wrapper binaries to execute caddy and choose a caddy binary suitable for deployment are added.


### Load Configuration and Run Custom Steps

The configuration in `input/configuration.sh` is loaded. Any commands in this file are executed immediately as POSIX (not bash) shell syntax.

In particular, this step can be used to add additional SASS / SCSS to CSS compilations, eg `lemonade_css_compileSassToCssAndAutoprefix "$lemonade_inputPath"/hugo/layouts/partials "$lemonade_inputPath"/hugo/layouts/partials` to generate HUGO partials that are CSS to be embedded into HTML (useful for AMP pages).


### Compilation of SASS / SCSS to CSS with autoprefixing

All `.sass` and `.scss` files in `input/sass` are compiled using `sassc` and then autoprefixed using `autoprefixer-cli`. Output is placed in `output/site/root`.

Sass imports are resolved against folders inside `input/sass/imports`. Sass plugins are used from `input/sass/plugins`.

When using AMP pages, output may need to go into hugo's partials as the CSS is embedded in the HTML. This can be achieved by adding a specific command to the configuration (see above).


### Download and Cache caddy binaries

Caddy binaries for the choice of caddy plugins and caddy deployment targets (as specified in `input/configuration.sh`) are downloaded and cached if not previously cached.

Symlinks are added to the output to make sure an appropriate caddy binary is used for each deployment target environment.


### Generation of favicons and app manifest

This is done using the Real Favicon Generator service. All generated image and textualy files are put into `output/site/root`. A HTML snippet suitable for the `<head>` of a HTML page is put into `input/hugo/layouts/partials/structure/header.favicons.html`

The generated output is cached in `output/cache/generated-favicons`.

The generated output will be regenerated if the SHA256 hashes of `input/favicon/master-picture.png` or `input/favicon/RealFaviconGenerator.request.template.json` change.


### Hugo site generation

The included hugo standalone binary is used to generate a website; output goes into `output/site/root`. The `404.html` error file is moved into `output/errors`.


#### Image Crushing

* PNG
	* Lossy crushing is done if requested using `pngquant`
	* All images are crushed losslessly using `optipng`
* JPEG
	* All images are crushed losslessly using `jpegoptim`
	* If lossy crushing is requested then it is done as part of the same pass of `jpegoptim`
* GIF
	* Lossy crushing is not done\*
	* All images are crushed losslessly using `gifsicle`
* SVG
	* Lossy crushing is not done
	* All images are crushed losslessly using `svgcleaner`

\* This is due to naming collision between the `gifsicle` binary and the `lossygif` binary; we can not know reliably which one is being used.


#### Minification

* HTML5 (and any embedded JavaScript or CSS) is minified using `html-minifier` (installed as necessary in output cache)
* CSS, JavaScript, JSON, XML and SVG are minified automatically using the Go program `minify` (included in the distribution)


#### Removal of Git and other Source Control files

* Git
	* The git files `.gitignore`, `.git` (either file or folder), `.gitattributes` and `.gitmodules` will be removed from the site root and its subfolders.
	* Additionally, `.gitkeep` files, and any others starting `.git` will be removed, even though they are not 'officially' git recognised files.
* Mecurial
	* Any files starting `.hg` will be removed from the site root and its subfolders
* Subversion
	* Any files starting `.svn` will be removed from the site root and its subfolders
* CVS
	* Any files starting `.cvs` will be removed from the site root and its subfolders


#### Validation of Output

* Build Failures are generated
* Build Warnings are generated, including spelling mistakes


#### Maximal Compression of Output

All output that is textual, and some binary files, are maximally compressed:-

* To gzip (`.gz`) using `pigz -11` (ie better that `gzip -9`)
* To brotli (`.br`)

The original files are retained.

The binary files that are compressed are:-

* ico
* eot
* ttf

Compression has been further enchanced by setting the `html-minifier` settings `sortAttributes` to true and `sortClassName` to true which increases the likelihood of redundant, compressible patterns in HTML.

WOFF files are not compressed, although there is a very slightly gain using pigz. This is because the original WOFF format does not include the newer gzip / zopfli `-11` compression mode.


## License

lemonade is MIT licensed. lemonade wraps, but does not link, binaries by other authors which are covered by lemonade's license.
