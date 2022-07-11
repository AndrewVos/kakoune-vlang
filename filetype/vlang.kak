# Detection
# ‾‾‾‾‾‾‾‾‾

hook global BufCreate .*[.](v) %{
    set-option buffer filetype vlang
}

# Initialization
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾

hook global WinSetOption filetype=(vlang) %{
    require-module vlang

    hook window ModeChange pop:insert:.* -group "%val{hook_param_capture_1}-trim-indent" vlang-trim-indent
    hook window InsertChar .* -group "%val{hook_param_capture_1}-indent" vlang-indent-on-char
    hook window InsertChar \n -group "%val{hook_param_capture_1}-insert" vlang-insert-on-new-line
    hook window InsertChar \n -group "%val{hook_param_capture_1}-indent" vlang-indent-on-new-line

    hook -once -always window WinSetOption filetype=.* "
        remove-hooks window %val{hook_param_capture_1}-.+
    "
}

hook global BufSetOption filetype=(vlang) %{
    set-option buffer comment_line '//'
    set-option buffer comment_block_begin '/*'
    set-option buffer comment_block_end '*/'
    set-option buffer formatcmd 'v fmt'
}

hook -group vlang-highlight global WinSetOption filetype=vlang %{
    add-highlighter window/vlang ref vlang
    hook -once -always window WinSetOption filetype=.* %{ remove-highlighter window/vlang }
}

provide-module vlang %§

# Commands
# ‾‾‾‾‾‾‾‾

define-command -hidden vlang-trim-indent %{
    # remove trailing white spaces
    try %{ execute-keys -draft -itersel <a-x> s \h+$ <ret> d }
}

define-command -hidden vlang-indent-on-char %<
    evaluate-commands -draft -itersel %<
        # align closer token to its opener when alone on a line
        try %/ execute-keys -draft <a-h> <a-k> ^\h+[\]}]$ <ret> m s \A|.\z <ret> 1<a-&> /
    >
>

define-command -hidden vlang-insert-on-new-line %<
    evaluate-commands -draft -itersel %<
        # copy // comments prefix and following white spaces
        try %{ execute-keys -draft k <a-x> s ^\h*\K/{2,}\h* <ret> y gh j P }
    >
>

define-command -hidden vlang-indent-on-new-line %<
    evaluate-commands -draft -itersel %<
        # preserve previous line indent
        try %{ execute-keys -draft <semicolon> K <a-&> }
        # filter previous line
        try %{ execute-keys -draft k : vlang-trim-indent <ret> }
        # indent after lines beginning / ending with opener token
        try %_ execute-keys -draft k <a-x> s [[({] <ret> <space> <a-l> <a-K> [\])}] <ret> j <a-gt> _
        # deindent closing token(s) when after cursor
        try %_ execute-keys -draft <a-x> <a-k> ^\h*[})\]] <ret> gh / [})\]] <ret> m <a-S> 1<a-&> _
    >
>

# Highlighters
# ‾‾‾‾‾‾‾‾‾‾‾‾

add-highlighter "shared/vlang" regions
add-highlighter "shared/vlang/code" default-region group
add-highlighter "shared/vlang/double_string" region '"'  (?<!\\)(\\\\)*"         fill string
add-highlighter "shared/vlang/single_string" region "'"  (?<!\\)(\\\\)*'         fill string
add-highlighter "shared/vlang/literal"       region "`"  (?<!\\)(\\\\)*`         group
add-highlighter "shared/vlang/comment_line"  region //   '$'                     fill comment
add-highlighter "shared/vlang/comment"       region /\*  \*/                     fill comment
add-highlighter "shared/vlang/shebang"       region ^#!  $                       fill meta

add-highlighter "shared/vlang/literal/"       fill string
add-highlighter "shared/vlang/literal/"       regex \$\{.*?\} 0:value

add-highlighter "shared/vlang/code/" regex (?:^|[^$_])\b(document|false|null|parent|self|this|true|undefined|window)\b 1:value
add-highlighter "shared/vlang/code/" regex "-?\b[0-9]*\.?[0-9]+" 0:value

# https://github.com/vlang/v/blob/master/doc/docs.md#appendix-i-keywords
add-highlighter "shared/vlang/code/" regex \b(as|asm|assert|atomic|break|const|continue|defer|else|embed|enum|false|fn|for|go|goto|if|import|in|interface|is|lock|match|module|mut|none|or|pub|return|rlock|select|shared|sizeof|static|struct|true|type|typeof|union|unsafe|volatile|__offsetof)\b 0:keyword

# https://github.com/vlang/v/blob/master/doc/docs.md#v-types
add-highlighter shared/vlang/code/ regex \b(bool|string|i8|i16|int|i64|i128|u8|u16|u32|u64|u128|rune|f32|f64|isize|usize|voidptr|any)\b 0:type

§
