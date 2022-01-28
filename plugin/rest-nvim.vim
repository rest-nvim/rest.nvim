" if !has('nvim-0.5')
"     echoerr 'Rest.nvim requires at least nvim-0.5. Please update or uninstall'
"     finish
" endif
"
" if exists('g:loaded_rest_nvim') | finish | endif
"
" nnoremap <Plug>RestNvim :lua require('rest-nvim').run()<CR>
" nnoremap <Plug>RestNvimPreview :lua require('rest-nvim').run(true)<CR>
" nnoremap <Plug>RestNvimLast :lua require('rest-nvim').last()<CR>
"
" let s:save_cpo = &cpo
" set cpo&vim
"
" let &cpo = s:save_cpo
" unlet s:save_cpo

" let g:loaded_rest_nvim = 1
"

function! YourFirstPlugin()
	" dont forget to remove this ...
	lua for k in pairs(package.loaded) do if k:match("^rest%-nvim") then package.loaded[k] = nil end end
endfun

augroup YourFirstPlugin
	autocmd!
augroup END
