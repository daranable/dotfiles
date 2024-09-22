" share configuration with Vim
source ~/.vim/vimrc


" style the :sign gutter identically to the 'number' gutter
highlight clear SignColumn
highlight link SignColumn LineNr

" style Neomake/nvim-typescript signs to match gutter
highlight link NeomakeErrorSign DiffDelete
highlight link NeomakeWarningSign DiffChange
highlight link NeomakeInfoSign DiffText
