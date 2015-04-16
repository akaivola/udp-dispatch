var gulp = require('gulp')
var gutil = require('gulp-util')
var wisp = require('gulp-wisp')
var cache = require('gulp-cached')
var remember = require('gulp-remember')
var rimraf = require('rimraf')
var nodemon = require('gulp-nodemon')

var SRC = './src/**/*.wisp'
var DEST = './lib'
var TESTSRC = './test/src/**/*.wisp'
var TESTDEST = './test/lib'

gulp.task('clean', function(cb) {
  rimraf(DEST, cb)
})
gulp.task('clean-test', function(cb) {
  rimraf(TESTDEST, cb)
})

gulp.task('wisp', function() {
  gulp.src('./src/**/*.wisp')
   .pipe(cache('wisp').on('error', gutil.log))
   .pipe(wisp())
   .pipe(remember('wisp'))
   .pipe(gulp.dest(DEST))
})

gulp.task('test-wisp', function() {
  gulp.src(TESTSRC)
   .pipe(wisp())
   .pipe(gulp.dest(TESTDEST))
})

gulp.task('watch', function() {
  gulp.watch('./src/**/*.wisp', ['wisp'])
    .on('change', function(event) {
      if (event.type !== 'deleted')
        return
      delete cache.caches['scripts'][event.path]
      remember.forget('scripts', event.path)
    })
})

function nodemonFor(script) {
  return function() {
    nodemon({
      script: script,
      ext: 'js',
      env: {}
    })
  }
}

function watchFor(task) {
  var nodemonTask = task + 'nodeMon'
  gulp.task(nodemonTask, nodemonFor(task))
  return nodemonTask
}

gulp.task('test', function() {
  gulp.src(TESTDEST + '/**/*.js').pipe(mocha({ reporter: 'nyan'}))
})

gulp.task('mainNodemon', nodemonFor('lib/core.js'))

gulp.task('default', ['clean', 'wisp', 'watch', watchFor('core')])
gulp.task('build', ['clean', 'wisp'])
