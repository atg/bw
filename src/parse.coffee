class TokBuffer
  constructor: (line) ->
    @toks = line.toks.slice()
    @idx = 0
  
  prev: () -> peekN(-1) # previous
  peek: () -> peekN(0) # current
  next: () -> peekN(1) # next
  
  pop: () ->
    i = @idx
    if i >= 0 and i < @toks.length
      @idx += 1
      return @toks[i]
    return null
  
  peekN: (delta) ->
    i = @idx + delta
    if i >= 0 and i < @toks.length
      return @toks[i]
    return null
  
  isEmpty: () ->
    return not (@idx >= 0 and @idx < @toks.length)

isSymbol: (t) ->
  t.kind == "symbol"
isSymbolX: (t, x) ->
  t.kind == "symbol" and t.val == x
isIdent: (t) ->
  t.kind == "ident"
isIdentX: (t, x) ->
  t.kind == "ident" and t.val == x


# TODO: eval insertions.
# At certain times, if there's an unexpected token, eval the loaded parser extensions
# each parser extension binding point gets a name, e.g.
#   [extpoint] decls.0

parse = (lines, errors, ctx) ->
  state = { "mode": ["decls"] }
  
  _parseBody = (line, toks, isMeta, callback) ->
    # { stmt1 EOL stmt2 EOL stmt3 }
    state.jobs.push({
      "mode": "body",
      "ctx": [],
      "callback": ((job) ->
        info = { "kind": "body", "stmts": job.ctx }
        callback(info))
    })
    
  _parseDeclFn = (line, toks, isMeta) ->
    # name <typeparams> ( params ) { body }
  
  _parseDeclLet = (line, toks, isMeta) ->
    # name = expr
    # name { body }
  
  _parseDeclUse = (line, toks, isMeta) ->
    # moduleName
    # moduleName: symbol1, symbol2, symbol3
    moduleName = toks.pop()
    useDecl = {
      "kind": "use",
      "isMeta": isMeta,
    }
    
    if not moduleName?
      errors.error(toks.prev(), "use ___ what?")
      return false
    
    if not isIdent(moduleName)
      errors.error(moduleName, "Unexpected %s", [moduleName])
      return false
    
    # expect : or EOL now
    colon = toks.pop()
    if not colon?
      return useDecl
    
    if not isSymbolX(colon, ":")
      errors.warning(colon, "Ignoring unexpected %s", [colon])
      return useDecl
    
    # comma separated list of idents
    # TODO
  
  _parseDeclMeta = (line, toks) ->
    head2 = toks.pop()
    if head2?
      if head2.val == "fn"
        return _parseDeclFn(line, toks, true)
      else if head2.val == "let"
        return _parseDeclLet(line, toks, true)
      else if head2.val == "use"
        return _parseDeclUse(line, toks, true)
      else
        # [extpoint] decl.meta.0
        errors.error(head, "Unexpected word %s", [head2])
        return false
    else
      errors.error(toks.prev(), "meta ___ what?")
      return false
  
  _parseDecls = (line, toks) ->
    head = toks.pop()
    if isIdent(head)
      if head.val == "fn"
        return _parseDeclFn(line, toks, false)
      else if head.val == "let"
        return _parseDeclLet(line, toks, false)
      else if head.val == "meta"
        return _parseDeclMeta(line, toks)
      else if head.val == "use"
        return _parseDeclUse(line, toks, false)
      else
        # [extpoint] decl.0
        errors.error(head, "Unexpected word %s", [head])
        return false
    else
      # [extpoint] decl.0
      errors.error(head, "Unexpected %s", [head])
      return false
  
  _parseStmts = (line, toks) ->
    head = toks.pop()
    dispatch = {
      "if": _parseStmtIf,
      "else": _parseStmtElse,
      "for": _parseStmtFor,
      "let": _parseStmtLet,
      "var": _parseStmtVar,
      "match": _parseStmtMatch,
      "rt": _parseStmtReturn,
      "return": _parseStmtReturn,
      "break": _parseStmtBreak,
      "continue": _parseStmtContinue,
      "yield": _parseStmtYield,
      "async": _parseStmtAsync,
    }
    if isIdent(head)
      k = head.val
      if k of dispatch
        return dispatch[k](line, toks)
      else
        # [extpoint] stmt.0
        assert False
  
  for line in lines
    toks = new TokBuffer(line.toks)
    
    # ignore empty lines
    if toks.isEmpty()
      continue
    
    job = state.jobs[state.jobs.length - 1]
    mode = job.mode
    if mode == "decls"
      _parseDecls(line, toks)
    else if mode == "body"
      _parseBody(line, toks)
    else
      # [extpoint] job.0
      assert False

    