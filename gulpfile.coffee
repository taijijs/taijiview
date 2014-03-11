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

build = (callback) -> runSequence('clean', ['copy', 'coffee'], callback)
# make is for debugging and test, dont concat and minify
task 'make', (callback) -> distributing = false; build(callback)
# dist is for release, so concat and minify packages
task 'dist', (callback) -> distributing = true; build(callback)

files_mocha = folders_dest+'test/mocha/**/*.js'

onErrorContinue = (err) -> console.log(err.stack); @emit 'end'
task 'mocha', ->  src(files_mocha).pipe(mocha({reporter: 'dot'})).on("error", onErrorContinue)

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
task 'test', (callback) -> runSequence('make', ['mocha'], callback)
task 'test/dist', (callback) -> runSequence('dist', ['mocha'], callback)
task 'default',['test']

