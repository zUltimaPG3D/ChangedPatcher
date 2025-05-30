# ChangedPatcher

CLI tool to patch your Changed install, written in V

## Problems

The program is completely untested on Windows past simply building it. Due to being mainly developed on Linux, supporting Windows natively is not immediately planned.

## Using via Docker (recommended)

Build the Docker image with this command:
```sh
$ docker build -t changed-patcher .
```

Then run it like this:
```sh
# If your patches are in the current working directory
$ docker run -it --rm -v "$PWD":"$PWD" -v "$PWD/patches":/app/patches changed-patcher ./ChangedPatcher -d "$PWD"
```

Obviously you can use different arguments and you don't **need** to use `-d "$PWD"`, but that's up to you. Since the command above only mounts the current working directory, it's best to run the command directly inside the game's directory.

## Building (Linux)

> [!NOTE]
> This isn't how you **have** to build it, but it is most likely the best way to do
> it as it is my personal setup, so in theory it should work flawlessly.

> [!NOTE]
> These instructions are specific to Linux, though they should work fine
> on WSL.

First off, install `rbenv` with this command:
```sh
$ curl -fsSL https://rbenv.org/install.sh | bash
```

Then, install Ruby (can be any version above 3.0.0, but 3.4.2 is used here) and set it as your global install with these command:
```sh
$ rbenv install 3.4.2
$ rbenv global 3.4.2
```

Then, install the VRGSS dependency with this:
```sh
$ v install
```

After this, run this command to configure and build:
```sh
$ # You might have to run this command first:
$ # chmod +x ./build.vsh ./configure.vsh

$ ./build.vsh
```