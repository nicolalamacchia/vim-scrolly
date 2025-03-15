" vim: et ts=2 sts=2 sw=2 et

" Author: Nicola Lamacchia

scriptencoding utf-8

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
\ }, "keep")
let g:scrolly_width = get(g:, 'scrolly_width', 20)
let g:scrolly_borders_outside = get(g:, 'scrolly_borders_outside', 1)

function! scrolly#bar() abort
  if winwidth(0) < get(g:, 'scrolly_minwidth', 150)
    return ''
  endif

  let bar_width = g:scrolly_width
  let symbols = g:scrolly_symbols
  let borders_outside = g:scrolly_borders_outside

  let win_top_line = line("w0") - 1
  let win_bottom_line = line("w$") - 1
  let current_line = line(".") - 1
  let total_lines = line("$")

  let scrollbar_start_padding = float2nr(1.0 * win_top_line / total_lines * bar_width)
  let win_indicator_width = float2nr(ceil((1.0 * win_bottom_line - win_top_line) / total_lines * bar_width))
  let curr_line_rel_to_win_ind_start = float2nr((1.0 * current_line - win_top_line) / max([(win_bottom_line - win_top_line), 1]) * win_indicator_width)
  let curr_line_ind_padding = scrollbar_start_padding + curr_line_rel_to_win_ind_start

  let chars = split(repeat(symbols.space, bar_width), '\zs')

  if win_indicator_width > 1
    let chars[max([min([scrollbar_start_padding, bar_width - 1]), 0]):max([scrollbar_start_padding + win_indicator_width - 1, 0])] = split(repeat(symbols.visible, win_indicator_width), '\zs')
  endif

  if !borders_outside
    let chars[0] = symbols.left
    let chars[-1] = symbols.right
  endif

  let chars[min([curr_line_ind_padding, bar_width - 1])] = symbols.current_line

  let scrollbar_str = join(chars, '')

  if get(g:, 'scrolly_show_errors', 1)
    " Process error markers
    let error_lnums = []
    for entry in getloclist(0)
      if has_key(entry, 'lnum')
        call add(error_lnums, entry.lnum)
      endif
    endfor
    let error_lnums = uniq(sort(error_lnums))

    let chars = split(scrollbar_str, '\zs')

    for lnum in error_lnums
      if lnum < 1 || lnum > total_lines
        continue
      endif

      if total_lines == 0
        continue
      endif
      let perc_error = (lnum - 1.0) / total_lines
      let error_index = float2nr(perc_error * bar_width)
      let error_index = max([0, min([error_index, bar_width])])

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

    let scrollbar_str = join(chars, '')
  endif

  if borders_outside
    return symbols.left . scrollbar_str . symbols.right
  endif

  return scrollbar_str
endfunction
