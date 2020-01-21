
const program = require('commander');

const yaml = require('js-yaml');
const fs = require('fs');
const _ = require('lodash');

program.arguments('<chart>');
program.parse(process.argv);

try {
  if (_.isEmpty(program.args)) {
    program.help();
  }
  else {
    const chartPath = program.args[0];

    // Load the values file of the chart.
    const data = yaml.safeLoad(fs.readFileSync(`${chartPath}/values.yaml`, 'utf8'));

    const schema = generateSchema(data);
    const schemaPath = `${chartPath}/values.schema.json`;

    fs.writeFileSync(schemaPath, JSON.stringify(schema, null, 2))
    process.stdout.write(`Generated schema at ${schemaPath}\n`)
  }
} catch (e) {
  console.log(e);
}

function generateSchema(data, path = '') {
  const schema = {};

  if (_.isBoolean(data)){
    schema.type = 'boolean';
  }
  else if (_.isString(data)){
    schema.type = 'string';
  }
  else if (_.isNumber(data)){
    schema.type = 'number';
  }
  else if (_.isArray(data)) {
    schema.type = 'array';

    if (data.length) {
      schema.items = generateSchema(data.pop());
    }
  }
  else if (_.isObject(data)) {
    schema.type = 'object';
    schema.properties = {};

    const externalDependencies = [
      'mariadb',
      'memcached',
      'varnish',
      'elasticsearch',
      'mailhog'
    ];

    if (!externalDependencies.some(dependency => path.match(new RegExp(dependency)))) {

      for (let propertyName in data) {
        schema.properties[propertyName] = generateSchema(data[propertyName], `${path}/${propertyName}`);
      }

      if (path.match(/(noauthips|env|cron)$/)) {
        schema.additionalProperties = schema.properties[Object.keys(schema.properties)[0]];
        delete schema.properties;
      }
      else {
        schema.additionalProperties = false;
      }
    }
  }

  return schema;
}