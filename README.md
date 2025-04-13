# ChangedPatcher

CLI tool to patch your Changed install written in V

## Problems

The program is completely untested on Windows past simply building it. Due to being mainly developed on Linux, supporting Windows natively is not immediately planned.

## Recommended build setup

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

Then, install Ruby 3.0.0 and set it as your global install with these command:
```sh
$ rbenv install 3.0.0
$ rbenv global 3.0.0
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