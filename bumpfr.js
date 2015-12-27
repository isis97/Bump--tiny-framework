#!/usr/bin/env node
/*
#
# Bump framework (bump-framework 0.0.1)
# Cli module by isis97 (https://github.com/isis97)
#
# license MIT
#
*/
(function(){var buildConfig,colors,config,e,fs,program,utils;fs=require("fs"),program=require("commander"),utils=require("./util/util"),colors=require("colors/safe"),config={},buildConfig={};try{config=fs.readFileSync(__dirname+"/package.json"),config=JSON.parse(config)}catch(_error){e=_error,utils.fatal("Could not find pacakge.json - Bump! was installed incorrectly.\nPlease reinstall Bump!\nIf this error will be thrown again please provide issue information to framework authors.\n\nError details:\n"+e.message)}program.version(config.version).command("build [path]","Run build proccess").command("install","Installs/updates project dependencies").command("dev","Runs dev server with autoreload on local host").command("newunit [name]","Creates new unit with given name").command("removeunit [name]","Removes permamently an unit with given name").command("list","Lists all units of a given Bump! project").parse(process.argv)}).call(this);
/*
#    bump-framework 0.0.1
*/