parse = (lines, errors, ctx) ->
  state = { "mode": "decls" }
  
  _parseDecls = (line) ->
    head = toks[0]
    if head.kind == "ident"
      if head.val == "fn"
        # function declaration
      else if head.val == "let"
        # let declaration
      else if head.val == "meta"
        # meta declaration
      else
        errors.error("Unexpected symbol %s", [head])
        return false
  
  _parseFn = (line) ->
    undefined
  
  for line in lines
    toks = line.toks
    
    # ignore empty lines
    if toks.length == 0
      continue
    
    if state.mode == "decls"
      _parseDecls(line)
    else if state.mode == "fn"
      _parseFn(line)
    