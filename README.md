# open_pdf

On macOS, you can use the `open` command line tool to open a PDF. But what if you need to open the PDF to a particular page?

For that you can use this tool, `open_pdf`. With it you can do:

```sh
$ open_pdf output.pdf 4
```

and it will open the PDF in Preview.app and go to page 4.

## requirements, buid instructions

Requires Xcode to have the Swift build chain

```sh
$ ./build.sh
$ cp .build/release/open_pdf ~/bin # copy it into your path
```

## why

If you're using an agentic workflow where PDF rendering is a target, then it is easy to automate buiding the PDF, easy to automate screenshotting an app (thanks to [peekaboo](https://peekaboo.dev) etc.), but you will also need to to automate opening a PDF to a particular page number. You might not want to install Adobe Reader because its installer is so presumptuous.

## how?

Really, this tool is nothing more than a wrapper for the following snippet of AppleScript

``` osacript
tell application "Preview"
    activate
    open POSIX file "\(filePath)"
    tell front document
        tell application "System Events"
            keystroke "g" using {option down, command down} -- Go to Page…
            delay 0.5
            keystroke "\(sanitizedPage)"
            delay 0.2
            keystroke return
        end tell
    end tell
end tell
```

I wrapped it in an executable, rather than using an honest bash script, because this seems to [work around](https://steipete.me/posts/2025/applescript-cli-macos-complete-guide) intermittent permissions issues. If bash simply worked, that would be simpler and therefore better. But this implementation pattern might be useful if you care to embed applescript in your own executable.








