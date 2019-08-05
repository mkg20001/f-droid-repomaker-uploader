# f-droid-repomaker-uploader

Script to upload APKs directly to repomaker, for the lazy ones among us

# Setup

First you need to define the enviroment variables `USER`, `SERVER` and `PW`
- `USER`: urlencoded username
- `PW`: urlencoded password
- `SERVER`: urlencoded serveraddress (just the host part, the script assumes https:// by default)

You can also put these variables into `/etc/fdroid-repomaker-uploader`

# Usage

Now you can call the script the following way:

```console
$ f-droid-repomaker-uploader 1 build/release/YourAPK.apk
```

