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

" terraform and hcl
Plugin 'hashivim/vim-terraform'

" status bar mods
Plugin 'itchyny/lightline.vim'
Plugin 'airblade/vim-gitgutter'

" coc language server client
Plugin 'neoclide/coc.nvim'

" cscope-maps
Plugin 'joe-skb7/cscope-maps'

" nerdtree navigation and git plugin
Plugin 'scrooloose/nerdtree'
"Plugin 'Xuyuanp/nerdtree-git-plugin'

" commenting plugin
Plugin 'scrooloose/nerdcommenter'

" show colors (hex, rgb, etc.)
"Plugin 'RRethy/vim-hexokinase', { 'do': 'make hexokinase' }
Plugin 'lilydjwg/colorizer'

" other stuff
Plugin 'infoslack/vim-docker'
Plugin 'pearofducks/ansible-vim'
Plugin 'arcticicestudio/nord-vim'

" finish plugin loading
call vundle#end()
filetype plugin indent on

" coc extensions
let g:coc_global_extensions = [
            \'coc-prettier',
            \'coc-json',
            \'coc-svg',
            \'coc-tslint',
            \'coc-tsserver',
            \'coc-yaml',
            \'coc-docker',
            \'coc-python',
            \'coc-gitignore'
            \]

" color scheme
colorscheme nord

""""""" jedi-vim """""""
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

""""""" nerdtree configuration """""""
" open nerdtree with ctrl+n
map <C-n> :NERDTreeToggle<CR>
" open nerdtree if no file was specified
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
" close vim automatically if nerdtree is the last open window
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
" close nerdtree after opening a file
let NERDTreeQuitOnOpen = 0
" automatically delete buffer when deleting a file with nerdtree
let NERDTreeAutoDeleteBuffer = 1
" show hidden files by default
let NERDTreeShowHidden=1

""""""" nerdtree git configuration """""""
" hide brackets around symbols
let g:NERDTreeGitStatusConcealBrackets = 1 " default: 0
" custom symbols
"let g:NERDTreeGitStatusIndicatorMapCustom = {
            "\ 'Modified'  :'✹',
            "\ 'Staged'    :'✚',
            "\ 'Untracked' :'✭',
            "\ 'Renamed'   :'➜',
            "\ 'Unmerged'  :'═',
            "\ 'Deleted'   :'✖',
            "\ 'Dirty'     :'✗',
            "\ 'Ignored'   :'☒',
            "\ 'Clean'     :'✔︎',
            "\ 'Unknown'   :'?',
            "\ }

""""""" coc configuration """""""
" textedit might fail if hidden is not set.
set hidden

" some servers have issues with backup files, see #649.
set nobackup
set nowritebackup

" give more space for displaying messages.
set cmdheight=2

" having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300

" don't pass messages to |ins-completion-menu|.
set shortmess+=c

" always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
if has("patch-8.1.1564")
  " recently vim can merge signcolumn and number column into one
  set signcolumn=number
else
  set signcolumn=yes
endif

" use tab for trigger completion with characters ahead and navigate.
" NOTE: use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif

" use <cr> to confirm completion, `<C-g>u` means break undo chain at current
" position. Coc only does snippet and additional edit on confirm.
" <cr> could be remapped by other vim plugin, try `:verbose imap <CR>`.
if exists('*complete_info')
  inoremap <expr> <cr> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"
else
  inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
endif

" Use `[g` and `]g` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" goto code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

" symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

" formatting selected code.
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder.
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" applying codeaction to the selected region.
" Example: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" remap keys for applying codeaction to the current buffer.
nmap <leader>ac  <Plug>(coc-codeaction)
" apply autofix to problem on the current line.
nmap <leader>qf  <Plug>(coc-fix-current)

" map function and class text objects
" NOTE: requires 'textDocument.documentSymbol' support from the language server.
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)

" use ctrl+s for selections ranges.
" Requires 'textDocument/selectionRange' support of LS, ex: coc-tsserver
nmap <silent> <C-s> <Plug>(coc-range-select)
xmap <silent> <C-s> <Plug>(coc-range-select)

" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocAction('format')

" Add `:Fold` command to fold current buffer.
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

" add (neo)vim's native statusline support.
" NOTE: Please see `:h coc-status` for integrations with external plugins that
" provide custom statusline: lightline.vim, vim-airline.
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

" mappings for coclist
" show all diagnostics.
nnoremap <silent><nowait> <space>a  :<C-u>CocList diagnostics<cr>
" manage extensions.
nnoremap <silent><nowait> <space>e  :<C-u>CocList extensions<cr>
" show commands.
nnoremap <silent><nowait> <space>c  :<C-u>CocList commands<cr>
" find symbol of current document.
nnoremap <silent><nowait> <space>o  :<C-u>CocList outline<cr>
" search workspace symbols.
nnoremap <silent><nowait> <space>s  :<C-u>CocList -I symbols<cr>
" do default action for next item.
nnoremap <silent><nowait> <space>j  :<C-u>CocNext<CR>
" do default action for previous item.
nnoremap <silent><nowait> <space>k  :<C-u>CocPrev<CR>
" resume latest coc list.
nnoremap <silent><nowait> <space>p  :<C-u>CocListResume<CR>


""""""" general coding stuff """""""
" highlight 80th column
set colorcolumn=80
" Always show status bar
set laststatus=2
" Let plugins show effects after 500ms, not 4s
set updatetime=500
" disable mouse click to go to position
set mouse-=a
" don't let autocomplete affect usual typing habits
set completeopt=menuone,preview,noinsert
" let vim-gitgutter do its thing on large files
let g:gitgutter_max_signs=10000
" set the undo directory and disable swap files
set undodir=~/.vim/undo//
set backupdir=~/.vim/backup//
set directory=~/.vim/swp//
set undofile
set backup
set swapfile
"set nobackup
"set noswapfile
" make tab two spaces
" remove multiple spaces on single backspace
set shiftwidth=2 tabstop=2 softtabstop=2 expandtab autoindent
" highlight current line
function s:SetCursorLine()
  set cursorline
  set nocursorcolumn
  hi cursorline cterm=none ctermbg=0 ctermfg=NONE
endfunction
autocmd VimEnter * call s:SetCursorLine()

""""""" python stuff """""""
syntax enable
set number showmatch
let python_highlight_all = 1


""""""" keybindings """""""
" set up leaders
let mapleader=","
let maplocalleader="\\"

" neomake and other build commands (ctrl-b)
nnoremap <C-b> :w<cr>:Neomake<cr>

autocmd BufNewFile,BufRead *.tex,*.bib noremap <buffer> <C-b> :w<cr>:new<bar>r !make<cr>:setlocal buftype=nofile<cr>:setlocal bufhidden=hide<cr>:setlocal noswapfile<cr>
autocmd BufNewFile,BufRead *.tex,*.bib imap <buffer> <C-b> <Esc><C-b>
