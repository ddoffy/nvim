let mapleader = "\<Space>"
filetype plugin on
filetype plugin indent on

autocmd BufEnter * :set scroll=10
syntax on

set encoding=UTF-8
set mouse=a

set incsearch 
set hlsearch

set tabstop=4
set softtabstop=0
set shiftwidth=4

set number
set relativenumber
set tabstop=4
set softtabstop=4
set shiftwidth=4
set smarttab
set expandtab
set autoindent
set list
set listchars=tab:▸\ ,trail:·
set clipboard=unnamedplus
set encoding=UTF-8

syntax on
filetype plugin on

colorscheme onedark
let g:lightline = {
    \ 'colorscheme': 'one'
    \ }



