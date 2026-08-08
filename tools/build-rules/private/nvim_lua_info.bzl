# Partially modeled off of rules_js's JsInfo
NvimLuaInfo = provider(
    doc = "Information provided by the nvim_lua_* rules",
    fields = {
        "sources": "A depset of source files produced by the target",
    },
)
