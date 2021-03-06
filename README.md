[![CircleCI](https://img.shields.io/circleci/project/github/Swift-Squirrel/NutView.svg)](https://circleci.com/gh/Swift-Squirrel/NutView)
[![platform](https://img.shields.io/badge/Platforms-OS_X%20%7C_Linux-lightgray.svg?style=flat)](https://developer.apple.com/swift/)
[![SPM](https://img.shields.io/badge/spm-Compatible-brightgreen.svg)](https://swift.org)
[![swift](https://img.shields.io/badge/swift-4.0-orange.svg)](https://developer.apple.com/swift/)

# NutView
Amazing template language for web development used n Swift Squirrel web framework (see: [Swift Squirrel](https://github.com/Swift-Squirrel/Squirrel))

### Installing

Add NutView as dependency in your *Package.swift*

```swift
// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Your app",
    products: [
        // Your products
    ],
    dependencies: [
        .package(url: "https://github.com/Swift-Squirrel/NutView.git", from: "1.0.2"),
        // Other dependencies
    ],
    targets: [
        .target(
            name: "Your Target",
            dependencies: [..., "NutView"]),
    ]
)
```

And in source add import line

```swift
import NutView
```

## Usage

NutView uses special swift-like syntax in *.nut.html* files which provide great readability for swift developers.

### Directory structure

NutView use two important directories. 

- First (default name: "**Nuts**") contains another three subdirectories with *.nut.html* files (*Views*, *Layouts*, *Subviews*). In theese three directories you can add another directories or add and edit *.nut.html* files.
- Second (defualt name: "**Fruits**") contains generated files from your *.nut.html* files. (Don't change content of this directory)

You can change this directories with

```swift
NutConfig.nuts = "SomeDir/SomeAnotherDir1/NutsDir"
NutConfig.fruits = "SomeDir/SomeAnotherDir2/FruitDir"
```

#### Nuts/Views
Contains page specific content. For example if we have blog and we want to have page with certain post our view will contain only post information and not layout, header, footer etc...

#### Nuts/Subview
Contains reusable parts of page. For example header or footer.

#### Nuts/Layout
This is actualy our web layout. You can refer to layout from Views which pin View content to Layout at the place where is `\View()`

### Commands

Commands starts with **\\** symbol. You can escape \\ symbol with \\\\

|Name|Syntax|Semantic|
|:--|:--|:--|
|Expression|`\(<expression>)`| Evaluates expression in parentheses and escapes html characters|
|Raw expression| `\RawValue(<expression>)`| Evalutes expression|
|Block end|`\}`|Indicates block end in if, for statements|
|If<br> Else if<br> Else|`\if <expression> {`<br>`\} else if <expression> {` <br>`\} else {` | If expression is `true` run commands in given block otherwise run else if else block if exists|
|If let<br> Else if let|`\if let <variableName> = <expression> {`<br>`\} else if let <variableName> = <expression> {` | If expression is not `nil` store result in `variableName` and run commands in given block otherwise run else if else block if exists|
|Subview|`\Subview(<expression>)`|Add content of given subview at position of this command. *__Note:__* `name` is using dot notation so instead of `MySubviewSubdirectory/Mysubview.nut.html` write `MySubviewSubdirectory.Mysubview`.|
|For|`\for <variable> in <Array>`<br>`\for (<key>, <value>) in <Dictionary>`| Iterates over array(`[Any]`) or dictionary(`[String: Any]`)|
|Date| `\Date(<expression>)`<br>`\Date(<expression>, fromat: <expression>`) | Evaluates expression and print date in given format. If `format` is not set, NutView use default date format specified in `NutConfig.dateDefaultFormat: String { set get }`|
|Layout|`\Layout(<expression>)`| Reffer View to Layout. `name` is using dot notation so instead of `MyLayoutSubdirectory/MyLayout.nut.html` write `MyLayoutSubdirectory.MyLayout`.|
|Title| `\Title(<expression>)` | Set `<title><\title>` header of html document
|Head|`\Head(<expression>)`|Add expression result inside html head tag|
|Body|`\Body(<expression>)`|Add expression result at the end of html body tag|
|View|`\View()`| Indicates where to place View|
 
*__Note:__* For evaluating expressions we use [Evaluation](https://github.com/Swift-Squirrel/Nutview)

### Implicit variables

Some variables are implicit so you don't have to send them as data.

- `view` - This variable contains View name

### Examples

*Sources/main.swift*

```swift
import NutView

let indexView = View(name: "Index") // We don't have to write .nut.html 
let indexContent = try indexView.getContent()
print(indexContent) // prints generated content of index

struct PostData {
    let title: String,
    let body: String,
    let isNew: Bool
}
let postData = PostData(title: "Squirrels", body: "Squirrels are best!", isNew: false)
let postView = try View(name: "Posts.Post", with: postData) // note we write . instead of /
let postContent = try postView.getContent()
print(postContent) // prints generated content of page with given data

let postContentData = try postView.present() // Data representation of view
```

For more examples check [Examples](https://github.com/Swift-Squirrel/Examples) or [Squirrel docs](https://squirrel.codes/docs) -> Views

## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request :D

## Authors

* **Filip Klembara** - *Creator* - [github](https://github.com/LeoNavel)

See also CONTRIBUTORS to list of contributors who participated in this project.

## License

This project is licensed under the Apache License Version 2.0 - see the LICENSE file for details
