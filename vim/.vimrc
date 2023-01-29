set number "设置行号
set ruler "设置游标
set wrap "设置折行
set linebreak "按单词进行折行
set showmode "设置显示当前处于的模式
set showcmd "设置显示当前使用的命令
set clipboard=unnamed "用系统粘贴板替换vim暂存器
set cursorline "光标所在行添加下划线
set scrolloff=5 "滚动时预留5行
set noswapfile "不会产生swap临时文件
set fileencodings=utf-8,gbk

" search
set hlsearch "高亮搜索结果
set ignorecase "搜索时不区分大小写
set incsearch "搜索时实时匹配
set smartcase "搜索单词时如果单词有大写字母时暂时忽略ignorecase

" tab and space
set softtabstop=4 "tab键以4个空白符显示
set shiftwidth=4 "快速排版时以4个空白符显示
set expandtab "可以使用retab命令将tab转换成空格

" tabe
set showtabline=2 "永远显示tab标签
set splitbelow "水平分割时新文档在下
set splitright "垂直分割时新文档在右

" color
syntax on
" try
"     colorscheme darkblue
" catch
"     colorscheme default
" endtry

" filetype
filetype on "匹配文件类型
filetype indent on "使用文件类型的缩进
filetype plugin on "使用插件

" keymap
let mapleader = ","
map <UP> <Nop>
map <LEFT> <Nop>
map <RIGHT> <Nop>
map <DOWN> <Nop>

" autocmd
autocmd WinEnter * setlocal cursorline "进入窗口，添加下划线
autocmd WinLeave * setlocal nocursorline "离开窗口，取消下划线
autocmd BufWritePre * :%s/\s\+$//e "清除行尾空白字符
autocmd BufRead,BufNewFile *.js noremap <F5> :w !ls&&node<Enter>
if executable("go")
    autocmd BufRead,BufNewFile *.go noremap <F5> :% w !go run<Enter>
    "读取或创建.go文件时，将f5映射为执行go run 命令
else
    autocmd BufRead,BufNewFile *.go noremap <F5> :echo "you need to install go first!"
endif

call plug#begin('~/.vim/plugged')

Plug 'ap/vim-css-color'

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

Plug 'preservim/nerdtree'

Plug 'mattn/emmet-vim'
Plug 'tpope/vim-surround'
Plug 'chun-yang/auto-pairs'
Plug 'ctrlpvim/ctrlp.vim'

Plug 'kien/rainbow_parentheses.vim'
Plug 'pangloss/vim-javascript'

Plug 'ycm-core/YouCompleteMe'
call plug#end()
