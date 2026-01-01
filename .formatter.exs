[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  plugins: [
    FreedomFormatter,
    Phoenix.LiveView.HTMLFormatter,
  ],
  line_length: 100,
  heex_line_length: 90,
  trailing_comma: true,
  # NEVER set this to true
  force_do_end_blocks: false,
  migrate_call_parens_on_pipe: true,
  migrate_bitstring_modifiers: true,
  migrate_charlists_as_sigils: true,
  single_clause_on_do: false,
]
