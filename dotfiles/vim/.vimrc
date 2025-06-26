" enable line numbers
: set number

" enable position indicator (line/column)
: set ruler

" Highlight column 80 with dark grey
highlight ColorColumn ctermbg=darkgrey guibg=darkgrey
let &colorcolumn="80,".join(range(120,999),",")
