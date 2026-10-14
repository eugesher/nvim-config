local icons = require("settings.icons")

local glyphs = icons.markdown

local M = {}

M.ft = { "markdown" }

M.keys = {
  { "<leader>um", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle markdown rendering" },
}

local function padded(list)
  return vim.tbl_map(function(glyph)
    return glyph .. " "
  end, list)
end

local function callout(name, raw, title, highlight, category)
  return {
    raw = raw,
    rendered = glyphs.callouts[name] .. " " .. title,
    highlight = highlight,
    category = category,
  }
end

local function site(name, pattern, kind)
  return { icon = glyphs.sites[name] .. " ", pattern = pattern, kind = kind }
end

M.opts = {
  enabled = true,
  render_modes = { "n", "c", "t" },
  debounce = 100,
  preset = "none",
  log_level = "error",
  log_runtime = false,
  file_types = { "markdown" },
  max_file_size = 10.0,
  ignore = function()
    return false
  end,
  nested = true,
  change_events = {},
  restart_highlighter = false,
  injections = {
    gitcommit = {
      enabled = true,
      query = [[
            ((message) @injection.content
                (#set! injection.combined)
                (#set! injection.include-children)
                (#set! injection.language "markdown"))
        ]],
    },
  },
  patterns = {
    markdown = {
      disable = true,
      directives = {
        { id = 17, name = "conceal_lines" },
        { id = 18, name = "conceal_lines" },
      },
    },
  },
  anti_conceal = {
    enabled = true,
    disabled_modes = false,
    above = 0,
    below = 0,
    ignore = {
      code_background = true,
      indent = true,
      sign = true,
      virtual_lines = true,
    },
  },
  padding = {
    highlight = "RenderMarkdownPadding",
  },
  latex = {
    enabled = false,
    render_modes = false,
    converter = { "utftex", "latex2text" },
    inline = true,
    block = true,
    highlight = "RenderMarkdownMath",
    position = "center",
    top_pad = 0,
    bottom_pad = 0,
  },
  on = {
    attach = function() end,
    initial = function() end,
    render = function() end,
    clear = function() end,
  },
  completions = {
    blink = { enabled = false },
    coq = { enabled = false },
    lsp = { enabled = false },
    filter = {
      callout = function()
        return true
      end,
      checkbox = function()
        return true
      end,
    },
  },
  heading = {
    enabled = true,
    render_modes = false,
    atx = true,
    setext = true,
    sign = true,
    icons = padded(glyphs.headings),
    position = "overlay",
    signs = { glyphs.heading_sign .. " " },
    width = "full",
    left_margin = 0,
    left_pad = 0,
    right_pad = 0,
    min_width = 0,
    border = false,
    border_virtual = false,
    border_prefix = false,
    above = "▄",
    below = "▀",
    backgrounds = {
      "RenderMarkdownH1Bg",
      "RenderMarkdownH2Bg",
      "RenderMarkdownH3Bg",
      "RenderMarkdownH4Bg",
      "RenderMarkdownH5Bg",
      "RenderMarkdownH6Bg",
    },
    foregrounds = {
      "RenderMarkdownH1",
      "RenderMarkdownH2",
      "RenderMarkdownH3",
      "RenderMarkdownH4",
      "RenderMarkdownH5",
      "RenderMarkdownH6",
    },
    custom = {},
  },
  paragraph = {
    enabled = true,
    render_modes = false,
    left_margin = 0,
    indent = 0,
    min_width = 0,
  },
  code = {
    enabled = true,
    render_modes = false,
    sign = true,
    conceal_delimiters = true,
    language = true,
    position = "left",
    language_icon = true,
    language_name = true,
    language_info = true,
    language_pad = 0,
    disable = {},
    disable_background = { "diff" },
    background_inset = 1,
    width = "full",
    left_margin = 0,
    left_pad = 0,
    right_pad = 0,
    min_width = 0,
    border = "hide",
    language_border = "█",
    language_left = "",
    language_right = "",
    above = "▄",
    below = "▀",
    inline = true,
    inline_left = "",
    inline_right = "",
    inline_pad = 0,
    priority = 140,
    highlight = "RenderMarkdownCode",
    highlight_info = "RenderMarkdownCodeInfo",
    highlight_language = nil,
    highlight_border = "RenderMarkdownCodeBorder",
    highlight_fallback = "RenderMarkdownCodeFallback",
    highlight_inline = "RenderMarkdownCodeInline",
    highlight_inline_left = nil,
    highlight_inline_right = nil,
    style = "full",
  },
  dash = {
    enabled = true,
    render_modes = false,
    icon = "─",
    width = "full",
    left_margin = 0,
    priority = nil,
    highlight = "RenderMarkdownDash",
  },
  document = {
    enabled = true,
    render_modes = false,
    conceal = {
      char_patterns = {},
      line_patterns = {},
    },
  },
  bullet = {
    enabled = true,
    render_modes = false,
    icons = glyphs.bullets,
    ordered_icons = function(ctx)
      local value = vim.trim(ctx.value)
      local index = tonumber(value:sub(1, #value - 1)) or 0
      return ("%d."):format(index > 1 and index or ctx.index)
    end,
    left_pad = 0,
    right_pad = 0,
    highlight = "RenderMarkdownBullet",
    scope_highlight = {},
    scope_priority = nil,
  },
  checkbox = {
    enabled = true,
    render_modes = false,
    bullet = false,
    left_pad = 0,
    right_pad = 1,
    unchecked = {
      icon = glyphs.unchecked .. " ",
      highlight = "RenderMarkdownUnchecked",
      scope_highlight = nil,
    },
    checked = {
      icon = glyphs.checked .. " ",
      highlight = "RenderMarkdownChecked",
      scope_highlight = nil,
    },
    custom = {
      todo = {
        raw = "[-]",
        rendered = glyphs.todo .. " ",
        highlight = "RenderMarkdownTodo",
        scope_highlight = nil,
      },
    },
    scope_priority = nil,
  },
  quote = {
    enabled = true,
    render_modes = false,
    icon = glyphs.quote,
    repeat_linebreak = false,
    highlight = {
      "RenderMarkdownQuote1",
      "RenderMarkdownQuote2",
      "RenderMarkdownQuote3",
      "RenderMarkdownQuote4",
      "RenderMarkdownQuote5",
      "RenderMarkdownQuote6",
    },
  },
  render = {
    diff = false,
  },
  pipe_table = {
    enabled = true,
    render_modes = false,
    preset = "none",
    cell = "padded",
    wrap = true,
    cell_offset = function()
      return 0
    end,
    padding = 1,
    min_width = 0,
    border = { "┌", "┬", "┐", "├", "┼", "┤", "└", "┴", "┘", "│", "─" },
    border_enabled = true,
    border_virtual = false,
    alignment_indicator = "━",
    head = "RenderMarkdownTableHead",
    row = "RenderMarkdownTableRow",
    style = "full",
  },
  callout = {
    note = callout("note", "[!NOTE]", "Note", "RenderMarkdownInfo", "github"),
    tip = callout("tip", "[!TIP]", "Tip", "RenderMarkdownSuccess", "github"),
    important = callout("important", "[!IMPORTANT]", "Important", "RenderMarkdownHint", "github"),
    warning = callout("warning", "[!WARNING]", "Warning", "RenderMarkdownWarn", "github"),
    caution = callout("caution", "[!CAUTION]", "Caution", "RenderMarkdownError", "github"),
    abstract = callout("abstract", "[!ABSTRACT]", "Abstract", "RenderMarkdownInfo", "obsidian"),
    summary = callout("abstract", "[!SUMMARY]", "Summary", "RenderMarkdownInfo", "obsidian"),
    tldr = callout("abstract", "[!TLDR]", "Tldr", "RenderMarkdownInfo", "obsidian"),
    info = callout("info", "[!INFO]", "Info", "RenderMarkdownInfo", "obsidian"),
    todo = callout("todo", "[!TODO]", "Todo", "RenderMarkdownInfo", "obsidian"),
    hint = callout("tip", "[!HINT]", "Hint", "RenderMarkdownSuccess", "obsidian"),
    success = callout("success", "[!SUCCESS]", "Success", "RenderMarkdownSuccess", "obsidian"),
    check = callout("success", "[!CHECK]", "Check", "RenderMarkdownSuccess", "obsidian"),
    done = callout("success", "[!DONE]", "Done", "RenderMarkdownSuccess", "obsidian"),
    question = callout("question", "[!QUESTION]", "Question", "RenderMarkdownWarn", "obsidian"),
    help = callout("question", "[!HELP]", "Help", "RenderMarkdownWarn", "obsidian"),
    faq = callout("question", "[!FAQ]", "Faq", "RenderMarkdownWarn", "obsidian"),
    attention = callout("warning", "[!ATTENTION]", "Attention", "RenderMarkdownWarn", "obsidian"),
    failure = callout("failure", "[!FAILURE]", "Failure", "RenderMarkdownError", "obsidian"),
    fail = callout("failure", "[!FAIL]", "Fail", "RenderMarkdownError", "obsidian"),
    missing = callout("failure", "[!MISSING]", "Missing", "RenderMarkdownError", "obsidian"),
    danger = callout("danger", "[!DANGER]", "Danger", "RenderMarkdownError", "obsidian"),
    error = callout("danger", "[!ERROR]", "Error", "RenderMarkdownError", "obsidian"),
    bug = callout("bug", "[!BUG]", "Bug", "RenderMarkdownError", "obsidian"),
    example = callout("example", "[!EXAMPLE]", "Example", "RenderMarkdownHint", "obsidian"),
    quote = callout("quote", "[!QUOTE]", "Quote", "RenderMarkdownQuote", "obsidian"),
    cite = callout("quote", "[!CITE]", "Cite", "RenderMarkdownQuote", "obsidian"),
  },
  link = {
    enabled = true,
    render_modes = false,
    footnote = {
      enabled = true,
      icon = glyphs.footnote .. " ",
      body = function(ctx)
        return ctx.text
      end,
      superscript = true,
      prefix = "",
      suffix = "",
    },
    image = glyphs.image .. " ",
    image_custom = true,
    email = glyphs.email .. " ",
    hyperlink = glyphs.hyperlink .. " ",
    highlight = "RenderMarkdownLink",
    highlight_title = "RenderMarkdownLinkTitle",
    wiki = {
      enabled = true,
      icon = glyphs.wiki .. " ",
      conceal_destination = true,
      body = function()
        return nil
      end,
      highlight = "RenderMarkdownWikiLink",
      scope_highlight = nil,
    },
    custom = {
      web = site("web", "^http"),
      apple = site("apple", "apple%.com", "url"),
      discord = site("discord", "discord%.com", "url"),
      github = site("github", "github%.com", "url"),
      gitlab = site("gitlab", "gitlab%.com", "url"),
      google = site("google", "google%.com", "url"),
      hackernews = site("hackernews", "ycombinator%.com", "url"),
      linkedin = site("linkedin", "linkedin%.com", "url"),
      microsoft = site("microsoft", "microsoft%.com", "url"),
      neovim = site("neovim", "neovim%.io", "url"),
      reddit = site("reddit", "reddit%.com", "url"),
      slack = site("slack", "slack%.com", "url"),
      stackoverflow = site("stackoverflow", "stackoverflow%.com", "url"),
      steam = site("steam", "steampowered%.com", "url"),
      twitter = site("twitter", "twitter%.com", "url"),
      wikipedia = site("wikipedia", "wikipedia%.org", "url"),
      x = site("x", "x%.com", "url"),
      youtube = site("youtube", "youtube[^.]*%.com", "url"),
      youtube_short = site("youtube", "youtu%.be", "url"),
    },
  },
  sign = {
    enabled = true,
    priority = nil,
    highlight = "RenderMarkdownSign",
  },
  inline_highlight = {
    enabled = true,
    render_modes = false,
    highlight = "RenderMarkdownInlineHighlight",
    custom = {},
  },
  indent = {
    enabled = false,
    render_modes = false,
    per_level = 2,
    skip_level = 1,
    skip_heading = false,
    icon = glyphs.indent,
    priority = 0,
    highlight = "RenderMarkdownIndent",
  },
  html = {
    enabled = true,
    render_modes = false,
    comment = {
      conceal = true,
      text = nil,
      highlight = "RenderMarkdownHtmlComment",
    },
    tag = {},
  },
  win_options = {
    conceallevel = {
      default = vim.o.conceallevel,
      rendered = 3,
    },
    concealcursor = {
      default = vim.o.concealcursor,
      rendered = "",
    },
  },
  overrides = {
    buflisted = {},
    buftype = {
      nofile = {
        render_modes = true,
        sign = { enabled = false },
      },
    },
    filetype = {},
    preview = {
      render_modes = true,
    },
  },
  custom_handlers = {},
  yaml = {
    enabled = true,
    render_modes = false,
  },
}

return M
