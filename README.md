# xcresult-to-json

A macOS command line tool that parses an Xcode-generated xcresult bundle and outputs a summarizing json for CI.

## Example usage

```
xcodebuild build -resultBundlePath "build.xcresult"
xcresult-to-json build.xcresult --path-root $PWD
```

For more options see: 
```
xcresult-to-json --help
```

## Runtime dependencies

* Requires Xcode to be installed
  - [XCResultKit](https://github.com/davidahouse/XCResultKit), that is used to
   parse the xcresult bundle, internally runs `xcrun xcresulttool`.

## Output format

The json that is written to `stdout` is described by [a Json Schema file](Schema/output.json)

