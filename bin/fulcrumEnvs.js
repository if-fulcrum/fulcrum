// read each json file in conf directory
var fs      = require('fs'),
    cfg_dir = process.argv[2],
    content = '',
    cfgs;

if (cfg_dir !== undefined) {
  cfgs    = fs.readdirSync(cfg_dir);

  for (var i = 0; i < cfgs.length; i++) {
    if (cfgs[i].match(/\.json$/)) {
      conf = require(cfg_dir + '/' + cfgs[i]);
      content += '  ' + cfgs[i].replace(/\.json$/, '') + '    \'' + conf.env  + '\';\n';
    }
  }

  process.stdout.write('map $host $fulcrum_env {\n  hostnames;\n\n' + content + '}\n');
} else {
  process.stdout.write('USAGE: ' + process.argv[1] + ' <CONFDIR>\n');
}