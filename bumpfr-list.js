#!/usr/bin/env node
/*
#
# Bump framework (bump-framework 0.0.1)
# Cli module by isis97 (https://github.com/isis97)
#
# license MIT
#
*/
(function(){var RelPath,buildConfig,fs,program,utils;fs=require("fs"),program=require("commander"),utils=require("./util/util"),program.option("-p, --path [path]","Specifies path where to find Bump! project",".").option("-dd, --harddebug","Enables hard level debugging of Bump! itself (for devs)",!1).option("-d, --debug","Enable debug mode",!1).option("-n, --dry","Enable dry-run mode (does not write any files)",!1).option("-v, --verbose","Generate a lot of debug info. Please use with --debug flag.",!1).option("-f, --force","Skip any fatal error (may be dangerous sometimes)",!1).parse(process.argv),RelPath=utils.getRelPath(program),buildConfig=utils.getBuildConfig(RelPath),utils.spawnGruntCli(RelPath,"viewUnits",{debug:program.debug||program.harddebug,stack:program.debug||program.harddebug,write:!program.dry&&!program.harddebug,verbose:program.verbose||program.harddebug,force:program.force||program.harddebug})}).call(this);
/*
#    bump-framework 0.0.1
*/