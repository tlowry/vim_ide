let g:ale_linters = {'rust': ['cargo','rls']}
let g:ale_linters = {'python': ['pyright','flake8','pylint']}
let g:ale_rust_rls_toolchain = 'stable'
let g:ale_completion_enabled = 1
let g:ale_disable_lsp = 0
nnoremap <buffer> <silent> <C-v>= :ALEFix<CR>
