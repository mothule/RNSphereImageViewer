# RNSphereImageViewer
This library can watch a spherical image.

# Features

- Support 2 Lens image. like the THETA.
 - https://theta360.com/
- Simple and easy.


# How to use

~~~swift
let vc = RNSphereImageViewController()
vc.configuration = RNSIConfiguration()
let resourceName = "<input image file name.>"
let resourceType = "<input image file type.>"
let path = NSBundle.mainBundle().pathForResource(resourceName, ofType: resourceType)
vc.configuration.filePath = path
vc.configuration.fps = 60
self.navigationController?.pushViewController(vc, animated: true)
~~~

# Runtime Requirements

- iOS 9.3
- Swift 2.2

# Installation and Setup

Support CocoaPods

~~~podfile
pod 'RNSphereImageViewer', '~> 1.0'
~~~

# LICENSE

MIT License


# Attention

I am a Japanese programmer, so I have some trouble writing in English.
You may find a typo or mistake but just be nice with your feedback.

Thank you for your support and kindness.

