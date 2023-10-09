# Bindable tests

Automated tests created with [utest](https://lib.haxe.org/p/utest).

## Run interpreter tests

To run tests with the Haxe interpreter, run the following command:

```sh
haxe test.hxml --interp
```

## Run Neko tests

To run tests with Neko, run the following command:

```sh
haxe test.hxml --neko bin/test.n
neko bin/test.n
```

## Run HashLink tests

To run tests with HashLink, run the following command:

```sh
haxe test.hxml --hl bin/test.hl
hl bin/test.hl
```

## Run C++ tests

To run tests with C++, run the following command:

```sh
haxe test.hxml --cpp bin/test
bin/test/Main
```

Note: Certain tests are disabled when targeting C++ unless `-D HXCPP_CHECK_POINTER` is specified.
