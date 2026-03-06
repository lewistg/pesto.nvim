# Default runner

Some sem-formal design notes for the pesto.nvim's default runner.

## The build window

The "build window" is the window pesto.nvim uses to do the following things:

1. Show output from a bazel execution
2. Show the target summary

## Reqirements

There are several types of buffers that may be displayed in the build window.
All of the open build windows should be in sync.

Here are the different states and transitions between them:

* State: Build window closed
    * Event: A bazel build is invoked
        * Action: Open a new build window with the job buffer displayed
        * Next state: Build window open displaying Bazel output
        * Implementation notes: The job should be started in a buffer with vim.fn.termopen.
* State: Build window open, Bazel build in progress
    * Event: Build finishes successfuly
        * Action: Do nothing
        * Next state: Build window open, Bazel build finished
    * Event: Build finishes with build errors
        * Condition: There are quickfix items to display
            * Action: Display the quickfix buffer in the build window
            * Next state: Displaying the quickfix window
        * Condition: There are no quickfix items to display
            * Action: Do nothing
            * Next state: Build window open, Bazel build finished
    * Event: Build window open, user changes the displayed buffer from
        * Action: Unmark window as the build window
        * Next state: Build window closed



The `auto_open_build_term` setting determines whether or not a "build window" automatically opens when a build is invoked.

### Auto-open enabled

- When a build is invoked, the default runner should open a window that shows Bazel's output.
- By default the build windows should stay focused on Bazel's latest output--effectively tailing Bazel's output.
- There are a couple cases when the build finishes:
    - Case: The build finishes successfully
        - Don't do anything. Just keep the window open.
    - Case: The build finishes with a build error
        - If we're able to parse any build errors from the BEP, load them into the quickfix window.
            - The quickfix window should re-use window that was showing the Bazel output.

### Build window stickiness

- If the user swaps buffers in the build window, the window is no longer the build window.
    - Invoking the build will open a new build window for the tab.
