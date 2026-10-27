{
  lib,
  pkgs,
  cursor-plugins,
  ...
}:

let
  # Claude Code installs the generated harness tree, not pstack/ itself. Its
  # skills are rewritten for Claude Code and link to docs/harness/claude-code.md.
  pstack = "${cursor-plugins}/harness/pstack/claude-code";
  pstackVersion = (builtins.fromJSON (builtins.readFile "${pstack}/plugin.json")).version;
  pstackEntries = dir: lib.attrNames (builtins.readDir "${pstack}/${dir}");

  linkInto =
    target: source: names:
    lib.listToAttrs (
      map (n: {
        name = "${target}/${n}";
        value.source = "${source}/${n}";
      }) names
    );

  # Every pstack skill says to read the Claude Code adapter once per session.
  # The hook puts it in context at session start, and in the context of the two
  # pstack agents, so no skill has to read it. The preamble covers what the
  # adapter gets wrong for this install: the skills are user skills, not a
  # plugin, so nothing carries the `pstack:` prefix.
  pstack-context = pkgs.writeShellApplication {
    name = "pstack-context";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      context() {
        cat <<PREAMBLE
      # pstack in this install

      pstack ${pstackVersion} is installed from the cursor/plugins flake input of the dotfiles repository, as user skills and agents, not as a Claude Code plugin.

      - \`<pstack>\` is \`$HOME/.claude/pstack\`. Its \`skills/\` entries are linked into \`~/.claude/skills/\` and its \`agents/\` entries into \`~/.claude/agents/\`.
      - Names have no \`pstack:\` prefix. Where a skill or the adapter says \`/pstack:<name>\`, the command is \`/<name>\`. Where it says \`subagent_type: "pstack:poteto-agent"\` or \`"pstack:comment-sicko"\`, use \`"poteto-agent"\` or \`"comment-sicko"\`.
      - Give every \`poteto-agent\` brief the absolute path \`$HOME/.claude/pstack/skills/poteto-mode/SKILL.md\`. Do not search \`~/.claude/plugins/\` for it.
      - The model rule is \`~/.claude/rules/pstack-models.md\`. Claude Code loads it into every session.

      The Claude Code adapter follows. It counts as read for this session, so do not read it again.

      ---

      PREAMBLE
        cat "$HOME/.claude/pstack/docs/harness/claude-code.md"
      }

      case "''${1:-session}" in
        session) context ;;
        subagent)
          context | jq --raw-input --slurp '{
            hookSpecificOutput: { hookEventName: "SubagentStart", additionalContext: . }
          }'
          ;;
        *)
          echo "usage: pstack-context [session|subagent]" >&2
          exit 2
          ;;
      esac
    '';
  };

  hooks = {
    SessionStart = [
      {
        hooks = [
          {
            type = "command";
            command = "~/.claude/hooks/pstack-context session";
            timeout = 10;
          }
        ];
      }
    ];
    SubagentStart = [
      {
        matcher = "poteto-agent|comment-sicko";
        hooks = [
          {
            type = "command";
            command = "~/.claude/hooks/pstack-context subagent";
            timeout = 10;
          }
        ];
      }
    ];
  };
  hooksJson = pkgs.writeText "claude-hooks.json" (builtins.toJSON hooks);
in
{
  # Do not supplement the OS trust store with stale bundled roots.
  # https://github.com/NixOS/nixpkgs/pull/576509
  home.sessionVariables.CLAUDE_CODE_CERT_STORE = "system";

  # The instructions are inlined rather than kept in a repo-root CLAUDE.md, so
  # Claude Code does not also read them as project instructions for this repo.
  home.file = {
    "CLAUDE.md".text = ''
      Write all responses in ASD-STE100 Simplified Technical English.
    '';

    ".claude/hooks/pstack-context".source = "${pstack-context}/bin/pstack-context";

    # The whole tree at one stable path, the `<pstack>` of the adapter doc.
    ".claude/pstack".source = pstack;
  }
  // linkInto ".claude/skills" "${pstack}/skills" (pstackEntries "skills")
  // linkInto ".claude/agents" "${pstack}/agents" (pstackEntries "agents")
  # Skills link to ../../docs/harness/claude-code.md and ../../docs/guide/,
  # which resolve here when the path is simplified before the symlinks are.
  // linkInto ".claude/docs" "${pstack}/docs" (pstackEntries "docs");

  # Claude Code rewrites ~/.claude/settings.json itself (theme, model, tui), so
  # the file is not a store symlink. This step owns only its "hooks" key and
  # leaves every other key as Claude Code wrote it.
  home.activation.claudeHooks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings="$HOME/.claude/settings.json"
    merged="$(${pkgs.coreutils}/bin/mktemp)"
    if [ -e "$settings" ]; then
      ${lib.getExe pkgs.jq} --slurpfile hooks ${hooksJson} '.hooks = $hooks[0]' "$settings" > "$merged"
    else
      ${lib.getExe pkgs.jq} --null-input --slurpfile hooks ${hooksJson} '{ hooks: $hooks[0] }' > "$merged"
    fi
    if ! ${pkgs.diffutils}/bin/cmp --silent "$merged" "$settings" 2>/dev/null; then
      run ${pkgs.coreutils}/bin/install -m 644 "$merged" "$settings"
    fi
    rm -f "$merged"
  '';
}
