#  SpaceSwitcher

A macOS API that allows the unique identification and programmatical switching of spaces.


## 'no cheating' layer

an API for limited spaces functionality, without dependency on private API's: 
- detect spaces as they are discovered;
- programmatically change the current space;


## 'full cheats' layer (coming soon)

an API that wraps the CoreGraphics private API, so you can e.g.
- send windows to a specific space;
- detect the full set of spaces without having to 'discover' them by making them current;
- make new ones;
- if someone can really really promise me this is not insane, even *delete* spaces.
Note the usage of private APIs will render apps that utilise the 'full cheats' layer ineligible for submission to 
the Mac App Store.


## Demo

build and run the  SpaceSwitcherDemo app to test out Spaces functionality.
Walk through the app code to understand how to use the framework.


## Notes

The API designers of macOS have steadfastly denied application developers of an officially designed and documented API
to control the Spaces of a desktop session, or a standard GUI login. 

Given no help from all the system's public frameworks, SpaceSwitcher makes use of how the system switches
to the Space of a window which has been brought to focus. 
Every time the user makes a new Space current, SpaceSwitcher will create a transparent window in that space.
This window provides a mean to uniquely identify a discovered Space and switch to it by activating the window.

A bunch of 'tying up loose ends' goes around this core approach to make it behave seamlessly, 
making it sensible to reuse the effort.
