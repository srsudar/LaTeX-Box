" LaTeX Box latexmk functions

" Options and variables {{{

if !exists('g:LatexBox_latexmk_options')
	let g:LatexBox_latexmk_options = ''
endif
if !exists('g:LatexBox_output_type')
	let g:LatexBox_output_type = 'pdf'
endif
if !exists('g:LatexBox_viewer')
	let g:LatexBox_viewer = 'xdg-open'
endif
if !exists('g:LatexBox_autojump')
	let g:LatexBox_autojump = 0
endif
if ! exists('g:LatexBox_quickfix')
	let g:LatexBox_quickfix = 1
endif
if !exists('g:LatexBox_autosave')
	let g:LatexBox_autosave = 0
endif

" }}}

" Latexmk {{{
function! LatexBox_Latexmk(force)

	if g:LatexBox_autosave
		w
	endif

	let basename = LatexBox_GetTexBasename(1)

	" Set latexmk command with options
	let texroot = LatexBox_GetTexRoot()
	let mainfile = fnamemodify(LatexBox_GetMainTexFile(), ':t')
	let cmd = 'cd ' . shellescape(texroot) . ' ;'
	let cmd .= 'latexmk -' . g:LatexBox_output_type . ' '
	if a:force
		let cmd .= ' -g'
	endif
	let cmd .= g:LatexBox_latexmk_options
	let cmd .= ' -silent'
	let cmd .= " -e '$pdflatex =~ s/ / -file-line-error /'"
	let cmd .= " -e '$latex =~ s/ / -file-line-error /'"
	let cmd .= ' ' . shellescape(mainfile)
	let cmd .= '>/dev/null'

	" Execute command
	" silent execute '!' . cmd
	echo 'Compiling to pdf...'
	call system(cmd)
	if !has('gui_running')
		redraw!
	endif

	" check for errors
	call LatexBox_LatexErrors(v:shell_error)

endfunction
" }}}

" LatexmkClean {{{
function! LatexBox_LatexmkClean(cleanall)
	let basename = LatexBox_GetTexBasename(1)
	if has_key(g:latexmk_running_pids, basename)
		echomsg "don't clean when latexmk is running"
		return
	endif

	let cmd = '! cd ' . shellescape(LatexBox_GetTexRoot()) . ';'
	if a:cleanall
		let cmd .= 'latexmk -C '
	else
		let cmd .= 'latexmk -c '
	endif
	let cmd .= shellescape(LatexBox_GetMainTexFile())
	let cmd .= '>&/dev/null'

	silent execute cmd
	if !has('gui_running')
		redraw!
	endif

	echomsg "latexmk clean finished"
endfunction
" }}}


" LatexErrors {{{
" LatexBox_LatexErrors(jump, [basename])
function! LatexBox_LatexErrors(status, ...)
	if a:0 >= 1
		let log = a:1 . '.log'
	else
		let log = LatexBox_GetLogFile()
	endif

	if fnamemodify(getcwd(), ":p") !=# fnamemodify(LatexBox_GetTexRoot(), ":p")
		redraw
		" echohl WarningMsg
		" echomsg 'Changing directory to TeX root: '
		" 			\ . LatexBox_GetTexRoot() . ' to support error log parsing'
		" echohl None
		execute 'lcd ' . LatexBox_GetTexRoot()
	endif

	if g:LatexBox_autojump
		execute 'cfile ' . fnameescape(log)
	else
		execute 'cgetfile ' . fnameescape(log)
	endif

	" always open quickfix when an error/warning is detected
	if g:LatexBox_quickfix
		ccl
		cw
		if g:LatexBox_quickfix==2
			wincmd p
		endif
	endif

	if a:status > 0
		echomsg "Error (latexmk exited with status " . a:status . ")"
	elseif a:status == 0
		echomsg "Success!"
	endif
endfunction
" }}}

" Commands {{{
command! -bang	Latexmk			call LatexBox_Latexmk(<q-bang> == "!")
command! -bang	LatexmkClean	call LatexBox_LatexmkClean(<q-bang> == "!")
command! LatexErrors			call LatexBox_LatexErrors(-1)
" }}}

" vim:fdm=marker:ff=unix:noet:ts=4:sw=4
