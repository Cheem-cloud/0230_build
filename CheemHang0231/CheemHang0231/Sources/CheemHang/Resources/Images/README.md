# App Logo Instructions

## Adding the Logo to XCode

1. In Xcode, open your project navigator
2. Locate the `Assets.xcassets` file
3. Right-click on it and select "Show in Finder"
4. Create a new folder named "SplashLogo.imageset" if it doesn't exist already
5. Save the logo image from your message as "logo.png" 
6. Place three versions of the image in the SplashLogo.imageset folder:
   - logo.png (1x)
   - logo@2x.png (2x)
   - logo@3x.png (3x)
7. If you only have one version, just place it as "logo.png" and update the Contents.json file to use it for all scales

## Manual Contents.json Update

If needed, here's how the Contents.json file in the SplashLogo.imageset folder should look:

```json
{
  "images" : [
    {
      "filename" : "logo.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "logo@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "filename" : "logo@3x.png",
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

If you only have one image, use this instead:

```json
{
  "images" : [
    {
      "filename" : "logo.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "logo.png",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "filename" : "logo.png",
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
``` 