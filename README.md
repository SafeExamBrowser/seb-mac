# seb-mac
Safe Exam Browser for Mac OS X and iOS

Open SafeExamBrowser.xcodeproj in a recent version of Xcode. For building you have to switch off code signing or add your own code signing identities. On master the currently or next to be released version (stable) is available. New versions are being developed on separate branches.

Safe Exam Browser for iOS is currently being developed in the SEB-iOS branch. This is a shared Xcode project with targets for OS X and iOS, just select the right target to build for the according operating system. There is major refactoring going on to be able to share as much code as possible for both OS X and iOS. Currently the building iOS version is a prototype to test Kiosk locking with Guided Access, additional functionality is being added continously. 

All information about Safe Exam Browser you'll find at http://safeexambrowser.org. Search discussions boards if you don't find  information in the manual and SEB How To document (see links on page Support).

For your information: There is only ONE correct way how to spell SEB (all three letters in CAPS). That's why even in camel case classes, methods and symbols should be named SEBFilterTreeController.m for example or SEBUnsavedSettingsAnswerDontSave. If you find SEB written as seb, then that's ok if it's some symbol users will never see (but better would have been to use SEB). If you find SEB written as Seb, then that is definitely WRONG (unfortunately some of our past Windows developers were not strict about following naming rules)! But both cases are no reason to file a pull request, we want to concentrate on real work for now.
