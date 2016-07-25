This is a simple script that generates basic summary information from the CIViC API

## Installation

Requirements:
  ImageMagick (can be installed via homebrew or your package manager of choice)
  RMagick (Ruby bindings to ImageMagick)
  Gruff (Ruby charting gem)

```
brew install imagemagick
bundle install
```

## Usage

Right now there are no flags or options, and its not built into a gem just yet

```
ruby -I lib/ bin/summarize
```

## LICENSE

MIT
