# Lumoslabs Challenge

Create a simple iOS application that, with the use of Google's API's, displays a map of the current area and shows nearby Italian restaurants. 
When choosing a restaurant on the map, display additional detail about the restaurant.

==============================
1) get the google maps SDK 
(from https://developers.google.com/maps/documentation/ios-sdk/start)
The Google Maps SDK for iOS is available as a CocoaPods pod. CocoaPods is an open source dependency manager for Swift and Objective-C Cocoa projects.

If you don't already have the CocoaPods tool, install it on macOS by running the following command from the terminal. For details, see the CocoaPods Getting Started guide.

sudo gem install cocoapods
Create a Podfile for the Google Maps SDK for iOS and use it to install the API and its dependencies:

If you don't have an Xcode project yet, create one now and save it to your local machine. (If you're new to iOS development, create a Single View Application.)
Create a file named Podfile in your project directory. This file defines your project's dependencies.
Edit the Podfile and add your dependencies. Here is an example which includes the dependencies you need for the Google Maps SDK for iOS and Places API for iOS (optional):
source 'https://github.com/CocoaPods/Specs.git'
target 'YOUR_APPLICATION_TARGET_NAME_HERE' do
  pod 'GoogleMaps'
  pod 'GooglePlaces'
end
Premium Plan customers must also add: pod 'GoogleMaps/M4B'.
Save the Podfile.
Open a terminal and go to the directory containing the Podfile:

cd <path-to-project>
Run the pod install command. This will install the APIs specified in the Podfile, along with any dependencies they may have.

pod install
Close Xcode, and then open (double-click) your project's .xcworkspace file to launch Xcode. From this time onwards, you must use the .xcworkspace file to open the project.
