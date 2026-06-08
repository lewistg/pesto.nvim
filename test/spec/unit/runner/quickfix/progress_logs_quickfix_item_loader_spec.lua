describe('pesto.ProgressLogsQuickfixItemLoader._strip_extra_lines', function()
  it('strips out "extra" lines that are unlikely to be part of the action\'s output', function()
    local lines = {
      'Use --sandbox_debug to see verbose messages from the sandbox and retain the sandbox build root for debugging',
      'src/main/java/net/starlark/java/syntax/LambdaExpression.java:43: error: could not resolve xpression',
      '  public xpression getBody() {',
      '         ^',
      '    }',
      '',
      'Use --sandbox_debug to see verbose messages from the sandbox and retain the sandbox build root for debugging',
      '',
    }
    local ProgressLogsQuickfixItemLoader =
      require('pesto.runner.quickfix.progress_logs_quickfix_item_loader')
    local stripped_lines = ProgressLogsQuickfixItemLoader._strip_extra_lines(lines)
    local expected_stripped_lines = {
      'src/main/java/net/starlark/java/syntax/LambdaExpression.java:43: error: could not resolve xpression',
      '  public xpression getBody() {',
      '         ^',
      '    }',
    }
    assert.are.same(expected_stripped_lines, stripped_lines)
  end)
end)

