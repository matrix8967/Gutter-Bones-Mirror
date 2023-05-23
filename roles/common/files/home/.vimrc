set nocompatible              " be iMproved, required
filetype off                  " required
set encoding=utf8
set t_RV=

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'
Plugin 'tpope/vim-fugitive'
Plugin 'git://git.wincent.com/command-t.git'
Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'dracula/vim', { 'name': 'dracula' }
" Plugin 'calviken/vim-gdscript3'
Plugin 'preservim/nerdtree'
Plugin 'ryanoasis/vim-devicons'
Plugin 'rust-lang/rust.vim'
Plugin 'chr4/nginx.vim'
Plugin 'fatih/vim-go'
Plugin 'godlygeek/tabular'
Plugin 'plasticboy/vim-markdown'
Plugin 'hashivim/vim-terraform'
Plugin 'cespare/vim-toml'
Plugin 'ntpeters/vim-better-whitespace'
Plugin 'gyim/vim-boxdraw'
Plugin 'isobit/vim-caddyfile'
Plugin 'mhartington/oceanic-next'
" Plugin 'blindFS/vim-taskwarrior'
Plugin 'hzchirs/vim-material'
Plugin 'Xuyuanp/nerdtree-git-plugin'
Plugin 'PhilRunninger/nerdtree-visual-selection'
Plugin 'folke/tokyonight.nvim', { 'branch': 'main' }
Plugin 'ghifarit53/tokyonight-vim'

let g:strip_whitespace_on_save = 1
let g:strip_whitespace_confirm = 0
let g:vim_markdown_folding_disabled = 1
let g:NERDTreeGitStatusUseNerdFonts = 1


" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required

" NerdTree

autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
map <C-b> :NERDTreeToggle<CR>
map <F7> gg=G<C-o><C-o>

" Misc Env Options

set termguicolors
set wrap linebreak nolist
set runtimepath+=~/.vim_runtime

try
source ~/.vim_runtime/my_configs.vim
catch
endtry

" Kitty Terminal Stuff
let &t_ut=''

syntax enable

" Tokyo Night:

let g:tokyonight_style = 'night' " available: night, storm
let g:tokyonight_enable_italic = 1
let g:tokyonight_transparent_background = 1

colorscheme tokyonight

" Material:

" Oceanic:

" Dark
"set background=dark
"colorscheme vim-material

" Palenight
"let g:material_style='palenight'
"set background=dark
"colorscheme vim-material

" Oceanic
" let g:material_style='oceanic'
" set background=dark
" colorscheme vim-material

" Light
"set background=light
"colorscheme vim-material

" Dracula:

" syntax enable
" let g:dracula_colorterm = 0
" colorscheme dracula

" DraculaPro:

" packadd! dracula_pro
" syntax enable
" let g:dracula_colorterm = 0
" colorscheme dracula_pro

" Powerline Colors:

" let g:airline_theme='deus'
" let g:airline_theme='material'
let g:airline_theme = "tokyonight"