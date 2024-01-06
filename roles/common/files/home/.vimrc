set nocompatible              " be iMproved, required
" filetype off                  " required
set encoding=utf8
set t_RV=

" Install vim-plug if not found
if empty(glob('~/.vim/autoload/plug.vim'))
	silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
				\ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
endif

" Run PlugInstall if there are missing plugins
autocmd VimEnter * if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
			\| PlugInstall --sync | source $MYVIMRC
			\| endif

" set the runtime path to include Vundle and initialize
" set rtp+=~/.vim/bundle/Vundle.vim
" call vundle#begin()
call plug#begin()
" Plug 'VundleVim/Vundle.vim'
Plug 'tpope/vim-fugitive'
" Plug 'git://git.wincent.com/command-t.git'
Plug 'rstacruz/sparkup', {'rtp': 'vim/'}
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'dracula/vim', { 'name': 'dracula' }
" Plug 'calviken/vim-gdscript3'
Plug 'preservim/nerdtree'
Plug 'ryanoasis/vim-devicons'
Plug 'rust-lang/rust.vim'
Plug 'chr4/nginx.vim'
Plug 'fatih/vim-go'
Plug 'godlygeek/tabular'
Plug 'plasticboy/vim-markdown'
Plug 'hashivim/vim-terraform'
Plug 'cespare/vim-toml'
Plug 'ntpeters/vim-better-whitespace'
Plug 'gyim/vim-boxdraw'
Plug 'isobit/vim-caddyfile'
Plug 'mhartington/oceanic-next'
" Plug 'blindFS/vim-taskwarrior'
Plug 'hzchirs/vim-material'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'PhilRunninger/nerdtree-visual-selection'
Plug 'folke/tokyonight.nvim', { 'branch': 'main' }
Plug 'ghifarit53/tokyonight-vim'
Plug 'junegunn/vim-plug'
Plug 'fladson/vim-kitty'
Plug 'NoahTheDuke/vim-just'
Plug 'mfussenegger/nvim-lint'
call plug#end()

let g:CommandTPreferredImplementation='lua'
let g:strip_whitespace_on_save = 1
let g:strip_whitespace_confirm = 0
let g:vim_markdown_folding_disabled = 1
let g:NERDTreeGitStatusUseNerdFonts = 1

" All of your Plugins must be added before the following line
" call vundle#end()            " required
" filetype plugin indent on    " required

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

" Persistent Undo

set undofile                " Save undos after file closes
set undodir=$HOME/.vim/undo " where to save undo histories
set undolevels=1000         " How many undos
set undoreload=10000        " number of lines to save for undo

" Kitty Terminal Stuff
let &t_ut=''

syntax enable

" Tokyo Night:

let g:tokyonight_style = 'night' " available: night, storm
let g:tokyonight_enable_italic = 1
let g:tokyonight_transparent_background = 1

colorscheme tokyonight

" Material

" Oceanic

" Dark
" set background=dark
" colorscheme vim-material

" Palenight
" let g:material_style='palenight'
" set background=dark
" colorscheme vim-material

" Oceanic
" let g:material_style='oceanic'
" set background=dark
" colorscheme vim-material

" Light
" set background=light
" colorscheme vim-material

" Dracula

" syntax enable
" let g:dracula_colorterm = 0
" colorscheme dracula

" DraculaPro

" packadd! dracula_pro
" syntax enable
" let g:dracula_colorterm = 0
" colorscheme dracula_pro

" Powerline Colors

" let g:airline_theme='deus'
" let g:airline_theme='material'
let g:airline_theme = "tokyonight"
