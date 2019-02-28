" ftplugin/typescript.vim - settings specific to Typescript files

set shiftwidth=2 softtabstop=4 tabstop=8 expandtab


" from here on is global initialization, only run it once
if exists('s:loaded')
    finish
endif
let s:loaded = 1


" handle checking via Syntastic
let g:tsuquyomi_disable_quickfix = 1
let g:syntastic_typescript_checkers = ['tsuquyomi']

" enable Syntastic automatic checking
let b:syntastic_mode = 'active'


" load Tsuquyomi
if v:version < 800
    packadd vimproc  " needed to fork TSServer from older Vim
endif
packadd tsuquyomi

" rerun Tsuquyomi's ftplugin
" without this Tsuquyomi will not detect the first TS buffer opened
runtime! ftplugin/typescript/tsuquyomi.vim
