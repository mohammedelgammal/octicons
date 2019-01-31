#!/bin/sh -l

set -e

if [ -n "$NPM_AUTH_TOKEN" ]; then
  # Respect NPM_CONFIG_USERCONFIG if it is provided, default to $HOME/.npmrc
  NPM_CONFIG_USERCONFIG="${NPM_CONFIG_USERCONFIG-"$HOME/.npmrc"}"
  NPM_REGISTRY_URL="${NPM_REGISTRY_URL-registry.npmjs.org}"

  # Allow registry.npmjs.org to be overridden with an environment variable
  printf "//%s/:_authToken=%s\\nregistry=%s" "$NPM_REGISTRY_URL" "$NPM_AUTH_TOKEN" "$NPM_REGISTRY_URL" > "$NPM_CONFIG_USERCONFIG"
  chmod 0600 "$NPM_CONFIG_USERCONFIG"
fi

PACKAGE_VERSION=$(cat package.json \
  | grep version \
  | head -1 \
  | awk -F: '{ print $2 }' \
  | sed 's/[",]//g' \
  | tr -d '[[:space:]]')

cd ./lib/$*

echo "**************** Copying assets files to build directory ****************"
cp -R ../build/ .

echo "**************** Installing ****************"
npm install

echo "**************** Building ****************"
npm run build

echo "**************** Linting ****************"
npm run lint

echo "**************** Testing  ****************"
npm run test

{
  echo "**************** Publishing ****************"
  npm version $PACKAGE_VERSION && npm publish --access public
} || {
  # Bail out of publishing
  exit 0
}
