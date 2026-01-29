# PyJHora Python Bundle

Place the PyJHora package (and its dependencies) in this folder so it is bundled
into the app at build time. The Swift bridge appends this directory to
`sys.path` before attempting to import `pyjhora`.

Recommended structure:

```
VedicChart/Resources/python/
  pyjhora/
  swiss_ephemeris/
  ...
```

You can populate this directory by copying a local virtualenv's
`site-packages` contents or by extracting a wheel into this folder.
