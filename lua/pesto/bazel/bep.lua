local M = {}

-- Types based on protobuf defintions from the official bazel repo [1].
-- [1]: https://github.com/bazelbuild/bazel/blob/7.1.0/src/main/java/com/google/devtools/build/lib/buildeventstream/proto/build_event_stream.proto

---@class BuildEventId

---@class BuildEvent
---@field id BuildEventId
