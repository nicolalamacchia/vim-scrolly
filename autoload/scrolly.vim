" vim: et ts=2 sts=2 sw=2 et

" Author: Nicola Lamacchia

scriptencoding utf-8

function! scrolly#init()
  let g:scrolly_symbols = get(g:, 'scrolly_symbols', {})
  call extend(g:scrolly_symbols, {
    \ 'left': '▐',
    \ 'right': '▌',
    \ 'current_line': '█',
    \ 'space': ' ',
    \ 'visible': '▒',
    \ 'error_in_line': '▀',
    \ 'error_in_view': '▓',
    \ 'error': '▄',
    \ 'overflow_line': '╳',
  \ }, "keep")
  let g:scrolly_width = get(g:, 'scrolly_width', 20)
  let g:scrolly_borders_outside = get(g:, 'scrolly_borders_outside', 1)
  let g:scrolly_loc_limit = get(g:, 'scrolly_loc_limit', 1000)
endfunction

function! scrolly#calculate(window_width, window_height, win_top_line, win_bottom_line, current_line, total_lines, loc_list) abort
  if a:window_width < get(g:, 'scrolly_minwidth', 150) || a:total_lines == 0
    return ''
  endif

  let bar_width = g:scrolly_width
  let symbols = g:scrolly_symbols
  let borders_outside = g:scrolly_borders_outside

  let effective_win_height = a:win_bottom_line - a:win_top_line + 1
  " this check is needed in case there are lines wrapping (overflow can only happen at the end of the buffer)
  if a:win_bottom_line + 1 == a:total_lines
    let overflow_lines = a:window_height - effective_win_height
  else
    let overflow_lines = 0
  endif
  let code_bar_width = a:total_lines * bar_width / (a:total_lines + overflow_lines)

  let scrollbar_start_padding = code_bar_width * a:win_top_line / a:total_lines
  let win_indicator_width = float2nr(ceil(1.0 * code_bar_width * effective_win_height / a:total_lines))
  let curr_line_ind_padding = code_bar_width * a:current_line / a:total_lines

  let scrollbar_str = repeat(symbols.space, scrollbar_start_padding)
    \ . repeat(symbols.visible, win_indicator_width)
    \ . repeat(symbols.space, code_bar_width - scrollbar_start_padding - win_indicator_width)
    \ . repeat(symbols.overflow_line, bar_width - code_bar_width)

  let chars = split(scrollbar_str, '\zs')

  if !borders_outside
    if chars[0] == symbols.space || chars[0] == symbols.overflow_line
      let chars[0] = symbols.left
    endif
    if chars[-1] == symbols.space || chars[-1] == symbols.overflow_line
      let chars[-1] = symbols.right
    endif
  endif

  let chars[curr_line_ind_padding] = symbols.current_line

  if get(g:, 'scrolly_show_errors', 1)
    let error_lnums = []
    if g:scrolly_loc_limit
      let loc_list = a:loc_list[:g:scrolly_loc_limit]
    else
      let loc_list = a:loc_list
    endif
    for entry in loc_list
      if has_key(entry, 'lnum')
        call add(error_lnums, entry.lnum)
      endif
    endfor
    let error_lnums = uniq(sort(error_lnums))

    for lnum in error_lnums
      if lnum < 1 || lnum > a:total_lines
        continue
      endif

      if a:total_lines == 0
        continue
      endif
      let perc_error = (lnum - 1.0) / a:total_lines
      let error_index = float2nr(perc_error * code_bar_width)
      let error_index = max([0, min([error_index, code_bar_width])])

      if error_index >= 0 && error_index < len(chars)
        if error_index == curr_line_ind_padding
          let chars[error_index] = symbols.error_in_line
        elseif error_index >= scrollbar_start_padding && error_index < scrollbar_start_padding + win_indicator_width
          let chars[error_index] = symbols.error_in_view
        else
          let chars[error_index] = symbols.error
        endif
      endif
    endfor
  endif

  let scrollbar_str = join(chars, '')

  if borders_outside
    return symbols.left . scrollbar_str . symbols.right
  endif

  return scrollbar_str
endfunction

function! scrolly#bar() abort
  let win_top_line = line("w0") - 1
  let win_bottom_line = line("w$") - 1
  let current_line = line(".") - 1
  let total_lines = line("$")
  let win_width = winwidth(0)
  let win_height = winheight(0)
  let loc_list = getloclist(0)

  return scrolly#calculate(win_width, win_height, win_top_line, win_bottom_line, current_line, total_lines, loc_list)
endfunction
