" vim: et ts=2 sts=2 sw=2 et

" Author: Nicola Lamacchia

scriptencoding utf-8

if exists('g:loaded_scrolly')
  finish
endif

let g:loaded_scrolly = 1

call scrolly#init()

function! AirlineScrolly(...)
  let w:airline_section_x = get(w:, 'airline_section_x',
    \ get(g:, 'airline_section_x', ''))
  let w:airline_section_x = '%{scrolly#bar()} ' . w:airline_section_x
endfunction

if get(g:, 'scrolly_enable', 1) && exists('g:loaded_airline') && g:loaded_airline == 1 && get(g:, 'scrolly_enable_airline_scrollbar', 1)
  call airline#add_statusline_func('AirlineScrolly')
endif
