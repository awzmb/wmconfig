""""""" Plugin management stuff """""""
set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin('~/.config/nvim/bundle')

Plugin 'VundleVim/Vundle.vim'

" easymotion - allows <leader><leader>(b|e) to jump to (b)eginning or (end)
" of words.
Plugin 'easymotion/vim-easymotion'
" neomake build tool (mapped below to <c-b>)
Plugin 'benekastah/neomake'
" autocomplete for python
Plugin 'davidhalter/jedi-vim'
" remove extraneous whitespace when edit mode is exited
Plugin 'thirtythreeforty/lessspace.vim'

" latex editing
"plugin 'latex-box-team/latex-box'
"Plugin 'lervag/vimtex'
"Plugin 'donRaphaco/neotex', { 'for': 'tex' }

" status bar mods
Plugin 'itchyny/lightline.vim'
Plugin 'airblade/vim-gitgutter'

" tab completion
Plugin 'ervandew/supertab'

" cscope-maps
Plugin 'joe-skb7/cscope-maps'

" nerdtree navigation
Plugin 'scrooloose/nerdtree'

" commenting plugin
Plugin 'scrooloose/nerdcommenter'

" other stuff
Plugin 'infoslack/vim-docker'
Plugin 'pearofducks/ansible-vim'
Plugin 'jistr/vim-nerdtree-tabs'
Plugin 'arcticicestudio/nord-vim'

" after all plugins...
call vundle#end()
filetype plugin indent on

""""""" Jedi-VIM """""""
" Don't mess up undo history
let g:jedi#show_call_signatures = "0"

""""""" lightline configuration """""""
" change the lightline theme
let g:lightline = {
      \ 'colorscheme': 'nord',
      \ }
""""""" vim-autoformat configuration """""""
" start formatting with F3
noremap <F3> :Autoformat<CR>
""""""" NERDTree configuration """""""
" open NERDTree with Ctrl+n
map <C-n> :NERDTreeToggle<CR>


""""""" SuperTab configuration """""""
"let g:SuperTabDefaultCompletionType = "<c-x><c-u>"
function! Completefunc(findstart, base)
    return "\<c-x>\<c-p>"
endfunction

"call SuperTabChain(Completefunc, '<c-n>')
"let g:SuperTabCompletionContexts = ['g:ContextText2']

""""""" General coding stuff """""""
" Highlight 80th column
set colorcolumn=80
" Always show status bar
set laststatus=2
" Let plugins show effects after 500ms, not 4s
set updatetime=500
" Disable mouse click to go to position
set mouse-=a
" Don't let autocomplete affect usual typing habits
set completeopt=menuone,preview,noinsert
" Let vim-gitgutter do its thing on large files
let g:gitgutter_max_signs=10000

""""""" Python stuff """""""
syntax enable
set number showmatch
set shiftwidth=4 tabstop=4 softtabstop=4 expandtab autoindent
let python_highlight_all = 1


""""""" Keybindings """""""
" Set up leaders
let mapleader=","
let maplocalleader="\\"

" Neomake and other build commands (ctrl-b)
nnoremap <C-b> :w<cr>:Neomake<cr>

autocmd BufNewFile,BufRead *.tex,*.bib noremap <buffer> <C-b> :w<cr>:new<bar>r !make<cr>:setlocal buftype=nofile<cr>:setlocal bufhidden=hide<cr>:setlocal noswapfile<cr>
autocmd BufNewFile,BufRead *.tex,*.bib imap <buffer> <C-b> <Esc><C-b>

" nordic color scheme
colorscheme nord
