NvimPluginInfo = provider(
    doc = "Information provided by the nvim_plugin rule",
    fields = {
        "lua": "A depset of source files for the plugin",
        "support_files": "A depset of miscellaneous support files"
    },
)
