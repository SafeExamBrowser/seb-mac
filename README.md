# seb-mac
Safe Exam Browser for Mac OS X

Open SafeExamBrowser.xcodeproj in a recent version of XCode. For building you have to switch off code signing or add your own code signing identities. Currently on master the upcoming version 2.1 is being developed, after releasing this we will create branches for future versions.
While in development, the deployment target is set to OS X 10.8 to be able to use Base Localization, upon release Localizable Strings will be converted to xib files and the deployment target will be set back to OS X 10.7.

All information about Safe Exam Browser you'll find at http://safeexambrowser.org. Search discussions boards if you don't find  information in the manual and SEB How To document (see links on page Support).

For your information: There is only ONE correct way how to spell SEB (all three letters in CAPS). That's why even in camel case classes, methods and symbols should be named SEBFilterTreeController.m for example or SEBUnsavedSettingsAnswerDontSave. If you find SEB written as seb, then that's ok if it's some symbol users will never see (but better would have been to use SEB). If you find SEB written as Seb, then that is definitely WRONG (unfortunately some of our past developers were not strict about following naming rules)! But both cases are no reason to file a pull request, please concentrate on real problems...
