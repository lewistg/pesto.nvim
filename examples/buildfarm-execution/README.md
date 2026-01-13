# README

This directory is root for a simple C project.
It's used to demo pesto.nvim's capabilities when working with a remote cache.
The project was set up to work with [Buildfarm][1] and it's remote execution capabilities.

## Quick start

These instructions assumes you've installed pesto.nvim already.

1. Check the .bazelrc file in this directory.
You should see just a single config line:
```bash
build --remote_executor=grpc://localhost:8980
```
This line configures bazel to use a remote executor running locally on port 8980.

2. To get the remote executor up and running, you'll need to follow Buildfarm's own "quick start" page [here][2].
At the time of writing, there's a section called ["Remote Execution (and caching)"][3].
If you follow their guide up to that point, you should have the remote executor up and running, listening on port 8980.

3. Now open `src/main.c` with Neovim and invoke a build:
```viml
:Pesto bazel build //src:main
```
The build should complete without error.

4. Now let's demo the quickfix integration. 
Open `src/digit_num.c` and add some type of syntax error.
Now invoke the build again:
```viml
:Pesto bazel build //src:main
```
Now that there are errors the quickfix window should populate this time.

## Buildfarm setup

[1]: https://github.com/buildfarm/buildfarm
[2]: https://buildfarm.github.io/buildfarm/docs/quick_start/#quick-start
[3]: https://buildfarm.github.io/buildfarm/docs/quick_start/#remote-execution-and-caching
