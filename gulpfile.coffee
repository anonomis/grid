gulp = require('gulp')
coffee = require('gulp-coffee')
gutil = require('gutil')
watch = require('gulp-watch')
browserify = require('gulp-browserify')
rename = require('gulp-rename')
livereload = require('gulp-livereload')
exec = require('child_process').exec
plumber = require('gulp-plumber')

swallowError = (error) ->
  console.log(error.toString())
  this.emit('end')

gulp.task 'default', ->
  livereload.listen()
  exec('static')

  gulp.src('./src/**.coffee', { read: false })
    .pipe(watch('./src/**.coffee'))
    .pipe(plumber())
    .pipe(coffee({bare: true}))
    .pipe(gulp.dest('./'))
  # ###
  gulp.src('./src/script.js', { read: false })
    .pipe(watch('./src/*.js'))
    .pipe(browserify({
          insertGlobals : true,
          debug : !gulp.env.production
        }))
    .pipe(rename('script.bundle.js'))
    .pipe(gulp.dest('./'))
    .pipe(livereload())
  ###
  ###
