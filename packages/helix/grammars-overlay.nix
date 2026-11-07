# Compile-time workarounds for specific tree-sitter grammars.  These quirks
# come from the upstream Helix / Steelix packaging in nixpkgs and mirror the
# same grammar set that the thdxg fork ships in its `languages.toml`.
#
# Regenerate together with `grammars.json` when bumping the fork rev:
#   nix-shell -p python3 nurl --run \
#     'python3 generate_grammars.py <path>/languages.toml -o grammars.json'
final: prev: {
  tree-sitter-agda = prev.tree-sitter-agda.override {
    excludeBrokenTreeSitterJson = false;
  };
  tree-sitter-beancount = prev.tree-sitter-beancount.override {
    excludeBrokenTreeSitterJson = false;
  };
  tree-sitter-git-rebase = prev.tree-sitter-git-rebase.overrideAttrs {
    dontPatch = true;
  };
  tree-sitter-glimmer = prev.tree-sitter-glimmer.override {
    excludeBrokenTreeSitterJson = false;
  };
  tree-sitter-janet-simple = prev.tree-sitter-janet-simple.override {
    excludeBrokenTreeSitterJson = false;
  };
  tree-sitter-qmljs = prev.tree-sitter-qmljs.overrideAttrs {
    dontCheckForBrokenSymlinks = true;
  };
  tree-sitter-sql = prev.tree-sitter-sql.override {
    generate = false;
  };
  tree-sitter-strace = prev.tree-sitter-strace.override {
    excludeBrokenTreeSitterJson = false;
  };
  tree-sitter-tact = prev.tree-sitter-tact.override {
    excludeBrokenTreeSitterJson = false;
  };
  tree-sitter-tlaplus = prev.tree-sitter-tlaplus.overrideAttrs {
    dontPatch = true;
  };
  tree-sitter-vue = prev.tree-sitter-vue.override {
    excludeBrokenTreeSitterJson = false;
  };
  tree-sitter-wit = prev.tree-sitter-wit.override {
    excludeBrokenTreeSitterJson = false;
  };
  tree-sitter-yuck = prev.tree-sitter-yuck.override {
    excludeBrokenTreeSitterJson = false;
  };
}