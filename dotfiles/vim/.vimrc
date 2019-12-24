set number
set tabstop=8 softtabstop=0 expandtab shiftwidth=4 smarttab

highlight OverLength ctermbg=red ctermfg=white guibg=#592929
match OverLength /\%81v.\+/

call plug#begin('~/.vim/plugged')

Plug 'avakhov/vim-yaml'

call plug#end()
