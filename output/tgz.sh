OUTPUT_EXTRA_PACKAGES=e2fsprogs

prepare_output() {
    tar --numeric-owner -C $DIR -cpzf $OUTPUT .
}
