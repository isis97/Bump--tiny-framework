module.exports =
  baseExportsOverride:
    "requirejs-plugins":
      "js": "src/*.js"
    "pure":
      "css": "pure.css"
    "requirejs":
      "js": "require.js"
    "jquery":
      "distjs": "dist/jquery*.min.js"
      "js": "dist/jquery*.js"
      "map": "dist/jquery*.map"
    "backbone":
      "js": "backbone.js"
    "underscore":
      "js": "underscore*.js"
      "map": "underscore*.map"
    "bootstrap":
      "distjs": "dist/js/bootstrap*.min.js"
      "distcss": "dist/css/bootstrap*.min.css"
      "js": "dist/js/bootstrap*.js"
      "map": "dist/js/bootstrap*.map"
      "font": "dist/fonts/*"
      "css": "dist/css/*"
    "font-awesome":
      "css": "css/*"
      "font": "fonts/*"
    "backbone-validation":
      "js": "dist/*.js"
    "backbone.paginator":
      "js": "lib/*.js"
    "fuelux":
      "js": "dist/js/*.js"
      "font": "dist/fonts/*"
      "css": "dist/css/*"
    "chosen":
      "js": "chosen.jquery*.js"
      "img": "chose*.png"
      "css": "chosen*.css"
    "moment":
      "js": "moment.js"
      "lang": "lang/*.js"
    "default":
      "distcss": "**/*.min.css"
      "distjs": "**/*.min.js"
      "js": "**/*.js"
      "css": "**/*.css"
      "map": "**/*.map(.js)?"
      "lang": "**/**/lang/**/*.js"
      "img": "**/*.(png|svg|jpeg|jfif|rif|gif|bmp|ppm|pgm|pbm|pnm|webp|bpg|img|cd5|tga)"
      "ts": "**/*.ts"
      "cs": "**/*.coffee"
      "less": "**/*.less"
      "sass": "**/*.(sass|scss)"
      "jade": "**/*.jade"
      "html": "**/*.(html|htm)"
      "font": "**/*.(ttf|tte|ttc|ttx|eot|etx|woff|pcf|otf|fot|fon|dfont|gtx|abf|afm|euf)"