describe('pesto.ProgressLogsQuickfixItemLoader.parse_no_curses_bazel_stdout', function()
  it('finds the failed action output', function()
    -- Output generated from the bazel repo using the following command
    -- ```
    -- bazel build \
    --   //src/main/java/com/google/devtools/build/docgen:docgen_bin \
    --   //src/main/java/net/starlark/java/syntax \
    --   --keep_going \
    --   --curses=no
    -- ```
    local bazel_ouptut = [[Computing main repo mapping:
Loading:
Loading: 0 packages loaded
Analyzing: 2 targets (0 packages loaded, 0 targets configured)                                                                                                                                                                                                                          Analyzing: 2 targets (0 packages loaded, 0 targets configured)                                                                                                                                                                                                                          
INFO: Analyzed 2 targets (0 packages loaded, 0 targets configured).
ERROR: /home/user/dev/bazel/src/main/java/net/starlark/java/syntax/BUILD:17:13: Compiling Java headers src/main/java/net/starlark/java/syntax/libsyntax-hjar.jar (42 source files) failed: (Exit 1): turbine_direct_graal failed: error executing Turbine command (from target //src/main/java/net/starlark/java/syntax:syntax) external/rules_java++toolchains+remote_java_tools_linux/java_tools/turbine_direct_graal '-Dturbine.ctSymPath=external/rules_java++toolchains+remotejdk21_linux/lib/ct.sym' --output ... (remaining 79 arguments skipped)

Use --sandbox_debug to see verbose messages from the sandbox and retain the sandbox build root for debugging
src/main/java/net/starlark/java/syntax/LambdaExpression.java:43: error: could not resolve xpression
  public xpression getBody() {
         ^
ERROR: /home/user/dev/bazel/src/main/java/net/starlark/java/syntax/BUILD:17:13: Compiling Java headers src/main/java/net/starlark/java/syntax/libsyntax-hjar.jar (42 source files) [for tool] failed: (Exit 1): turbine_direct_graal failed: error executing Turbine command (from target //src/main/java/net/starlark/java/syntax:syntax) external/rules_java++toolchains+remote_java_tools_linux/java_tools/turbine_direct_graal '-Dturbine.ctSymPath=external/rules_java++toolchains+remotejdk21_linux/lib/ct.sym' --output ... (remaining 79 arguments skipped)

Use --sandbox_debug to see verbose messages from the sandbox and retain the sandbox build root for debugging
src/main/java/net/starlark/java/syntax/LambdaExpression.java:43: error: could not resolve xpression
  public xpression getBody() {
         ^
ERROR: /home/user/dev/bazel/src/main/java/net/starlark/java/syntax/BUILD:17:13: Building src/main/java/net/starlark/java/syntax/libsyntax.jar (42 source files) and running annotation processors (AutoAnnotationProcessor, AutoBuilderProcessor, AutoOneOfProcessor, AutoValueProcessor,AutoValueGsonAdapterFactoryProcessor) failed: (Exit 1): java failed: error executing Javac command (from target //src/main/java/net/starlark/java/syntax:syntax) external/rules_java++toolchains+remotejdk21_linux/bin/java '--add-exports=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED' '--add-exports=jdk.compiler/com.sun.tools.javac.main=ALL-UNNAMED' ... (remaining 19 arguments skipped)
src/main/java/net/starlark/java/syntax/LambdaExpression.java:43: error: cannot find symbol
  public xpression getBody() {
         ^
  symbol:   class xpression
  location: class LambdaExpression
ERROR: /home/user/dev/bazel/src/main/java/net/starlark/java/syntax/BUILD:17:13: Building src/main/java/net/starlark/java/syntax/libsyntax.jar (42 source files) and running annotation processors (AutoAnnotationProcessor, AutoBuilderProcessor, AutoOneOfProcessor, AutoValueProcessor,AutoValueGsonAdapterFactoryProcessor) [for tool] failed: (Exit 1): java failed: error executing Javac command (from target //src/main/java/net/starlark/java/syntax:syntax) external/rules_java++toolchains+remotejdk21_linux/bin/java '--add-exports=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED' '--add-exports=jdk.compiler/com.sun.tools.javac.main=ALL-UNNAMED' ... (remaining 19 arguments skipped)
src/main/java/net/starlark/java/syntax/LambdaExpression.java:43: error: cannot find symbol
  public xpression getBody() {
         ^
  symbol:   class xpression
  location: class LambdaExpression
ERROR: /home/user/dev/bazel/src/main/java/com/google/devtools/common/options/BUILD:42:13: Building src/main/java/com/google/devtools/common/options/liboptions_internal.jar (38 source files) and running annotation processors (AutoAnnotationProcessor, AutoBuilderProcessor, AutoOneOfProcessor, AutoValueProcessor, AutoValueGsonAdapterFactoryProcessor) [for tool] failed: (Exit 1): java failed: error executing Javac command (from target //src/main/java/com/google/devtools/common/options:options_internal) external/rules_java++toolchains+remotejdk21_linux/bin/java '--add-exports=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED' '--add-exports=jdk.compiler/com.sun.tools.javac.main=ALL-UNNAMED' ... (remaining 19 arguments skipped)
src/main/java/com/google/devtools/common/options/Converters.java:48: error: cannot find symbol
      mmutableSet.of("false", "0", "no", "f", "n");
      ^
  symbol:   variable mmutableSet
  location: class Converters
ERROR: /home/user/dev/bazel/src/main/java/com/google/devtools/common/options/BUILD:42:13: Building src/main/java/com/google/devtools/common/options/liboptions_internal.jar (38 source files) and running annotation processors (AutoAnnotationProcessor, AutoBuilderProcessor, AutoOneOfProcessor, AutoValueProcessor, AutoValueGsonAdapterFactoryProcessor) failed: (Exit 1): java failed: error executing Javac command (from target //src/main/java/com/google/devtools/common/options:options_internal) external/rules_java++toolchains+remotejdk21_linux/bin/java '--add-exports=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED' '--add-exports=jdk.compiler/com.sun.tools.javac.main=ALL-UNNAMED' ... (remaining 19 arguments skipped)
src/main/java/com/google/devtools/common/options/Converters.java:48: error: cannot find symbol
      mmutableSet.of("false", "0", "no", "f", "n");
      ^
  symbol:   variable mmutableSet
  location: class Converters
INFO: Found 2 targets...
Use --verbose_failures to see the command lines of failed build steps.
INFO: Elapsed time: 0.737s, Critical Path: 0.57s
INFO: 7 processes: 7 internal.
ERROR: Build did NOT complete successfully]]

    local ProgressLogsQuickfixItemLoader =
      require('pesto.runner.quickfix.progress_logs_quickfix_item_loader')
    local action_logs =
      ProgressLogsQuickfixItemLoader.parse_no_curses_bazel_stdout(vim.split(bazel_ouptut, '\n'))

    ---@type {action_mnemonic: string, stdout_lines: string[]}[] failed_action_lines
    local expected_action_logs = {
      {
        action_mnemonic = 'Turbine',
        stdout_lines = {
          'src/main/java/net/starlark/java/syntax/LambdaExpression.java:43: error: could not resolve xpression',
          '  public xpression getBody() {',
          '         ^',
        },
      },
      {
        action_mnemonic = 'Turbine',
        stdout_lines = {
          'src/main/java/net/starlark/java/syntax/LambdaExpression.java:43: error: could not resolve xpression',
          '  public xpression getBody() {',
          '         ^',
        },
      },
      {
        action_mnemonic = 'Javac',
        stdout_lines = {
          'src/main/java/net/starlark/java/syntax/LambdaExpression.java:43: error: cannot find symbol',
          '  public xpression getBody() {',
          '         ^',
          '  symbol:   class xpression',
          '  location: class LambdaExpression',
        },
      },
      {
        action_mnemonic = 'Javac',
        stdout_lines = {
          'src/main/java/net/starlark/java/syntax/LambdaExpression.java:43: error: cannot find symbol',
          '  public xpression getBody() {',
          '         ^',
          '  symbol:   class xpression',
          '  location: class LambdaExpression',
        },
      },
      {
        action_mnemonic = 'Javac',
        stdout_lines = {
          'src/main/java/com/google/devtools/common/options/Converters.java:48: error: cannot find symbol',
          '      mmutableSet.of("false", "0", "no", "f", "n");',
          '      ^',
          '  symbol:   variable mmutableSet',
          '  location: class Converters',
        },
      },
      {
        action_mnemonic = 'Javac',
        stdout_lines = {
          'src/main/java/com/google/devtools/common/options/Converters.java:48: error: cannot find symbol',
          '      mmutableSet.of("false", "0", "no", "f", "n");',
          '      ^',
          '  symbol:   variable mmutableSet',
          '  location: class Converters',
        },
      },
    }
    assert.are.same(expected_action_logs, action_logs)
  end)
end)
