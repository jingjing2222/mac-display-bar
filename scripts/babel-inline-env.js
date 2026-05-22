const fs = require('node:fs');
const path = require('node:path');

const dotenv = require('dotenv');

const projectRoot = path.resolve(__dirname, '..');

for (const fileName of ['.env', '.env.hotupdater', '.env.local']) {
  const envPath = path.join(projectRoot, fileName);

  if (fs.existsSync(envPath)) {
    dotenv.config({
      path: envPath,
      override: fileName === '.env.local',
      quiet: true,
    });
  }
}

module.exports = function inlineEnv({ types: t }) {
  return {
    name: 'inline-project-env',
    visitor: {
      MemberExpression(pathNode, state) {
        const variableNames = state.opts.variables ?? [];
        const objectPath = pathNode.get('object');
        const property = pathNode.node.property;

        if (
          !objectPath.matchesPattern('process.env') ||
          !t.isIdentifier(property) ||
          !variableNames.includes(property.name)
        ) {
          return;
        }

        const value = process.env[property.name];

        if (value == null || value.length === 0) {
          throw pathNode.buildCodeFrameError(
            `Missing required env variable: ${property.name}`,
          );
        }

        pathNode.replaceWith(t.stringLiteral(value));
      },
    },
  };
};
