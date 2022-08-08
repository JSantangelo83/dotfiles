set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'preservim/nerdtree'
Plugin 'junegunn/fzf'
Plugin 'junegunn/fzf.vim'

call vundle#end()            " required
filetype plugin indent on    " required

let mapleader = "\ "
syntax on
set autoindent
set smartindent
set number
set mouse=a
set textwidth=0
set encoding=utf-8
colorscheme sublimemonokai
set relativenumber

map <ESC>[27;5;9~ :tabnext<CR>
map <ESC>[27;6;9~ :tabnext<CR>

nnoremap <F14> gT
nnoremap <C-w> :tabclose<CR>
nnoremap <C-t> :NERDTreeToggle %<CR>
nnoremap <S-C-f> :NERDTreeFind<CR>
nnoremap <C-p> :Files <CR>
nnoremap <leader>s :w<CR>
nnoremap <leader>q :q
