
- add origin from main microsoft repository
- create branch from latest tag on that repository
- and then work with individual build files to introduce changes similar to previous PR's
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







































