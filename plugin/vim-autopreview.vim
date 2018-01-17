if exists ('g:loaded_autopreview') || !has('autocmd') || !exists(':filetype')
    finish
endif
let g:loaded_autopreview = 1


if !exists('g:AutoPreview_enabled')
    let g:AutoPreview_enabled = 1
endif

if !exists('g:AutoPreview_allowed_filetypes')
    let g:AutoPreview_allowed_filetypes = ['c', 'cpp']
endif

command! -nargs=0 -bar AutoPreviewToggle :call s:AutoPreviewToggle()
command! -nargs=0 -bar PreviewWord :call s:PreviewWord()

if g:AutoPreview_enabled
    augroup AutoPreview
        au! FileType * :call s:SetCursorHoldAutoCmd()
    augroup END
endif


func s:AutoPreviewToggle()
    if g:AutoPreview_enabled
        silent! exe 'pclose'
        silent! :au! AutoPreview
    else 
        silent! call s:PreviewWord()
        augroup AutoPreview
            au! FileType * :call s:SetCursorHoldAutoCmd()
            let l:i = 1
            let l:n = bufnr('$')
            while (l:i <= l:n)
                if buflisted(l:i) && index(g:AutoPreview_allowed_filetypes,
                            \            getbufvar(l:i, '&ft')) >= 0 &&
                            \   !getbufvar(l:i, '&previewwindow')
                    exe 'au! CursorHold <buffer=' . l:i . '> nested :call s:PreviewWord()'
                    exe 'au! CursorHoldI <buffer=' . l:i . '> nested :call s:PreviewWord()'
                endif
                let l:i = l:i + 1
            endwhile
        augroup END
    endif
    let g:AutoPreview_enabled = !g:AutoPreview_enabled
endfunc


func s:SetCursorHoldAutoCmd()
    if &previewwindow
        return
    endif

    augroup AutoPreview
        if index(g:AutoPreview_allowed_filetypes, &filetype) >= 0
            " auto refresh the ptag window
            au! CursorHold <buffer> nested :call s:PreviewWord()
            au! CursorHoldI <buffer> nested :call s:PreviewWord()
        else
            au! CursorHold <buffer>
            au! CursorHoldI <buffer>
        endif
    augroup END
endfunc

func s:PreviewWord()
    if &previewwindow           " don't do this in the preview window
        return
    endif
    let l:w = expand('<cword>')       " get the word under cursor
    if l:w =~ '\a'            " if the word contains a letter

        " Try displaying a matching tag for the word under the cursor
        try
            silent! exe 'ptag ' . l:w
        catch
            return
        endtry

        let l:oldwin = winnr()  " get origin window
        silent! wincmd P            " jump to preview window

        if &previewwindow       " if we really get there...
            if has('folding')
                silent! .foldopen       " don't want a closed fold
            endif

            call search('$', 'b')       " to end of previous line
            let l:w = substitute(l:w, '\\', '\\\\', '')
            call search('\<\V' . l:w . '\>')  " position cursor on match

            match none " delete existing highlight

            " Add a match highlight to the word at this position
            hi previewWord term=bold ctermbg=white guibg=white ctermfg=black guifg=black
            exe 'match previewWord "\%' . line('.') . 'l\%' . col('.') . 'c\k*"'
            " back to old window
            exec l:oldwin.'wincmd w'
        endif
    endif
endfun
