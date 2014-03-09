###
 extensible
 pragma
 configurable: attriblue separator, interplation delimitor, text starter, text ender
 define syntax on the fly
###

path = require('path')
extname = path.extname

{debug, warn} = peasy = require 'peasy'

nodes = require('./nodes')

class Ast
class Render

exports = module.exports = class Parser extends peasy.Parser
  constructor: ->
    super

    {memo, orp, char, may, any, eoi, identifier, follow, wrap, list, literal, select, base
    string} = self = @

    @parse = (data, root=self.root, cur=0) -> super; self.lineno = 0; self.row = 0
    @parseFile = (file) ->
    @char = (c) -> -> 
      if self.data[self.cur]==c
        self.cur++
        #\r\n, or \n
        if c=='\n' then self.lineno++; self.row = 0
        else self.row++
        c
    @step = ->
      if (c=self.data[self.cur])=='\n' then self.lineno++
      else self.row++
      c

    spaces = @spaces = ->
      data = self.data
      len = 0
      cur = self.cur
      while 1
        if ((c=data[cur++]) and (c==' ' or c=='\t')) then len++ else break
      self.cur += len; self.row += len
      len+1

    # matcher *spaces1*<br/>
    # one or more whitespaces, ie. space or tab.<br/>
    spaces1 = @spaces1 = ->
      data = self.data
      cur = self.cur
      len = 0
      while 1
        if ((c=data[cur++]) and (c==' ' or c=='\t')) then lent++ else break
      self.cur += len; self.row += len
      len

    lex = @lex =
      tjBibindLeft: '{{'
      tjBibindRight: '}}'
      tjUpbindLeft: '^{'
      tjUpbindRight: '}'
      tjDownbindLeft: '!{'
      tjDownbindRight: '}'
      tjInitbindLeft: '{'
      tjInitbindRight: '}'
      keyword: ->
      operator: ->
      token: ->
      next: ->
      attrsLeftDelimiter: -> true
      attrsRightDelimiter: -> follow(orp(blockStart, lineComment))()
      identifier: identifier
      operators:
        assign: char('=')
        attrAssign: char('=')

    identifier = -> lex.identifier()

    ast = @ast = new Ast()

    render = @render = new Render()

    @error = (msg) -> throw self.data[self.cur-20..self.cur+20]+' '+self.cur+': '+msg
    @expect = (match, message) -> match() or self.error(message)

    @nonQuotedAttrValue = ->  # non quoted string or expression
    @quotedAttrValue = -> string()
    @attrValue = -> orp(self.nonQuotedAttrValue, self.quotedAttrValue)
    @attrAssign = may(-> lex.operators.attrAssign() and expect(self.attrValue(), 'expect attribute value'))
    @tagAttr = ->
      if (name = identifier()) and (value=self.attrAssign())
        if value==true then nodes.Attr(name)
        else nodes.Attr(name, value)
    @attrs = -> wrap(list(self.tagAttr, lex.attrSeparator), lex.attrsLeftDelimiter, lex.attrsRightDelemiter)
    lineTailStmt = ->
    tagContent = -> lineTailStmt() and mayIndentBlockStmt()
    htmlTag = ->

    statements = @statements = {}
    statements.tag = -> console.log('tag stmt'); self.attrs() and tagContent()
    keywordIn = lex.keyword('in')
    statements['for'] = -> identifier() and may(-> comma() and identifier()) and keywordIn() and expression and block()
    statements['if'] = -> expression() and block()

    @pragmaDirectives =
      'css-coding-style': ->

    statements.pragma = -> (name = pragmaName()) and select self.pragmaDiretives[name]
    statements.include = ->
    statements['switch'] = ->
    statements.comment = ->
    statements.block = ->
    statements.extend = ->
    statements.text = ->
    statements.replace = ->
    statements.errorOnStatementBegin = ->

    @statement = -> select lex.next(),
      tag: statements.tag
      'for': statements.for
      'if': statements.if
      'switch': statements.switch
      pragma: statements.pragma
      include: statements.include
      block: statements.block
      replace: statements.replace # replace block in layout with content
      extends: statements.extends
      textStarter: statements.text
      comment: statements.comment
      syntax: statements.syntax
      '': statements.errorOnStatementBegin # 'default': error
    @root = @statementList = any(self.statement)


parser = exports.parser = new Parser()

exports.parse = (text, root=self.root, cursor=0) ->
  if typeof root=='number' then  cursor = root; root = self.root
  parser.parse(text, root, cursor)
