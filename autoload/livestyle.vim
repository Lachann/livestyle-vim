if !exists('s:bufcache')
  let s:bufcache = {}
endif

let s:url = "http://127.0.0.1:54000/"

function! s:updateFiles()
  let files = map(range(1, bufnr('$')), 'fnamemodify(bufname(v:val), ":p")')
  call webapi#http#post(s:url, webapi#json#encode({
  \  "action": "updateFiles",
  \  "data": files,
  \}))
endfunction

function! s:patch()
  let f = fnamemodify(bufname('%'), ':p')
  if !livestyle#lang#exists(&ft)
    return
  endif
  let prev = has_key(s:bufcache, f) ? s:bufcache[f] : {}
  if !empty(prev) && prev['tick'] == b:changedtick
    return
  endif
  let buf = join(getline(1, line('$')), "\n") . "\n"
  let cur = livestyle#lang#{&ft}#parse(buf)
  let patch = []
  if !empty(prev)
    let patch = livestyle#lang#{&ft}#diff(prev.data, cur)
  endif
  let s:bufcache[f] = {'tick': b:changedtick, 'data': cur}
  for p in patch
    call webapi#http#post(s:url, webapi#json#encode({
    \  "action": "update",
    \  "data": {
    \    "editorFile": f,
    \    "patch": p,
    \  }
    \}))
  endfor
endfunction

function! livestyle#setup()
  let files = map(range(1, bufnr('$')), 'fnamemodify(bufname(v:val), ":p")')
  let vimapp = printf('Vim%d.%d', v:version / 100, v:version % 100)
  call webapi#http#post(s:url, webapi#json#encode({
  \  "action": "id",
  \  "data": {
  \    "id": vimapp,
  \    "title": vimapp,
  \    "icon": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAEnQAABJ0BfDRroQAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAAMXSURBVDiNdZNbbFRVFIa/fTjTuRxnOi2EtJBo2kiiRiyEllEkamiqGAGjSTWRTMAoSELfIF4wrQJJVSyIQHzwQpCpOhSsGB80bXhAjcYATQuEsSUGaoFBalN75szM6czZe/tgOwWj+3X969//WvmW0FrzX08IYcSenrNdKl08fXxsp/4foYivW1v55JqnToQj4Wo0AgCt9fGepLqj+bcqlNDXeuf3PfHA+iqgDCBjZwqfJT/f1n30y4RZU1Mbf7SpaZGU6hbnyWKBrjPriNbkxcrlh+tjS2JMhzBNk9N9ZzqAhJFKXTj0xZHkmFIKz/PwPI+Rkd9JHPuQinkmZWaIk5c+4vof6VJ9aGiQk9//OARgdCWPTZw7N7Dedd2SIJVKMW/VWayID58IsnD2KiqilXiex+Xhy7z82rYLeSezGsAAUFIJpWTJQGmNzwzgM0Lc42yl6f5mCoUCV66M0L63leq64qX+/v4JAEMIYejoeKuUMyOgFaYIUDu+icaGZlx3knQ6zc69r7IwfpWHnq1+/MXWld1CCGEsWBrZeO+yufVKq1sSLJiMs2JJM/l8ntHRUdrff5365zPcVh7gL++iseKZu9bcWR9Za05m9VmZC7hKqqDneQDU3beIUGgZuVwO27Z5e18bsRdcguHgFCMG0rYcN6POG8Pn7Z9+/nbwoJQzOwgEAuRyOSbsCd7Z9wYPblCUV4QoM4P4fRZVstH+9L1vWkZ+zfQbAOWB6u/0TSM4joPjOOzav4OHXzKJVlqUzQriNy3mFh6xP+7obuk9OpAAMKfIY3qJQgiKXpGOA+00brIIV5ql2JFsg/1BR2dLT1dfYho4E0CjUUohpURrxZ4Du/VjmytEZPZMs5VZ7Ox/6/Ar6WEjeTOx/3CglBRCIKVH25vbr98Yv/bJ7f7leb9p4fdZhO2l7u62zoPpYT0I3F3XEJtf1xDzlxJks9lTPSd6//yq++vRMdveas4yvT07OvXmLc/FpVLq3V2HkmM35A+AmPpUAApA/PtKp5wtwHLd8VolhQxZ0atAFsgB+YFTv8hp/d+3KJyTs2tiKQAAAABJRU5ErkJggg==",
  \    "files": files,
  \  }
  \}))
  augroup LiveStyle
    autocmd!
    autocmd CursorHold * silent! call s:patch()
    autocmd CursorHoldI * silent! call s:patch()
    autocmd CursorMoved * silent! call s:patch()
    autocmd CursorMovedI * silent! call s:patch()
    autocmd InsertLeave * silent! call s:patch()
    autocmd BufEnter * silent! call s:updateFiles()
  augroup END
  set updatetime=100
endfunction
