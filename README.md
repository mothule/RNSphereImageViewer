# RNSphereImageViewer
This library can watch a spherical image.

## gif animation

![rnsphereimageviewer_animation3](https://cloud.githubusercontent.com/assets/974367/18443388/a5c2fe06-794f-11e6-9ba6-f43aa9ccaebc.gif)


## Youtube

https://www.youtube.com/watch?v=crqeokiwsfc



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

- iOS 11
- Swift 5

# Installation and Setup

Support CocoaPods

~~~podfile
pod 'RNSphereImageViewer', '~> 3.0'
~~~

# LICENSE

MIT License


# Attention

I am a Japanese programmer, so I have some trouble writing in English.
You may find a typo or mistake but just be nice with your feedback.

Thank you for your support and kindness.

