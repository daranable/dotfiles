
"let g:nvim_typescript#kind_symbols = {
"  \ 'label': 'd',
"  \ 'parameter': 'v',
"  \ 'enum': 't',
"  \ 'alias': 't',
"  \ 'method': 'f',
"  \ 'local var': 'v',
"  \ 'interface': 't',
"  \ 'type': 't',
"  \ 'getter': 'f',
"  \ 'local class': 't',
"  \ 'property': 'm',
"  \ 'constructor': 'f',
"  \ 'const': 'v',
"  \ 'let': 'v',
"  \ 'type parameter': 't',
"  \ 'function': 'f',
"  \ 'index': 'd',
"  \ 'keyword': 'd',
"  \ 'setter': 'f',
"  \ 'script': 'd',
"  \ 'module': 'd',
"  \ 'local function': 'f',
"  \ 'call': 'f',
"  \ 'class': 't',
"  \ 'primitive type': 't',
"  \ 'var': 'v'
"  \}


function! typescriptcomplete#Complete(findstart, base)
  if a:findstart
    let line = getline('.')
    let start = col('.') - 1

    while start > 0 && line[start - 1] =~ '\k'
      let start -= 1
    endwhile

    return start
  else
    return TSComplete(a:base)
  endif
endfun
