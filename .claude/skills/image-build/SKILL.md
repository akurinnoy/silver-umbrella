---
name: image-build
description: Build and push multi-arch zeroclaw-full container image to quay.io
trigger: when user wants to build, rebuild, or push the zeroclaw image
---

# Skill: Build and Push zeroclaw-full Image

This skill guides building and pushing `quay.io/okurinny/zeroclaw-full` as a multi-arch container image.

**Context:**
- Dockerfile is at the repo root (`/Users/okurinny/Workspace/akurinnoy/zeroclaw-terminal/`)
- Image: `quay.io/okurinny/zeroclaw-full`
- Current version: `v0.1.7`
- Platforms: `linux/amd64,linux/arm64`
- Builder: `multiarch` (docker buildx, already configured on this machine)
- Registry: quay.io (must be logged in before pushing)

---

## Steps

1. **Ask for the new version tag.**
   Ask the user: "What version tag should I use for the new image? (current is `v0.1.7`, e.g. `v0.1.8`)"
   Do NOT reuse the current tag without explicit confirmation from the user.

2. **Verify the buildx builder is available.**
   Run:
   ```
   docker buildx ls | grep multiarch
   ```
   If `multiarch` does not appear in the output, stop and report to the user. Do not proceed.

3. **Build and push the multi-arch image.**
   From the repo root, run (substituting `<VERSION>` with the tag confirmed in step 1):
   ```
   docker buildx build --builder multiarch --platform linux/amd64,linux/arm64 -t quay.io/okurinny/zeroclaw-full:<VERSION> --push .
   ```
   This command builds both architectures and pushes directly to quay.io in one step.
   Note: you must be logged in to quay.io (`docker login quay.io`) before running this.

4. **Remind the user to update `devfile.yaml`.**
   After a successful push, remind the user:
   > "The image was pushed successfully. Remember to update the `image:` field in `devfile.yaml` to `quay.io/okurinny/zeroclaw-full:<VERSION>`."
   Show the user the relevant line in `devfile.yaml` so they can confirm the change.

5. **Commit and push the `devfile.yaml` change.**
   Once the user confirms the `devfile.yaml` update, stage and commit it:
   ```
   git add devfile.yaml
   git commit -s -m "Update zeroclaw-full image to <VERSION>"
   git push
   ```
   Follow the Collaborative Debugging rule: propose the commit message and wait for user confirmation before running it.
