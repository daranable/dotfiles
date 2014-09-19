
fun! s:CheckShebang()
    if getline(1) == '%#!haml'
        set ft=haml
    endif
endfun

autocmd BufNewFile,BufRead * call s:CheckShebang()
