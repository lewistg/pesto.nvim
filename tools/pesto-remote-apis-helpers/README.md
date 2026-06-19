# pesto.nvim remote APIs helpers

This directory contains helper scripts for working with [Bazel's remote APIs][1].
At the moment there is only one helper script, `pesto-fetch-bytestreams`, which is described further on.

## FAQ

### Why?

The Bazel remote APIs are gRPC-based.
Instead of implementing a gRPC client in Lua from scratch, pesto.nvim optionally delegates gRPC concerns to scripts in this directory.

The scripts are written in Python and invoked using `uv`. Python has firstclass support for writing gRPC clients, and `uv` eases the burden of managing dependencies and the virtual environment. (No additional setup is required on your part other than making sure `uv` is available.)

### Are these scripts necessary? 

No, you don't have to use these scripts.
Try using `pty_output` for `quickfix_log_source` (`:help pesto.Settings.quickfix_log_source`).
It may work well enough, and Pesto won't use this helper script at all.

Pesto also won't use these scripts unless they've been set up using the Pesto's `install-remote-apis-helpers` command.

Support for custom bytestream clients is not supported yet; if you need this, please open a feature request.

## Requirements

The scripts in this directory depend on [`uv`][2].

## `pesto-fetch-bytestreams`

The `pesto-fetch-bytestreams` command takes as input Byte Stream URIs (the kind found in BEP log files).
As output `pesto-fetch-bytestreams` writes `google.byestream.ReadResponse`s to stdout.

After a build finishes, pesto.nvim can process the Build Event Protocol (BEP) log to do things like populate the quickfix list.
When a remote cache is involved, BEP will refer to log files by "bytestream" URLs.
Here is an example of one such URL:
```
bytestream://localhost:8980/blobs/477b2a3983637d7633933691800642a388a38e1dd81ebe12304a603dc3b3dfba/226
```
The remote cache service that serves these URLs implements the [Byte Stream gRPC service][3].

Implementing a gRPC client directly in Lua using Neovim's provided libraries seemed like more effort than its worth.
Instead this helper Python CLI tool is provided, which pesto.nvim integrates with.

[1]: https://github.com/bazelbuild/remote-apis
[2]: https://docs.astral.sh/uv/
[3]: https://github.com/googleapis/googleapis/blob/347b0e45a6ec42e183e44ce11e0cb0eaf7f24caa/google/bytestream/bytestream.proto
