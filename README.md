# seb-mac
Safe Exam Browser for macOS and iOS,
SEB Verificator for macOS

To build, SafeExamBrowser.xcworkspace needs to be opened in a recent version of Xcode (currently 14.3.1). Note: When building SEB for iOS with Xcode 15.x, the custom SEB User Agent cannot be set in UIWebView, which leads to issues when using some SEB integrations in assessment systems. For building, own code signing identities need to be added. SEB uses the com.apple.developer.edu-assessment-mode entitlement, which needs to be requested from Apple for your developer team.

Currently main reflects SEB for macOS/iOS 3.3.2 or newer. SEB is using a unified macOS/iOS/iPadOS Xcode project (Xcode workspace with both macOS and iOS targets and a SEBVerificator target). 

This repository contains the open source SEB code base. Binary security modules and Zoom integration (with proprietary licenses) are not included. You might have to remove missing references in the Xcode workspace and particular security-related code. Please note that we can only consult SEB Alliance Platinum or Diamond contributors about building (customized) SEB versions. The open source code is available mainly for educational purposes and not for building own versions of SEB.

All information about Safe Exam Browser you'll find at http://safeexambrowser.org, especially see https://safeexambrowser.org/developer/overview.html. Other documentation is available in the according repositories. Search discussions boards if you don't find information in the manual and SEB How To document (see links on page Support).

For your information: The correct way how to spell SEB for user-facing text is all three letters in CAPS. If you find SEB written as seb in code, then that's ok if it's some symbol users will never see. If you find SEB written as Seb, then that is definitely WRONG.
