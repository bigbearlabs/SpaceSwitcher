#  SpaceSwitcher – a macOS API to switch between Spaces

The API designers of macOS have steadfastly denied application developers of an officially designed and documented API
to control the Spaces of a desktop session, or a standard GUI login. This is probably a decision to prioritise
maintaining a baseline user experience to the user over *all* situations, over risking allowing apps to impair the user experience
when they start poking this area of the system.
this is fundamental to the Mac experience 

SpaceSwitcher provides 2 layers of access to programmatically address macOS Mission Control / Spaces.


## 'no cheating' layer
an API for limitied Spaces functionality, without dependency on private API's: 
- detect spaces as they are discovered;
- programmatically change the current space;

## 'full cheats' layer
is the API that wraps the CoreGraphics private API, so you can e.g.
- send windows to a specific space;
- detect the full set of spaces without having to 'discover' them by making them current;
- in the future, make new ones;
- and also in the future, if someone can really really promise me this is not insane, even *delete* spaces.

Why layers? Because depending on private API is brittle and carries unknown product risk – 
e.g. if you want to submit to the Mac App Store, you'll get ___rejected___.


## Demo

build and run the  SpaceSwitcherDemo app to test out Spaces functionality.
Walk through the app code to understand how to use the framework.



---
Remember, a baseline feel of how a Mac works is remarkably
consistent over decades, so I completely understand the designers at Apple when they decided, 'no, apps shall not
influence this area of the system'. (Unlike graphics, )
