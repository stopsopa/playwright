
- add origin from main microsoft repository
- create branch from latest tag on that repository
  for current situation was branch 1.60.0 and then I have created another branch in this point of history v1.60.0-only-chrome-with-core
- and then work with individual build files to introduce changes similar to previous PR's
- then create PR from v1.60.0-only-chrome-with-core to v1.60.0 - to keep record of what exactly was changed
- Then build and push


Currently there are two base ubuntu images jammy and noble. Noble is newer then let's focus on this one. (previously it was focal, now it doesn't exist)

- utils/docker/Dockerfile.jammy
- utils/docker/Dockerfile.noble

In old image we had to modify build process to use buildx instead of standard docker build

https://github.com/stopsopa/playwright/pull/1/changes#diff-391ff715a9049f5310672d4ba350add8edb7798b99ead089bc385114ea75ed0fR44

standard docker build will not create a multi-arch manifest.

doing:

```
docker build --platform linux/amd64 -t myimage .
docker build --platform linux/arm64 -t myimage .
```

The second build would overwrite the first one in your local image store.

When it comes to modifying utils/docker/Dockerfile.noble
we are using `npx playwright@1.60.0 install chromium --with-deps` because we have this luxury of using external build because the original image is already published. Where original project have to do it differently because they are doing it first.

But generally we are pulling just chrome not all supported browsers binaries which makes final image much smaller.

then build and push:

```
docker login
npm ci
npm run build
/bin/bash ./utils/docker/build.sh --arm64 noble monstersmart/playwright:v1.60.0-noble-just-chromium

```

then new image should be visible here: https://hub.docker.com/repository/docker/monstersmart/playwright/general

It is also beneficial to run:

```
# 2. Build and LOAD only the native architecture into your local Docker
# (Docker Desktop will automatically pick the platform matching your Mac)
docker buildx build --load --tag "${3}" -f "Dockerfile.${2}" .

```

this way we won't have to pull the image:

```

docker pull monstersmart/playwright:v1.60.0-noble-just-chromium

```
in order to test it locally

```
docker run -it monstersmart/playwright:v1.60.0-noble-just-chromium node --version
```


# Ultimate test of the image

```
mkdir ttt
cd ttt
echo "nodejs v24.15.0" > .tool-versions
cat <<EOF > package.json
{
  "name": "playwright-debug",
  "version": "1.0.0",
  "type": "module",
  "devDependencies": {
    "@playwright/test": "1.60.0",
    "playwright": "1.60.0"
  }
}
EOF
pnpm install
npx playwright install --with-deps chromium
cat <<EEE > playwright.config.js
import { devices } from "@playwright/test";
const config = {
  projects: [
    {
      name: "chromium",
      use: {
        ...devices["Desktop Chrome"],
      },
    },
  ],
};
export default config;
EEE
cat <<EOF > debug.spec.js
import { test, expect } from '@playwright/test';

test('basic test', async ({ page }) => {
  await page.goto('https://playwright.dev/');
  
  const title = page.locator('.navbar__inner .navbar__title');
  await expect(title).toHaveText('Playwright');
  
  await page.waitForTimeout(1000);
});
EOF
npx playwright test --headed
cat <<EEE | docker run -i --rm --ipc host --cap-add SYS_ADMIN --entrypoint="" \
-w "/code" \
--env NODE_API_PORT \
 \
 \
--env MYSQL_HOST=host.docker.internal \
-v "$(pwd)/debug.spec.js:/code/debug.spec.js" \
-v "$(pwd)/playwright.config.js:/code/playwright.config.js" \
-v "$(pwd)/package.json:/code/package.json" \
-v "$(pwd)/node_modules:/code/node_modules" \
--env NODE_API_HOST=host.docker.internal \
monstersmart/playwright:v1.60.0-noble-just-chromium \
bash
  set -e
  echo ===========printenv== to see PLAYWRIGHT_TEST_MATCH =========
  printenv
  echo "pwd: >\$(pwd)<"
  ls -la
  set -x
  echo yarn.lock and package.json are required to run yarn list playwright but lets try
  npm ls | grep playwright
  /bin/bash node_modules/.bin/playwright --version
  cat <<OOO

value for PLAYWRIGHT_TEST_MATCH >${PLAYWRIGHT_TEST_MATCH}<

  /bin/bash node_modules/.bin/playwright test --forbid-only --project=chromium --workers=1

OOO
  echo =========== inspect =========== ^^
  /bin/bash node_modules/.bin/playwright test --forbid-only --project=chromium --workers=1
EEE
```