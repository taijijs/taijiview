###
 extensible
 pragma
 configurable: attriblue separator, interplation delimitor, text starter, text ender
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

    {memo, orp, char, may, any, eoi, identifier, follow, wrap, list, literal, select, base} = self = @

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

    identifier = -> lex.identifier()

    ast = @ast = new Ast()

    render = @render = new Render()

    nonQuotedAttrValue = ->  # non quoted string or expression
    quotedAttrValue = -> # quoted string or expression
    @attrValue = -> orp(nonQuotedAttrValue, quotedAttrValue)
    @attrAssign = may(-> lex.op.attrAssign() and attrValue())
    @tagAttr = -> (name = identifier()) and (value=attrAssign()) and [name, value]
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
      'css-coding-style' : ->

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
      #inlinecomment: inlineComment
      '': statements.errorOnStatementBegin # 'default': error
    @root = @statementList = any(self.statement)

    @init = (text='', start=0) -> self.text = text; self.cur = start; self
    @parseFile = (file) ->

parser =exports.parser = new Parser()

exports.parse = (text, cursor=0, start=parser.root) ->
  if typeof cursor=='function' then  start = cursor; cursor = 0
  parser.init(text, cursor)
  start()
