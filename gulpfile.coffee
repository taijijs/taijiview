_ = require 'lodash'
gulp = require('gulp')
gutil = require 'gulp-util'
changed = require('gulp-changed')
cache = require('gulp-cached')
plumber = require('gulp-plumber')
clean = require('gulp-clean')
#gulpFilter = require('gulp-filter')
shell = require 'gulp-shell'
rename = require("gulp-rename")
coffee = require ('gulp-coffee')
#browserify = require('gulp-browserify')
concat = require('gulp-concat')
closureCompiler = require('gulp-closure-compiler')
size = require('gulp-size')
mocha = require('gulp-mocha')
karma = require('gulp-karma')
twoside = require './gulp-twoside'
pluginwatch = require('gulp-watch')
express = require('express')
#http://rhumaric.com/2014/01/livereload-magic-gulp-style/
livereload = require('gulp-livereload')
tinylr = require('tiny-lr')
runSequence = require('run-sequence')

task = gulp.task.bind(gulp)
watch = gulp.watch.bind(gulp)
src = gulp.src.bind(gulp)
dest = gulp.dest.bind(gulp)
from = (source, options={dest:folders_dest, cache:'cache'}) ->
  options.dest ?= folders_dest
  options.cache ?= 'cache'
  src(source).pipe(changed(options.dest)).pipe(cache(options.cache)).pipe(plumber())
GulpStream = src('').constructor
GulpStream::to = (dst) -> @pipe(dest(dst))#.pipe(livereload(tinylrServer))
GulpStream::pipelog = (obj, log=gutil.log) -> @pipe(obj).on('error', log)

rootOf = (path) -> path.slice(0, path.indexOf(''))
midOf = (path) -> path.slice(path.indexOf('')+1, path.indexOf('*'))

distributing = false

# below will put output js files in wrong directory structure!!!
# coffee: [coffeeroot+'*.coffee', coffeeroot+'samples/**/*.coffee', coffeeroot+'test/**/*.coffee']
# use the code below to solve this problem
patterns = (args...) ->
  for arg in args
    if typeof arg =='string' then pattern(arg)
    else arg
gulpto = (destbase, args...) ->
  for arg in args
    if typeof arg =='string' then pattern(arg, destbase)
    else arg
pattern = (src, destbase, options) -> new Pattern(src, destbase, options)
class Pattern
  constructor: (@src, @destbase, options={}) ->
    if typeof destbase=='object' then options = destbase; @destbase = undefined
    srcRoot = rootOf(@src)
    if not @destbase then @destbase = rootOf(@src)
    if not options.desttail? then @desttail = midOf(@src)
    if @desttail then @dest = @destbase+@desttail
    else @dest = @destbase

folders_src = 'src/'
folders_coffee = folders_src
folders_dest = 'dist/'
folders_dest = folders_dest
folders_destClient = folders_dest+'client/'
folders_dist = 'dist/'
folders_dev = 'dev/'
folders_pulic = 'public/'
folders_static = 'static/'

task 'clean', -> src([folders_dest], {read:false}) .pipe(clean())

files_copy = (folders_src+name for name in ['**/*.js', '**/*.json', '**/*.jade', '**/*.html', '**/*.css', '**/*.tjv'])
task 'copy', -> from(files_copy, {cache:'copy'}).to(folders_dest)

files_coffee = [folders_coffee+'**/*.coffee']
task 'coffee', -> from(files_coffee, {cache:'coffee'}).pipelog(coffee({bare: true})).to(folders_dest)

#task 'stylus', -> from(['css/**/*.css']).pipe(styl({compress: true})).to(folders_dest)

merge = (files) -> files = files.split(' '); path = files[0]; (for file in files.splice(1) then path+file).join(' ')

client = folders_destClient

# remove twoside temporalily. add them when distributing.
#destLib = folders_dest+'lib/'
#destLibClient = destLib+'client/'
#files_taijiview = merge('nodes/ nodes index')+' '+'parser lex taijiview'
#files_taijiview = for item in files_taijiview.split(' ') then destLib+item+'.js'
#task 'transform:taijiview', (cb) ->
#  if not distributing then return src(files_taijiview).pipelog(twoside(destLib, 'taijiview')).to(destLib)
#  src(files_taijiview)
#  .pipelog(twoside(folders_dest, 'taijiview', {only_wrap_for_browser:true})).to(destLibClient)
#  .pipe(concat("taijiview-package.js")).pipe(size()).to(destLibClient)
#  #minify
#  .pipe(closureCompiler()).pipe(rename(suffix: "-min")).pipe(size()).to(destLibClient)

