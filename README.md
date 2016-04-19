
![Banner](Screenshots/banner.png)

[![Build Status](https://travis-ci.org/mamaral/xkcd-Open-Source.svg)](https://travis-ci.org/mamaral/xkcd-Open-Source)
[![GitHub license](https://img.shields.io/github/license/mashape/apistatus.svg)]()
[![Coverage Status](https://coveralls.io/repos/mamaral/xkcd-Open-Source/badge.svg?branch=master)](https://coveralls.io/r/mamaral/xkcd-Open-Source?branch=master)

## A free, ad-free, open-source, native, and universal xkcd.com reader for iOS. [Download it from the app store now!](https://itunes.apple.com/us/app/xkcd-open-source/id995811425?mt=8)

![portrait](Screenshots/demo.png)


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

- [x] Gathering user feedback (ongoing)
- [x] Searching
- [x] Visual indication that comics are read/unread
- [x] Investigate integrating the ***What If?*** series (probably not happening for now...)
- [x] Favoriting
- [x] 'Next' and 'prev' movement between comics
- [x] View a random comic
- [x] Social sharing
- [x] Code coverage > 25%
- [x] Code coverage > 50%
- [x] Code coverage > 75%
- [x] Code coverage > 95%
- [ ] ***About*** section featuring major contributors
- [ ] Ask users ***one-time only*** to leave a review/rating in the app store, to get some more honest feedback
- [ ] Get Randall Munroe to acknowledge my existence

## Version History
- **v2.1.1** (Available for download in the App Store)
   - iOS 9 networking bug fix (https://github.com/mamaral/xkcd-Open-Source/issues/29)

- **v2.1**
   - Share comics to Facebook and Twitter

- **v2.0**
   - Added the ability to favorite a comic, which is indicated on the comic list with a pretty red heart. Along with this, you're able to toggle a filter on the comic list to see only favorites
   - Roll-the-dice to view a random comic
   - Navigate forward and backward through comics directly from the comic view controller
   - Fixed a potential issue with comics not loading on the first launch

- **v1.2**
 	- Visual indication that comics are read vs. unread
 	- Improved comic view layout so some comics won't be cut off by the alt button
 	- *Hopefully* corrected issue related to disappearing push notifications

- **v1.1**
	- Improved scrolling performance
	- Search *beta*
	- Silent push notifications w/ vibration & app badge
	- Bug fixes

- **v1.0**
	- Initial Release - you can read comics and stuff...


## Contributors

- [Yours Truly](https://github.com/mamaral) - Architect of the iOS app.
- [Sean Ferguson](https://github.com/fergusean) - Architect of the server that pulls content from xkcd and pushes to clients.
- [Ryan Copley](https://github.com/RyanCopley) - CI build improvements.

## Want to help?

Download the app and use it - give us feedback! Leave a star on the repo, and a review on the app. If you find any bugs, have any feature requests, or want to say mean and nasty things to me, [open an issue](https://github.com/mamaral/xkcd-Open-Source/issues/new), and if you can patch the bug or add a feature and submit a pull request, even better - just make sure to follow the same code formatting/style and ***BE SURE TO ADD TESTS*** if applicable.


## License / Attribution

The source is made available under the MIT license. See LICENSE.txt for details. For information regarding xkcd licensing, [click here.](http://xkcd.com/license.html)

Social sharing icons from [Zlatko Najdenovski](https://www.iconfinder.com/zlaten) via a [Creative Commons Attribution 3.0 Unported License](http://creativecommons.org/licenses/by/3.0/).
