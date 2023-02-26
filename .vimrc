""""""" Plugin management stuff """""""
set nocompatible
filetype off

call plug#begin('~/.vim/plugged')

" neomake build tool (mapped below to <c-b>)
Plug 'benekastah/neomake'
" autocomplete for python
"Plug 'davidhalter/jedi-vim'
" remove extraneous whitespace when edit mode is exited
Plug 'thirtythreeforty/lessspace.vim'

" latex editing
"plugin 'latex-box-team/latex-box'
"Plug 'lervag/vimtex'
"Plug 'donRaphaco/neotex', { 'for': 'tex' }

" terraform and hcl
Plug 'hashivim/vim-terraform'

" status bar mods
"Plug 'itchyny/lightline.vim'
Plug 'vim-airline/vim-airline'
"Plug 'vim-airline/vim-airline-themes'
Plug 'airblade/vim-gitgutter'

" coc language server client
Plug 'neoclide/coc.nvim'

" git commit browser (start with :GV)
Plug 'tpope/vim-fugitive'
Plug 'junegunn/gv.vim'

" fzf plugin
Plug 'junegunn/fzf'

" cscope-maps
Plug 'joe-skb7/cscope-maps'

" nerdtree navigation and git plugin
Plug 'scrooloose/nerdtree'

" fern tree / project navigation (nerdtree replacement)
"Plug 'antoinemadec/FixCursorHold.nvim'
"Plug 'lambdalisue/fern.vim'

" commenting plugin
Plug 'scrooloose/nerdcommenter'

" show colors (hex, rgb, etc.)
"Plug 'RRethy/vim-hexokinase', { 'do': 'make hexokinase' }
Plug 'lilydjwg/colorizer'

" automated closing, paranthesis, brackets, quotes
Plug 'KaraMCC/vim-gemini'

" edit helm templates
Plug 'towolf/vim-helm'

" syntax
Plug 'martinda/Jenkinsfile-vim-syntax'

" other stuff
Plug 'infoslack/vim-docker'
Plug 'pearofducks/ansible-vim'

" colorscheme
Plug 'arcticicestudio/nord-vim'
"Plug 'chriskempson/base16-vim'

" finish plugin loading
" Initialize plugin system
" - Automatically executes `filetype plugin indent on` and `syntax enable`.
call plug#end()

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
            \'coc-go',
            \'coc-groovy',
            \'coc-java',
            \'coc-gitignore'
            \]

""""""" colorscheme """""""
"set termguicolors
syntax on
colorscheme nord

""""""" jedi-vim """""""
" Don't mess up undo history
let g:jedi#show_call_signatures = "0"

""""""" vim-autoformat configuration """""""
" start formatting with F3
noremap <F3> :Autoformat<CR>

""""""" fern configuration """""""
" open fern as drawer in current working directory with ctrl+n
"map <C-n> :Fern . -drawer -toggle -reveal=%<CR>
"" initialize options for fern (options visible by hitting ? in fern buffer)
"function! s:init_fern() abort
  "" Use 'select' instead of 'edit' for default 'open' action
  "nmap <buffer> <Plug>(fern-action-open) <Plug>(fern-action-open:select)
  "nmap <buffer> <Plug>(fern-action-hidden) <Plug>(fern-action-hidden:set)
"endfunction

"augroup fern-custom
  "autocmd! *
  "autocmd FileType fern call s:init_fern()
"augroup END

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
" change default arrows
let g:NERDTreeDirArrowExpandable = '+'
let g:NERDTreeDirArrowCollapsible = '-'

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
xmap <leader>a <Plug>(coc-codeaction-selected)
nmap <leader>a <Plug>(coc-codeaction-selected)

" remap keys for applying codeaction to the current buffer.
nmap <leader>ac <Plug>(coc-codeaction)
" apply autofix to problem on the current line.
nmap <leader>qf <Plug>(coc-fix-current)

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
command! -nargs=? Fold :call CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR :call CocAction('runCommand', 'editor.action.organizeImport')

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
  hi CursorLine cterm=none ctermbg=0 ctermfg=none
endfunction
autocmd VimEnter * call s:SetCursorLine()
autocmd BufNew * call s:SetCursorLine()

""""""" python stuff """""""
syntax enable
set number showmatch
let python_highlight_all = 1

""""""" fzf options """""""
" open fzf with ctrl+o
map <C-o> :FZF<CR>
" this is the default extra key bindings
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }
" Default fzf layout
" - down / up / left / right
let g:fzf_layout = { 'down': '40%' }
" You can set up fzf window using a Vim command (Neovim or latest Vim 8 required)
"let g:fzf_layout = { 'window': 'enew' }
"let g:fzf_layout = { 'window': '-tabnew' }
"let g:fzf_layout = { 'window': '10new' }
" Customize fzf colors to match your color scheme
" - fzf#wrap translates this to a set of `--color` options
let g:fzf_colors =
\ { 'fg':      ['fg', 'Normal'],
  \ 'bg':      ['bg', 'Normal'],
  \ 'hl':      ['fg', 'Comment'],
  \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
  \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
  \ 'hl+':     ['fg', 'Statement'],
  \ 'info':    ['fg', 'PreProc'],
  \ 'border':  ['fg', 'Ignore'],
  \ 'prompt':  ['fg', 'Conditional'],
  \ 'pointer': ['fg', 'Exception'],
  \ 'marker':  ['fg', 'Keyword'],
  \ 'spinner': ['fg', 'Label'],
  \ 'header':  ['fg', 'Comment'] }

""""""" confluence-vim """""""
let g:confluence_url = 'https://confluence.dkb.ag/wiki/rest/api/content'

""""""" vim-terraform """""""
" allow vim-terraform to align settings automatically with tabularize
let g:terraform_align=1
" allow vim-terraform to automatically format *.tf and *.tfvars files with
" terraform fmt. you can also do this manually with the :terraformfmt command
let g:terraform_fmt_on_save=1

""""""" keybindings """""""
" set up leaders
let mapleader=","
let maplocalleader="\\"

" neomake and other build commands (ctrl-b)
nnoremap <C-b> :w<cr>:Neomake<cr>

autocmd BufNewFile,BufRead *.tex,*.bib noremap <buffer> <C-b> :w<cr>:new<bar>r !make<cr>:setlocal buftype=nofile<cr>:setlocal bufhidden=hide<cr>:setlocal noswapfile<cr>
autocmd BufNewFile,BufRead *.tex,*.bib imap <buffer> <C-b> <Esc><C-b>
