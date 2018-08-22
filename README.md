# SCPaste

This will place an HTML copy of a buffer on the web on a server to
which the user has SSH access.

It's similar in purpose to services such as [Gist](https://gist.github.com)
or [Pastebin](https://pastebin.com), but it's much simpler since it 
assumes the user has an account on a publicly-accessible HTTP
server. It uses `scp` as its transport and uses Emacs' font-lock as
its syntax highlighter instead of relying on a third-party syntax
highlighter for which individual language support must be added
one-by-one.

Requires [htmlize](https://github.com/hniksic/emacs-htmlize) library.

## Configuration

You'll need to configure your destination:

    (setq scpaste-http-destination "https://p.hagelb.org"
          scpaste-scp-destination "p.hagelb.org:p.hagelb.org")

`scpaste-scp-destination` should be an `scp`-accessible directory that
is also served over HTTP. `scpaste-http-destination` should be the URL
that corresponds to that directory.

Optionally you can set the displayed name and where it should link to:

    (setq scpaste-user-name "Technomancy"
          scpaste-user-address "https://technomancy.us/")

You probably want to set up SSH keys for your destination to avoid
having to enter your password once for each paste. Also be sure the
key of the host referenced in `scpaste-scp-destination` is in your
known hosts file--scpaste will not prompt you to add it but will
simply hang.

## Usage

`M-x scpaste`, (or `scpaste-region`) enter a name, and press
return. The name will be incorporated into the URL by escaping it and
adding it to the end of `scpaste-http-destination`. The URL for the
pasted file will be pushed onto the kill ring.

Two files will be uploaded: the HTML version as well as the raw
version. The HTML version simply has ".html" on the end of the name,
and it includes a link to the raw version at the bottom.

You can autogenerate a splash page that gets uploaded as index.html
in `scpaste-http-destination` by invoking `M-x scpaste-index`. This
will upload an explanation as well as a listing of existing
pastes. If a paste's filename includes "private" it will be skipped.

## Copyright

Copyright © 2008-2018 Phil Hagelberg and contributors.
Distributed under the same terms as GNU Emacs.
