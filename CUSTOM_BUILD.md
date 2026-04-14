
- add origin from main microsoft repository
- create branch from latest tag on that repository
  for current situation was branch 1.59.1 and then I have created another branch in this point of history v1.59.1-only-chrome-with-core
- and then work with individual build files to introduce changes similar to previous PR's
- then create PR from v1.59.1-only-chrome-with-core to v1.59.1 - to keep record of what exactly was changed
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
we are using `npx playwright@1.59.1 install chromium --with-deps` because we have this luxury of using external build because the original image is already published. Where original project have to do it differently because the are doing it first.

But generally we are pulling just chrome not all supported browsers binaries which makes final image much smaller.

then build and push:

```
docker login
npm ci
npm run build
/bin/bash ./utils/docker/build.sh --arm64 noble monstersmart/playwright:v1.59.1-noble-just-chromium

```

then new image should be visible here: https://hub.docker.com/repository/docker/monstersmart/playwright/general





































