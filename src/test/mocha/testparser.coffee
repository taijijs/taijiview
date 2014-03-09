chai = require("chai")
expect = chai.expect

#console.log 'running testparser'
{parse, parser} = require '../../lib/parser'
{tag} = nodes = require '../../lib/nodes'
#console.log 'requird finish'

describe "parser",  ->
  xit 'should parse "p: 1"', ->
    expect(parse('p: 1')).to.equal 1
  xit 'should parse "p: 1", parser.tag', ->
    expect(parse('p: 1', parser.statements.tag)).to.equal 1, tag.p({}, 1)
  it.only 'should parse id, parser.tagAttr', ->
    expect(parse('id', parser.tagAttr)).to.deep.equal nodes.attr('id')

describe 'render', ->
  it 'should render <p>1</p>', ->
    expect(tag.p(nodes.attrs(), nodes.text('1')).render()).to.equal '<p>1</p>'

  it 'tag.p(nodes.attrs([nodes.attr(id, x) should render <p>1</p>', ->
    expect(tag.p(nodes.attrs([nodes.attr('id', 'x')]), nodes.text('1')).render()).to.equal '<p id="x">1</p>'

  it 'nodes.attr(id, x) should render <p>1</p>', ->
    expect(nodes.attr('id', 'x').render()).to.equal 'id="x"'

  it 'nodes.text(1) should render 1', ->
    expect(nodes.text('1').render()).to.equal '1'

  it 'vari(a) should render 1', ->
    expect(nodes.variable('a').render({a:1})).to.equal '1'