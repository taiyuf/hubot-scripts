'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = getConfig;

var _fs = require('fs');

var _fs2 = _interopRequireDefault(_fs);

var _jsYaml = require('js-yaml');

var _jsYaml2 = _interopRequireDefault(_jsYaml);

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * load 'config/default.yml(or yaml)' and 'config/NODE_ENV.yml(or yaml)' and return the contents as hash.
 *
 * @example:
 *   import getConfig from './getConfig';
 *
 *   const configDir = path.resolve(__dirname, '..', '..', 'config');
 *   const config = getConfig(configDir);
 *
 * @param  {String} dir the directory of yaml file.
 * @return {Object} the hash of configuration.
 */
function getConfig(dir) {
  var name = 'getConfig';

  if (!dir) {
    throw new Error('*** ' + name + ': argument error: dir: ' + dir);
  }

  var defaultYaml = void 0;
  var envYaml = void 0;
  var result = {};
  var env = process.env.NODE_ENV || 'development';

  try {
    defaultYaml = _jsYaml2.default.safeLoad(_fs2.default.readFileSync(dir + '/default.yml', 'utf8'));
  } catch (e) {
    try {
      defaultYaml = _jsYaml2.default.safeLoad(_fs2.default.readFileSync(dir + '/default.yaml', 'utf8'));
    } catch (e) {
      console.log('Could not read default yaml: ' + e);
      defaultYaml = {};
    }
  }

  try {
    envYaml = _jsYaml2.default.safeLoad(_fs2.default.readFileSync(dir + '/' + env + '.yml', 'utf8'));
  } catch (e) {
    try {
      envYaml = _jsYaml2.default.safeLoad(_fs2.default.readFileSync(dir + '/' + env + '.yaml', 'utf8'));
    } catch (e) {
      console.log('Could not read ' + env + ' yaml: ' + e);
      envYaml = {};
    }
  }

  return _lodash2.default.merge({}, defaultYaml, envYaml);
};