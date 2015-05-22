# Utils package for `lookback:emails`.

fs = Npm.require 'fs'
path = Npm.require 'path'
sass = Npm.require 'node-sass'

# This package assumes that assets (templates, SCSS, CSS ..) are
# stored in the `private` directory. Thanks to that, Meteor won't
# touch the HTML and CSS, which are non-JS files.
#
# However, since the file paths are screwed up when bundling and
# deploying Meteor apps, we need to set the BUNDLE_PATH env var
# to keep track of where the bundle lives.
#
# When deployed, set the BUNDLE_PATH env var to the location, perhaps:
#     /var/www/app/bundle
if process.env.BUNDLE_PATH
  ROOT = path.join(process.env.BUNDLE_PATH, 'programs', 'server', 'assets', 'app')
else
# In development, using PWD is fine.
  ROOT = path.join(process.env.PWD, 'private')

# Export the object on `share`, since CoffeeScript.
share.MailerUtils =

  capitalizeFirstChar: (string) ->
    string.charAt(0).toUpperCase() + string.slice(1)

  # Set up a logger to use through `MailerUtils.Logger`. Verify
  # that necessary methods exists on the injected `logger` and
  # fallback if not.
  setupLogger: (logger) ->
    res = ['info', 'warn', 'error'].map (method) ->
      if not method in logger
        console.warn "The injected logger does not support the #{method} method."
        return false
      return true

    if _.compact(res).length is 0
      console.warn 'Falling back to the native logger.'
      @Logger = console
    else
      @Logger = logger

  joinUrl: (base, path) ->
    # Remove any trailing slashes.
    base = base.replace(/\/$/, '')

    # Add front slash if not exist already.
    unless /^\//.test(path)
      path = '/' + path

    return base + path

  addDoctype: (html) ->
    '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">\n' + html

  readFile: (relativePathFromApp) ->
    file = path.join(ROOT, relativePathFromApp)

    try
      return fs.readFileSync(file, encoding: 'utf8')
    catch ex
      throw new Meteor.Error 500, 'Could not find file: ' + file, ex.message

  # Take a path to a SCSS file and compiles it to CSS with `node-sass`.
  toCSS: (scss) ->
    file = path.join(ROOT, scss)

    try
      return sass.renderSync(file: file, sourceMap: false).css
    catch ex
      # `ex` is somehow a JSON string.
      e = JSON.parse(ex)
      console.error 'Sass failed to compile: ' + e.message
      console.error 'In ' + (e.file or scss)