task 'make:samples', (cb) -> # twoside, concat
  # twoside and concat for samples
  files = 'some .js examples filename for taijiview'
  files = for name in files.split(' ') then folders_dest+'examples/'+name+'.js'
#  console.log files.join(' ')
  stream = src(files).pipelog(twoside(folders_dest+'examples', 'taijiview/examples')) #, {only_wrap_for_browser:true}
  if not distributing then return stream.to(folders_dest+'examples')
  stream.pipe(concat('examples-concat.js')).pipe(size()) # when debuggin, dont concat
  stream.to(folders_dest+'examples')

task 'make:test', (cb) -> # twoside, concat, minify
  # twoside and concat for test/karma
  stream = src(folders_dest+'test/karma/**/*.js')
  .pipelog(twoside(folders_dest+'test/karma', 'peasy/karma', {only_wrap_for_browser:true}))
  if not distributing then return  stream.to(folders_dest+'test/karma')
  stream.pipe(concat('karma-concat.js')) # when debugging, dont concat
  .to(folders_dest+'test/karma')

build = (callback) ->
  runSequence('clean', ['copy', 'coffee'], ['transform:taijiview', 'make:samples', 'make:test'], callback)
# make is for debugging and test, dont concat and minify
task 'make', (callback) -> distributing = false; build(callback)
# dist is for release, so concat and minify packages
task 'dist', (callback) -> distributing = true; build(callback)

files_mocha = folders_dest+'test/mocha/**/*.js'

onErrorContinue = (err) -> console.log(err.stack); @emit 'end'
task 'mocha', ->  src(files_mocha).pipe(mocha({reporter: 'dot'})).on("error", onErrorContinue)

# removes content for karma, if need, please see the content in project peasy, and rewrite for taijiview.
#files_karma_debug = 'twoside peasy linepeasy logicpeasy index '+\
#  merge('samples/ statemachine dsl arithmatic arithmatic2')+' '+\
#  merge('test/karma/ peasy logicpeasy samples-arithmatic samples-arithmatic samples-arithmatic')
#files_karma_debug = for item in files_karma_debug.split(' ') then folders_dest+item+'.js'
#files_karma_dist = 'twoside client/full-peasy-package samples/sample-concat test/karma/karma-concat'
#files_karma_dist = for item in files_karma_dist.split(' ') then folders_dest+item+'.js'
#karmaOnce = karma({configFile: folders_dest+'test/karma-conf.js', action: 'run'})
#task 'karma1', -> src(files_karma_debug).pipe(karmaOnce)
#task 'karma1/dist', -> src(files_karma_dist).pipe(karmaOnce)
#karmaWatch = karma({configFile: folders_dest+'test/karma-conf.js', action: 'watch'})
##console.log files_karma_dist.join(' ')
#task 'karma', -> src(files_karma_debug).pipe(karmaWatch)
#task 'karma/dist', -> src(files_karma_dist).pipe(karmaWatch)

task 'runapp', shell.task ['node dist/examples/sockio/app.js']
task 'express',  ->
  app = express()
  app.use(require('connect-livereload')()) # play with tiny-lr to livereload stuffs
  app.use(express.static(__dirname))
  app.listen(4000)
task 'tinylr', -> server.listen 35729, (err) -> if err then console.log(err)

task 'watch/copy', -> watch files_copy, ['copy']
task 'watch/coffee', -> watch files_coffee, ['coffee']
task 'watch/mocha', -> watch [files_modulejs, files_serverjs, files_mocha], ['mocha']
onWatchReload = (event) -> src(event.path, {read: false}).pipe(livereload(tinylrServer))
task 'watch/reload', -> watch files_reload,onWatchReload #tinylrServer = tinylr(); tinylrServer.listen(35729);
task 'watch/all', -> ['watch/copy', 'watch/coffee', 'watch/mocha'] #  , 'watch/reload'

task 'mocha/auto', ['watch/copy', 'watch/coffee', 'watch/mocha']
task 'test', (callback) -> runSequence('make', ['mocha', 'karma1'], callback)
task 'test/dist', (callback) -> runSequence('dist', ['mocha'], callback)   #, 'karma1/dist'
task 'default',['test']

