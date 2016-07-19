import fs   from 'fs';
import yaml from 'js-yaml';
import _    from 'lodash';

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
export default function getConfig(dir) {
  const name = 'getConfig';

  if (!dir) {
    throw new Error(`*** ${name}: argument error: dir: ${dir}`);
  }

  let defaultYaml;
  let envYaml;
  let result = {};
  const env  = process.env.NODE_ENV || 'development';

  try {
    defaultYaml = yaml.safeLoad(fs.readFileSync(`${dir}/default.yml`, 'utf8'));
  } catch (e) {
    try {
      defaultYaml = yaml.safeLoad(fs.readFileSync(`${dir}/default.yaml`, 'utf8'));
    } catch (e) {
      console.log(`Could not read default yaml: ${e}`);
      defaultYaml = {};
    }
  }

  try {
    envYaml = yaml.safeLoad(fs.readFileSync(`${dir}/${env}.yml`, 'utf8'));
  } catch (e) {
    try {
      envYaml = yaml.safeLoad(fs.readFileSync(`${dir}/${env}.yaml`, 'utf8'));
    } catch (e) {
      console.log(`Could not read ${env} yaml: ${e}`);
      envYaml = {};
    }
  }

  return _.merge({}, defaultYaml, envYaml);
};
