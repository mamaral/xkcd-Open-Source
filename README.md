
![Banner](Screenshots/banner.png)

[![Build Status](https://travis-ci.org/mamaral/xkcd-Open-Source.svg)](https://travis-ci.org/mamaral/xkcd-Open-Source)
[![GitHub license](https://img.shields.io/github/license/mashape/apistatus.svg)]()
[![Coverage Status](https://coveralls.io/repos/mamaral/xkcd-Open-Source/badge.svg?branch=master)](https://coveralls.io/r/mamaral/xkcd-Open-Source?branch=master)

## A free, ad-free, open-source, native, and universal xkcd.com reader for iOS. [Download it from the app store today!]((https://itunes.apple.com/us/app/xkcd-open-source/id995811425?mt=8))


![portrait](Screenshots/demo.png)
![landscape](Screenshots/demo_landscape.png)

# Features include:

- Notifications when new comics are released
- Search for your favorite comics by text or number
- Maximum GMOs
- Increased meta
- Optimized electron-per-pixel count
- Quantum entanglement
- The most skeptical algorithms
- Now with ***even more*** Pizza

## Architecture

- [AFNetworking](https://github.com/AFNetworking/AFNetworking) for networking. *duh*
- [Realm](https://github.com/realm/realm-cocoa) as a data store.
- [Façade](https://github.com/mamaral/Facade) for the UI layout.
- [GTrack](https://github.com/gemr/GTrack) for interfacing with Google Analytics.
- [SDWebImage](https://github.com/rs/SDWebImage) for image downloading / caching.
- [FLAnimatedImage](https://github.com/Flipboard/FLAnimatedImage) for that one GIF.
- [Fabric](https://get.fabric.io/) for beta distribution, analytics, and crash reporting.
- [xkcd-font](https://github.com/ipython/xkcd-font) because obviously.
- Stripped, modified, and customized [Mosaic Layout](https://github.com/betzerra/MosaicLayout) for the comic list.

## Todo List (in no specific order)

- [x] Searching
- [x] Code coverage > 25%
- [x] Code coverage > 50%
- [ ] Code coverage > 75%
- [ ] Code coverage == 100%
- [ ] Gathering user feedback
- [ ] Favoriting?
- [ ] Visual indication that comics are read/unread
- [ ] Social sharing
- [ ] Investigate integrating the ***What If?*** series
- [ ] ***About*** section featuring contributors
- [ ] Getting Randall Munroe to acknowledge my existence

## Version History
- v1.1 ***(Submitted to Apple - awaiting review)***
	- Improved scrolling performance
	- Search *beta*
	- Silent push notifications w/ vibration & app badge
	- Bug fixes

- v1.0 ***(Available for download in the App Store)***
	- Initial Release


## Contributors

- [Yours Truly](https://github.com/mamaral) - Architect of the iOS app.
- [Sean Ferguson](https://github.com/fergusean) - Architect of the server that pulls content from xkcd and pushes to clients.
- [Ryan Copley](https://github.com/RyanCopley) - CI build improvements.

## Want to help?

Download the app and use it - give us feedback! Leave a star on the repo, and a review on the app. If you find any bugs, have any feature requests, or want to say mean and nasty things to me, [open an issue](https://github.com/mamaral/xkcd-Open-Source/issues/new), and if you can patch the bug or add a feature and submit a pull request, even better - just make sure to follow the same code formatting/style and ***BE SURE TO ADD TESTS*** if applicable.


## License

The source is made available under the MIT license. See LICENSE.txt for details. For information regarding xkcd licensing, [click here.](http://xkcd.com/license.html)
